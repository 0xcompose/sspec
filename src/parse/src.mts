import { NonterminalKind, Query } from "@nomicfoundation/slang/cst"
import { ParseOutput, Parser } from "@nomicfoundation/slang/parser"
import { parseFunctions } from "./queries/functions.mjs"
import { validateParseOutput } from "../validation/parseOutput.mjs"
import { SourceContracts, FunctionName, ContractName } from "./types.mjs"
import { readSolidityFile, SolidityFile } from "../utils/files.mjs"

export function parseSoliditySourceFiles(
	files: SolidityFile[],
): SourceContracts {
	const contracts = new Map<ContractName, FunctionName[]>()

	for (const file of files) {
		const parsedContracts = parseSoliditySourceFile(file)

		if (!parsedContracts) {
			continue
		}

		// Merge parsedContracts into contracts
		for (const [contractName, functions] of parsedContracts) {
			if (!contracts.has(contractName)) {
				contracts.set(contractName, [])
			}
			contracts.get(contractName)!.push(...functions)
		}
	}

	return contracts
}

export function parseSoliditySourceFile(
	file: SolidityFile,
): SourceContracts | undefined {
	const source = readSolidityFile(file)

	const parser = Parser.create(file.version)
	const parseOutput = parser.parseFileContents(source)

	const { isValid } = validateParseOutput(parseOutput)
	if (!isValid) return

	const contracts: SourceContracts = new Map()

	// Query the contract names
	const cursor = parseOutput.createTreeCursor()

	const query = Query.create(
		`[ContractDefinition 
			@contract_name [Identifier]
		]`,
	)
	const matches = cursor.query([query])

	for (const match of matches) {
		const contractNameCursor = match.captures["contract_name"][0]
		const contractName = contractNameCursor.node.unparse()

		const functions: FunctionName[] = parseFunctions(cursor)

		contracts.set(contractName, functions)
	}

	return contracts

	// Parse contract names and contract functions
}
