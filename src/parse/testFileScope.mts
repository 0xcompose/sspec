import path from "path"
import {
	getContractName,
	isSourceContract,
	isSourceFunction,
	toCamelCase,
	toPascalCase,
} from "../utils/utils.mjs"
import warningSystem from "../warning.mjs"
import {
	FeatureName,
	FunctionName,
	ScopeType,
	SourceContracts,
	TestFileScope,
} from "./types.mjs"
import { SolidityFile } from "../utils/files.mjs"
import { Cursor } from "@nomicfoundation/slang/cst"
import sourceContractsSingleton from "./sourceContractsSingleton.mjs"

// There are three valid naming conventions for unit testing (according to foundry best practice):
// 1. `SourceContractName.t.sol`, where test contract is named `SourceContractNameTest`
// 2. `SourceContractName.sourceFunctionName.t.sol`, where test contract is named `SourceFunctionName` with pascal case
// 3. `SourceContractName.FeatureName.t.sol`, where test contract is named `FeatureName`
export function getTestFileScope(
	testFile: SolidityFile,
	cursor: Cursor,
): TestFileScope {
	const unknownScope: TestFileScope = { type: ScopeType.Unknown }

	const sourceContracts = sourceContractsSingleton.getSourceContracts()

	const [sourceContractName, secondPart, testIdentifier, extension] = path
		.basename(testFile.filePath)
		.split(".")
	const testContractName = getContractName(testFile, cursor)

	if (!isSourceContract(sourceContractName, sourceContracts)) {
		createErrorOnUnknownScope(testFile)
		return unknownScope
	}

	// Check if it's a contract-level test file
	if (testContractName === `${sourceContractName}Test`) {
		return {
			type: ScopeType.Contract,
			target: sourceContractName,
		}
	}

	// For both function and feature scopes, we need a valid second part
	if (
		!secondPart ||
		!testIdentifier ||
		testIdentifier !== "t" ||
		extension !== "sol"
	) {
		createErrorOnUnknownScope(testFile)
		return unknownScope
	}

	// Check if it's a function-level test file
	if (
		toCamelCase(testContractName) === secondPart &&
		isSourceFunction(secondPart)
	) {
		return {
			type: ScopeType.Function,
			target: secondPart as FunctionName,
		}
	}

	// Check if it's a feature-level test file
	if (testContractName === secondPart) {
		return {
			type: ScopeType.Feature,
			target: secondPart as FeatureName,
		}
	}

	createErrorOnUnknownScope(testFile)
	return unknownScope
}

function createErrorOnUnknownScope(testFile: SolidityFile) {
	warningSystem.addError(
		`Unable to determine scope for test file ${testFile.filePath}`,
	)
}
