import { Cursor } from "@nomicfoundation/slang/cst"
import { SolidityFile } from "../files.mjs"
import { getContractName } from "../utils.mjs"
import warningSystem from "../warning.mjs"
import { TestFileNamingConvention } from "../validation/testFileNamingConvention.mjs"
import { ScopeType } from "./testFile.mjs"
import { FunctionName } from "./src.mjs"

export type TestFunctionScopeType = "function" | "unknown" // | "feature"

export interface TestFunctionScope {
	type: TestFunctionScopeType
	sourceContract?: string
	sourceFunction?: string
}

// FunctionScope is usually expected to a Unit test for specific function / constructor
// If file has FunctionScope, all test functions are assumed to have the function scope
export interface TestFunction {
	name: FunctionName
	scope: TestFunctionScope | undefined
}

export function getTestFunctionScope(
	file: SolidityFile,
	functionName: string,
	cursor: Cursor,
	convention: TestFileNamingConvention,
): TestFunctionScope {
	// Default scope is unknown
	const scope: TestFunctionScope = {
		type: "unknown",
	}

	// Check if test contract follows second naming convention (Contract.function.t.sol)
	if (convention === "second") {
		// Contract name already indicates the function being tested
		scope.type = "function"
		scope.sourceFunction = getContractName(file, cursor)
		scope.sourceContract = getSourceContractFromPath(file.filePath)
		return scope
	}

	// First naming convention or undefined
	// Try to extract function name from test function name
	const extractedFunction = getFunctionNameFromTestName(functionName)

	if (extractedFunction) {
		scope.type = "function"
		scope.sourceFunction = extractedFunction
		scope.sourceContract = getSourceContractFromPath(file.filePath)
		return scope
	}

	// Could not determine function scope
	warningSystem.addWarning(
		`Unable to determine scope for test ${functionName} in ${file.filePath}`,
	)

	return scope
}

function getSourceContractFromPath(filePath: string): string {
	// Extract contract name from path like "test/Contract/Contract.*.t.sol"
	const parts = filePath.split("/")
	const contractDir = parts[parts.length - 2] // Get parent directory name
	return contractDir
}

function getFunctionNameFromTestName(functionName: string): string | undefined {
	// Match patterns like:
	// test_functionName
	// testFuzz_functionName
	// test_RevertIf_functionName
	const patterns = [
		/^test_([a-z][a-zA-Z]*)/, // Basic test
		/^testFuzz(?:ing)?_([a-z][a-zA-Z]*)/, // Fuzz test
		/^test_(?:RevertIf|RevertWhen|RevertOn)_([a-z][a-zA-Z]*)/, // Revert test
	]

	for (const pattern of patterns) {
		const match = functionName.match(pattern)
		if (match && match[1]) {
			return match[1]
		}
	}

	// Try splitting by underscore and checking second part
	const parts = functionName.split("_")
	if (parts.length >= 2) {
		const candidate = parts[1]
		if (/^[a-z][a-zA-Z]*$/.test(candidate)) {
			return candidate
		}
	}

	return undefined
}
