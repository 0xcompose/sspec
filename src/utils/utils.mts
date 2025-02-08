import { Cursor, Query, TextRange } from "@nomicfoundation/slang/cst"
import { SolidityFile } from "./files.mjs"
import warningSystem from "../warning.mjs"
import { SourceContracts } from "../parse/types.mjs"
import sourceContractsSingleton from "../parse/sourceContractsSingleton.mjs"
import path from "path"
export const DEFAULT_SOLIDITY_VERSION = "0.8.22"

export function extractSolidityVersion(source: string): string {
	const matches = source.match(/pragma solidity \^(\d+\.\d+\.\d+);/)
	return matches?.[1] ?? DEFAULT_SOLIDITY_VERSION
}

export function toPascalCase(str: string): string {
	return str.replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, (match) => {
		return match.toUpperCase()
	})
}

export function getContractName(file: SolidityFile, cursor: Cursor): string {
	const query = Query.create(
		"[ContractDefinition @contract_name [Identifier]]",
	)
	const matches = cursor.query([query])

	let contractName = ""

	for (const match of matches) {
		if (contractName.length != 0) {
			warningSystem.addWarning(
				`Multiple contracts found in ${file.path} (first found is used)`,
			)
			break
		}

		contractName = match.captures["contract_name"]![0]!.node.unparse()
	}

	return contractName
}

export function isTestFile(file: SolidityFile): boolean {
	return file.path.includes(".t.sol")
}

export function isSetupFile(file: SolidityFile): boolean {
	return file.path.includes("Setup")
}

export function isUtilsFile(file: SolidityFile): boolean {
	const name = path.basename(file.path)
	return (
		file.path.includes("utils") ||
		file.path.includes("util") ||
		name.includes("Helper") ||
		name.includes("Utils") ||
		name.includes("Util") ||
		name.includes("Mock") ||
		name.includes("Harness")
	)
}

export function isSetupFunction(functionName: string): boolean {
	return ["setUp", "_setUp", "_afterSetup", "_beforeSetup"].includes(
		functionName,
	)
}

export function isTestFunction(functionName: string): boolean {
	return functionName.startsWith("test")
}

export function isSourceFunction(supposedSourceFunctionName: string): boolean {
	const sourceContracts = sourceContractsSingleton.getSourceContracts()

	for (const [, functions] of sourceContracts) {
		if (functions.includes(supposedSourceFunctionName)) {
			return true
		}
	}

	return false
}

export function isSourceContract(
	supposedSourceContractName: string,
	sourceContracts: SourceContracts,
): boolean {
	return sourceContracts.has(supposedSourceContractName)
}

export function isCamelCase(str: string): boolean {
	return /^[a-z]+([A-Z][a-z]*)*$/.test(str)
}

export function isPascalCase(str: string): boolean {
	return /^[A-Z][a-z]*(?:[A-Z][a-z]*)*$/.test(str)
}

export function toCamelCase(str: string): string {
	return str
		.replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) =>
			index === 0 ? letter.toLowerCase() : letter.toUpperCase(),
		)
		.replace(/\s+/g, "")
}

export function isInternalOrPrivateFunction(functionName: string): boolean {
	return functionName.startsWith("_")
}
