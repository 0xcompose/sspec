import { TextRange } from "@nomicfoundation/slang/cst"
import { Definition } from "../parse/types.mjs"

export function makeLinkToDefinition(definition: Definition): string {
	return `${definition.file.path}:${definition.range.start.line + 1}:${
		definition.range.start.column + 1
	}`
}

export function makeLinkToFile(path: string): string {
	return `file://${path}`
}
