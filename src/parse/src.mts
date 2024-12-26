import fs from "fs"
import { SolidityFile } from "../files.mjs"
import { ContractName } from "./test.mjs"
import { NonterminalKind, Query } from "@nomicfoundation/slang/cst"
import { ParseOutput, Parser } from "@nomicfoundation/slang/parser"
import warningSystem from "../warning.mjs"
import { parseFunctions } from "../queries/functions.mjs"

export type FunctionName = string

interface Contract {
	name: ContractName
	functions: FunctionName[]
}

export function parseSoliditySourceFiles(files: SolidityFile[]) {
	const functions = new Map<ContractName, FunctionName[]>()
	const contracts = new Map<ContractName, boolean>()

	for (const file of files) {
		const parsedContracts = parseSoliditySourceFile(file)

		if (!parsedContracts) {
			continue
		}

		for (const contract of parsedContracts) {
			contracts.set(contract.name, true)
			functions.set(contract.name, contract.functions)
		}
	}
}

export function parseSoliditySourceFile(
	file: SolidityFile,
): Contract[] | undefined {
	const source = fs.readFileSync(file.filePath, "utf8")

	const parser = Parser.create(file.version)
	ParseOutput
	const parseOutput = parser.parse(NonterminalKind.SourceUnit, source)

	if (!parseOutput.isValid()) {
		for (const error of parseOutput.errors) {
			warningSystem.addWarning(
				`Error at contract ${file.filePath} at byte offset ${error.textRange.start.utf8}: ${error.message}`,
			)
		}
		return
	}

	const contracts: Contract[] = []

	// Query the contract names
	const cursor = parseOutput.createTreeCursor()

	const query = Query.parse(
		`[ContractDefinition 
			@contract_name [Identifier]
		]`,
	)
	const matches = cursor.query([query])

	for (const match of matches) {
		const contractNameCursor = match.captures["contract_name"][0]
		const contractName = contractNameCursor.node.unparse()

		const functions: FunctionName[] = parseFunctions(cursor)

		contracts.push({ name: contractName, functions })
	}

	return contracts

	// Parse contract names and contract functions
}
