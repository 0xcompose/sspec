import { Cursor, Query } from "@nomicfoundation/slang/cst"
import {
	getContractName,
	isSetupFunction,
	isTestFunction,
} from "../utils/utils.mjs"
import { checkIfFileHasMultipleContracts } from "../validation/noMultipleContracts.mjs"
import { getTestFunctionScope } from "./testFunctionScope.mjs"
import { getTestFileScope } from "./testFileScope.mjs"
import { TestFile, TestFileScope } from "./types.mjs"
import { SolidityFile } from "../utils/files.mjs"
import { parseSolidityFile } from "./parse.mjs"
import path from "path"

// Function to parse a Solidity file and extract function names
export function parseSolidityTestFile(
	file: SolidityFile,
): TestFile | undefined {
	const parseOutput = parseSolidityFile(file)
	if (!parseOutput) return

	const cursor = parseOutput.createTreeCursor()

	validateFile(file, cursor)

	const testFileScope = getTestFileScope(file, cursor)

	const testFile = initializeTestFile(file, testFileScope, cursor)
	populateTestFunctions(testFile, file, testFileScope, cursor)

	return testFile
}

function validateFile(file: SolidityFile, cursor: Cursor) {
	const childCursor = cursor.spawn()

	checkIfFileHasMultipleContracts(file, childCursor)
}

function initializeTestFile(
	file: SolidityFile,
	testFileScope: TestFileScope,
	cursor: Cursor,
): TestFile {
	return {
		file: file,
		scope: testFileScope,
		testContract: getContractName(file, cursor),
		targetContract: path.basename(file.path).split(".")[0],
		tests: [],
		setUps: [],
	}
}

function populateTestFunctions(
	testFile: TestFile,
	file: SolidityFile,
	testFileScope: TestFileScope,
	cursor: Cursor,
) {
	const query = Query.create(
		"[FunctionDefinition [FunctionName @function_name [Identifier]]]",
	)
	const matches = cursor.query([query])

	for (const match of matches) {
		const capture = match.captures["function_name"]![0]!
		const functionName = capture.node.unparse()

		if (isSetupFunction(functionName)) {
			testFile.setUps.push(functionName)
			continue
		}

		if (!isTestFunction(functionName)) continue

		const functionDefinition = capture.textRange

		testFile.tests.push({
			name: functionName,
			definition: {
				range: functionDefinition,
				file: testFile.file,
			},
			scope: getTestFunctionScope(file, functionName, testFileScope),
		})
	}
}
