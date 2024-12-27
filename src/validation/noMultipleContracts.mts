import { Cursor, Query } from "@nomicfoundation/slang/cst"
import { SolidityFile } from "../files.mjs"
import warningSystem from "../warning.mjs"

// Expecting a cursor from a parseOutput
export function checkIfFileHasMultipleContracts(
	file: SolidityFile,
	cursor: Cursor,
): boolean {
	const contractQuery = Query.parse("@contract [ContractDefinition]")
	const contractMatches = cursor.query([contractQuery])

	const matches = []

	// Check if there is more than one contract in the file
	for (const match of contractMatches) {
		matches.push(match.captures["contract"]![0]!)
	}

	const hasMultipleContracts = matches.length > 1

	if (hasMultipleContracts) {
		warningSystem.addError(
			`File ${file.filePath} contains more than one contract.`,
		)
	}

	return hasMultipleContracts
}
