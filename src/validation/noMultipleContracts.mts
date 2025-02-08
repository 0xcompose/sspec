import { Cursor, Query, QueryMatchIterator } from "@nomicfoundation/slang/cst"
import warningSystem from "../warning.mjs"
import { SolidityFile } from "../utils/files.mjs"

// Expecting a cursor from a parseOutput
export function checkIfFileHasMultipleContracts(
	file: SolidityFile,
	cursor: Cursor,
): boolean {
	const contractQuery = Query.create("@contract [ContractDefinition]")
	const contractMatches = cursor.query([contractQuery])

	const matches = Array.from(contractMatches)

	// Check if there is more than one contract in the file

	const hasMultipleContracts = matches.length > 1

	if (hasMultipleContracts) {
		warningSystem.addError(
			`File ${file.path} contains more than one contract.`,
		)
	}

	return hasMultipleContracts
}
