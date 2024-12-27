import path from "path"
import { SolidityFile } from "../files.mjs"
import { getContractName, toPascalCase } from "../utils.mjs"
import warningSystem from "../warning.mjs"
import { Cursor } from "@nomicfoundation/slang/cst"

export type TestFileNamingConvention = "first" | "second" | undefined

// There are two valid naming conventions for unit testing (according to foundry best practice):
// 1. `SourceContractName.t.sol`, where test contract is named `SourceContractNameTest`
// 2. `SourceContractName.sourceFunctionName.t.sol`, where test contract is named `SourceFunctionName` with pascal case
export function checkIfTestFileFollowsNamingConvention(
	testFile: SolidityFile,
	cursor: Cursor,
): {
	followsConvention: boolean
	convention: TestFileNamingConvention
} {
	const fileNameParts = path.basename(testFile.filePath).split(".")
	const sourceContractNameFromFileName = fileNameParts[0]
	const testContractName = getContractName(testFile, cursor)

	// Check for the first naming convention
	const isFirstConvention =
		sourceContractNameFromFileName + "Test" === testContractName

	// Check for the second naming convention
	const isSecondConvention =
		fileNameParts.length > 2 &&
		testContractName === toPascalCase(fileNameParts[1])

	if (!isFirstConvention && !isSecondConvention) {
		warningSystem.addError(
			`File ${testFile.filePath} does not follow the test file naming convention`,
		)
		return {
			followsConvention: false,
			convention: undefined,
		}
	}

	return {
		followsConvention: true,
		convention: isFirstConvention ? "first" : "second",
	}
}
