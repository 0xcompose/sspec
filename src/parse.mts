import { NonterminalKind, Query } from "@nomicfoundation/slang/cst"
import { ParseOutput, Parser } from "@nomicfoundation/slang/parser"
import { SolidityFile } from "./files.mjs"
import { extractSolidityVersion, getContractName } from "./utils.mjs"
import fs from "fs"
import path from "path"
import warningSystem from "./warning.mjs"

export type ContractName = string
export type FeatureName = string
export type TestFunctionName = string

export interface Scope {
	type: "contract"
	name: string
}

export interface TestStructure {
	filePath: string
	error: string
	scope: Scope
	tests: TestFunctionName[]
	testContract: ContractName
	setUps: string[] // setUp(), _setUp(), _afterSetup(), _beforeSetup()
}

// Function to parse a Solidity file and extract function names
export function parseSolidityFile(
	file: SolidityFile,
): TestStructure | undefined {
	const source = fs.readFileSync(file.filePath, "utf8")
	// Use the utility function to find the solidity version in file
	const solidityVersion = extractSolidityVersion(source)

	const parser = Parser.create(solidityVersion)
	const parseOutput = parser.parse(NonterminalKind.SourceUnit, source)

	if (!parseOutput.isValid()) {
		for (const error of parseOutput.errors) {
			console.error(
				`Error at byte offset ${error.textRange.start.utf8}: ${error.message}`,
			)
		}
		return
	}

	const testFile: TestStructure = {
		filePath: file.filePath,
		error: "",
		scope: getScope(file, parseOutput),
		tests: [],
		testContract: "",
		setUps: [],
	}

	// Create a query to find all function definitions
	const query = Query.parse(
		"@function [FunctionDefinition [FunctionName @function_name [Identifier]]]",
	)
	const cursor = parseOutput.createTreeCursor()
	const matches = cursor.query([query])

	// Extract the names of the test functions
	for (const match of matches) {
		const functionNameCursor = match.captures["function_name"]![0]!

		const functionName = functionNameCursor.node.unparse()

		// Filter out setUps
		if (
			["setUp", "_setUp", "_afterSetup", "_beforeSetup"].includes(
				functionName,
			)
		) {
			testFile.setUps.push(functionName)
			continue
		}

		// If doesn't start with "test", skip
		if (!functionName.startsWith("test")) {
			continue
		}

		testFile.tests.push(functionName)
	}

	return testFile
}

function getScope(file: SolidityFile, parseOutput: ParseOutput): Scope {
	return {
		type: "contract",
		name: getContractNameFromFilePath(file, parseOutput),
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
