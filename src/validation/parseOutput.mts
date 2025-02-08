import { ParseOutput } from "@nomicfoundation/slang/parser"
import warningSystem from "../warning.mjs"

export function validateParseOutput(parseOutput: ParseOutput) {
	const isValid = parseOutput.isValid()

	if (!isValid) {
		for (const error of parseOutput.errors()) {
			warningSystem.addError(
				`Error at byte offset ${error.textRange.start.utf8}: ${error.message}`,
			)
		}
	}

	return { isValid, errors: parseOutput.errors }
}
