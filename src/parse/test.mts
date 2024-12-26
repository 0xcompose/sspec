import { NonterminalKind, Query } from "@nomicfoundation/slang/cst"
import { ParseOutput, Parser } from "@nomicfoundation/slang/parser"
import { SolidityFile } from "../files.mjs"
import {
	checkIfFileHasMultipleContracts,
	extractSolidityVersion,
	getContractName,
	isSetupFunction,
	isTestFunction,
} from "../utils.mjs"
import fs from "fs"
import path from "path"
import warningSystem from "../warning.mjs"

export type ContractName = string
export type FeatureName = string

// FunctionScope is a Unit test for specific
// If file has FunctionScope, all test functions are assumed to have the same scope
export interface TestFunction {
	name: string
	scope: FunctionScope | undefined
}

export interface FunctionScope {
	type: "function"
	sourceFunctionName: string
}

export interface ContractScope {
	type: "contract"
	name: string
}

export interface TestStructure {
	testContract: ContractName
	filePath: string
	error: string
	scope: FunctionScope | ContractScope
	tests: TestFunction[]
	setUps: string[] // setUp(), _setUp(), _afterSetup(), _beforeSetup()
}

// Function to parse a Solidity file and extract function names
export function parseSolidityTestFile(
	file: SolidityFile,
): TestStructure | undefined {
	const source = fs.readFileSync(file.filePath, "utf8")

	const solidityVersion = extractSolidityVersion(source)

	const parser = Parser.create(solidityVersion)
	const parseOutput = parser.parse(NonterminalKind.SourceUnit, source)

	if (!parseOutput.isValid()) {
		for (const error of parseOutput.errors) {
			warningSystem.addError(
				`Error at byte offset ${error.textRange.start.utf8}: ${error.message}`,
			)
		}
		return
	}

	// Check if there is more than one contract in the file

	const testFile: TestStructure = {
		filePath: file.filePath,
		error: "",
		scope: getFileScope(file, parseOutput),
		tests: [],
		testContract: "",
		setUps: [],
	}

	const cursor = parseOutput.createTreeCursor()

	// Create a query to find all contract definitions
	checkIfFileHasMultipleContracts(file, cursor)

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
			scope: getFunctionScope(file, functionName),
		}

		testFile.tests.push(testFunction)
	}

	return testFile
}

function getFileScope(
	file: SolidityFile,
	parseOutput: ParseOutput,
): ContractScope {
	return {
		type: "contract",
		name: getContractNameFromFilePath(file, parseOutput),
	}
}

function getFunctionScope(
	file: SolidityFile,
	functionName: string,
): FunctionScope {
	// If test contract is named with a function name,
	// use that function name as the scope

	// If test function has test_functionName_Description,
	// use that function name as the scope

	return {
		type: "function",
		sourceFunctionName: functionName,
	}
}

function getContractNameFromFilePath(
	file: SolidityFile,
	parseOutput: ParseOutput,
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

	return getContractName(file, parseOutput)
}
