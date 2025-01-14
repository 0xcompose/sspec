import { SolidityFile } from "../utils/files.mjs"
import { isSourceFunction } from "../utils/utils.mjs"
import warningSystem from "../warning.mjs"
import { ScopeType, TestFileScope, TestFunctionScope } from "./types.mjs"

export function getTestFunctionScope(
	file: SolidityFile,
	functionName: string,
	testFileScope: TestFileScope,
): TestFunctionScope {
	const unknownScope: TestFunctionScope = {
		type: ScopeType.Unknown,
	}

	/* ============================
	 * Contract scope
	 * ============================ */

	if (testFileScope.type === ScopeType.Contract) {
		// Function's scope is ALWAYS function

		const sourceFunctionName =
			getSourceFunctionNameFromTestName(functionName)

		if (!sourceFunctionName) {
			warnAboutInvalidFunctionName(functionName, file)
			return unknownScope
		}

		return {
			type: ScopeType.Function,
			target: sourceFunctionName,
		}
	}

	/* ============================
	 * Function scope
	 * ============================ */

	if (testFileScope.type === ScopeType.Function) {
		// Function's scope is ALWAYS function

		return {
			type: ScopeType.Function,
			target: testFileScope.target,
		}
	}

	/* ============================
	 * Feature scope
	 * ============================ */

	if (testFileScope.type === ScopeType.Feature) {
		// Function's scope is EITHER function OR feature
		const sourceFunctionName =
			getSourceFunctionNameFromTestName(functionName)

		if (!sourceFunctionName) {
			// Feature scope
			return {
				type: ScopeType.Feature,
				target: testFileScope.target,
			}
		} else {
			// Function scope
			return {
				type: ScopeType.Function,
				target: sourceFunctionName,
			}
		}
	}

	// Could not determine function scope
	warningSystem.addWarning(
		`Unable to determine scope for test ${functionName} in ${file.path}`,
	)

	return unknownScope
}

export function getSourceFunctionNameFromTestName(
	functionName: string,
): string | undefined {
	if (!functionName) {
		return undefined
	}

	// Match patterns like:
	// test_functionName
	// test_functionName_Description
	// testFuzz_functionName_Description
	// testForkFuzz_functionName_Description
	const standardPattern =
		/^test(?:Fork)?(?:Fuzz)?_([a-z][a-zA-Z]*)(?:_[A-Z].+)?$/

	// For revert tests, we don't extract function names as they follow different patterns:
	// Contract scope: test_functionName_RevertIf_Condition
	// Function scope: test_RevertIf_Condition
	// Feature scope: test_RevertIf_Condition (or test_functionName_RevertIf_Condition)
	if (
		functionName.includes("RevertIf") ||
		functionName.includes("RevertWhen") ||
		functionName.includes("RevertOn")
	) {
		return undefined
	}

	const match = functionName.match(standardPattern)
	if (!match?.[1]) {
		return undefined
	}

	const extractedName = match[1]

	if (!isSourceFunction(extractedName)) {
		return undefined
	}

	return extractedName
}

function warnAboutInvalidFunctionName(
	functionName: string,
	file: SolidityFile,
) {
	warningSystem.addWarning(
		`Unable to determine source function name for test ${functionName} in ${file.path}`,
	)
}
