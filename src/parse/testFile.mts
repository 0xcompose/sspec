import { NonterminalKind, Query, Cursor } from "@nomicfoundation/slang/cst"
import { Parser } from "@nomicfoundation/slang/parser"
import { SolidityFile } from "../files.mjs"
import { getContractName, isSetupFunction, isTestFunction } from "../utils.mjs"
import { checkIfFileHasMultipleContracts } from "../validation/noMultipleContracts.mjs"
import { checkIfTestFileFollowsNamingConvention } from "../validation/testFileNamingConvention.mjs"
import warningSystem from "../warning.mjs"
import { FunctionName, SourceContracts } from "./src.mjs"
import fs from "fs"
import { validateParseOutput } from "../validation/parseOutput.mjs"
import path from "path"
import { getTestFunctionScope, TestFunction } from "./testFunction.mjs"

export type ContractName = string

// Feature tests and integration tests are unsupported, that's why we have an unknown scope type
export type ScopeType = "function" | "contract" | "unknown" // | "feature"

export interface TestContractScope {
	type: ScopeType
	target: ContractName | FunctionName | undefined // | FeatureName
}

// Assumes there is only one contract in the file
// otherwise throws an error
export interface TestFile {
	testContract: ContractName
	filePath: string
	scope: TestContractScope
	tests: TestFunction[]
	setUps: string[] // setUp(), _setUp(), _afterSetup(), _beforeSetup()
}

// Function to parse a Solidity file and extract function names
export function parseSolidityTestFile(
	file: SolidityFile,
	parsedSource: SourceContracts,
): TestFile | undefined {
	const source = fs.readFileSync(file.filePath, "utf8")

	const parser = Parser.create(file.version)
	const parseOutput = parser.parse(NonterminalKind.SourceUnit, source)

	/* ============= PARSE OUTPUT VALIDATION ============= */

	const { isValid } = validateParseOutput(parseOutput)
	if (!isValid) return

	const cursor = parseOutput.createTreeCursor()

	// Check if there is more than one contract in the file
	// Adds error to execution if there is more than one contract in the file
	checkIfFileHasMultipleContracts(file, cursor)

	// Validate that the file and contract name are following the naming convention
	const { convention } = checkIfTestFileFollowsNamingConvention(file, cursor)

	/* ============= FILE PASSED VALIDATION ============= */

	const testFile: TestFile = {
		filePath: file.filePath,
		scope: getFileScope(file, cursor),
		tests: [],
		testContract: "",
		setUps: [],
	}

	// Create a query to find all function definitions
	const query = Query.parse(
		"@function [FunctionDefinition [FunctionName @function_name [Identifier]]]",
	)
	const matches = cursor.query([query])

	// Extract the names of the test functions
	for (const match of matches) {
		const functionNameCursor = match.captures["function_name"]![0]!

		const functionName = functionNameCursor.node.unparse()

		// Filter out setUps
		if (isSetupFunction(functionName)) {
			testFile.setUps.push(functionName)
			continue
		}

		// If doesn't start with "test", skip
		if (!isTestFunction(functionName)) {
			continue
		}

		const testFunction: TestFunction = {
			name: functionName,
			scope: getTestFunctionScope(file, functionName, cursor, convention),
		}

		testFile.tests.push(testFunction)
	}

	return testFile
}

function getFileScope(file: SolidityFile, cursor: Cursor): TestContractScope {
	return {
		type: "contract",
		target: getContractNameFromFilePath(file, cursor),
	}
}

function getContractNameFromFilePath(
	file: SolidityFile,
	cursor: Cursor,
): ContractName {
	const fileName = path.basename(file.filePath)
	const folderName = path.basename(path.dirname(file.filePath))

	// Try to extract contract name from the file name
	const match = fileName.match(/^(.+)\.([a-zA-Z]+)\.t\.sol$/)

	if (match) {
		return match[1]
	}

	// If no contract name in file name, use the folder name
	if (folderName) {
		return folderName
	}

	// If neither is available, log a warning and use a default name
	warningSystem.addWarning(
		`Unable to determine scope name for file: ${file.filePath}`,
	)

	return getContractName(file, cursor)
}
