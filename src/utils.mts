import { Query } from "@nomicfoundation/slang/cst"
import { ParseOutput } from "@nomicfoundation/slang/parser"
import { SolidityFile } from "./files.mjs"
import warningSystem from "./warning.mjs"

export const DEFAULT_SOLIDITY_VERSION = "0.8.22"

export function extractSolidityVersion(source: string): string {
	const matches = source.match(/pragma solidity \^(\d+\.\d+\.\d+);/)
	return matches?.[1] ?? DEFAULT_SOLIDITY_VERSION
}

export function getContractName(
	file: SolidityFile,
	parseOutput: ParseOutput,
): string {
	const query = Query.parse(
		"[ContractDefinition @contract_name [Identifier]]",
	)
	const cursor = parseOutput.createTreeCursor()
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
