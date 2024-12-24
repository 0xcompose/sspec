import { NonterminalKind, Query } from "@nomicfoundation/slang/cst"
import { Parser } from "@nomicfoundation/slang/parser"
import { SolidityFile } from "./files.mjs"
import { extractSolidityVersion } from "./utils.mjs"
import fs from "fs"

interface TestStructure {
	filePath: string
	error: string
	tests: string[]
	testContract: string
	setUps: string[] // setUp(), _setUp(), _afterSetup(), _beforeSetup()
}

// Function to parse a Solidity file and extract function names
export function parseSolidityFile(file: SolidityFile): TestStructure {
	const source = fs.readFileSync(file.filePath, "utf8")
	// Use the utility function to find the solidity version in file
	const solidityVersion = extractSolidityVersion(source)

	const parser = Parser.create(solidityVersion)
	const parseOutput = parser.parse(NonterminalKind.SourceUnit, source)

	if (!parseOutput.isValid()) {
		for (const error of parseOutput.errors) {
			console.error(`Error at byte offset ${error.textRange.start.utf8}: ${error.message}`)
		}
		return {
			filePath: file.filePath,
			error: parseOutput.errors[0].message,
			tests: [],
			testContract: "",
			setUps: [],
		}
	}

	// Create a query to find all function definitions
	const query = Query.parse("@function [FunctionDefinition [FunctionName @function_name [Identifier]]]")
	const cursor = parseOutput.createTreeCursor()
	const matches = cursor.query([query])

	const testFile: TestStructure = {
		filePath: file.filePath,
		error: "",
		tests: [],
		testContract: "",
		setUps: [],
	}

	// Extract the names of the test functions
	for (const match of matches) {
		const functionNameCursor = match.captures["function_name"]![0]!

		const functionName = functionNameCursor.node.unparse()

		// Filter out setUps
		if (["setUp", "_setUp", "_afterSetup", "_beforeSetup"].includes(functionName)) {
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
