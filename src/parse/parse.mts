import { ParseOutput, Parser } from "@nomicfoundation/slang/parser"
import { readSolidityFile, SolidityFile } from "../utils/files.mjs"
import { validateParseOutput } from "../validation/parseOutput.mjs"

export function parseSolidityFile(file: SolidityFile): ParseOutput | undefined {
	const parser = Parser.create(file.version)
	const source = readSolidityFile(file)
	const parseOutput = parser.parseFileContents(source)

	const { isValid } = validateParseOutput(parseOutput)
	if (!isValid) return

	return parseOutput
}
