import { Cursor, Query } from "@nomicfoundation/slang/cst"
import { SolidityFile } from "./files.mjs"
import warningSystem from "./warning.mjs"

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
	const query = Query.parse(
		"[ContractDefinition @contract_name [Identifier]]",
	)
	const matches = cursor.query([query])

	let contractName = ""

	for (const match of matches) {
		if (contractName.length != 0) {
			warningSystem.addWarning(
				`Multiple contracts found in ${file.filePath} (first found is used)`,
			)
			break
		}

		contractName = match.captures["contract_name"]![0]!.node.unparse()
	}

	return contractName
}

export function isTestFile(file: SolidityFile): boolean {
	return file.filePath.includes(".t.sol")
}

export function isSetupFile(file: SolidityFile): boolean {
	return file.filePath.includes("Setup")
}

export function isUtilsFile(file: SolidityFile): boolean {
	return (
		file.filePath.includes("Helper") ||
		file.filePath.includes("Utils") ||
		file.filePath.includes("Util") ||
		file.filePath.includes("Mock") ||
		file.filePath.includes("Harness")
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
