import { Cursor, Query } from "@nomicfoundation/slang/cst"
import { FunctionName } from "../types.mjs"

// Doesn't change the state of the cursor due to the spawn of new cursor
export function parseFunctions(
	cursorPointedAtContractDefinition: Cursor,
): FunctionName[] {
	const cursor = cursorPointedAtContractDefinition.spawn()
	cursor.goToFirstChild()

	const functionNames: FunctionName[] = []

	// Define a query to find all function definitions and capture their names
	const functionQuery = Query.parse(
		"[FunctionDefinition [FunctionName @function_name [Identifier]]]",
	)

	// Execute the query on the cursor
	const matches = cursor.query([functionQuery])

	// Iterate over the matches and extract function names
	for (const match of matches) {
		const functionNameCursor = match.captures["function_name"]![0]!
		const functionName = functionNameCursor.node.unparse()
		functionNames.push(functionName)
	}

	return functionNames
}
