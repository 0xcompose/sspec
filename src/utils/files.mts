import path, { ParsedPath } from "path"
import fs from "fs"
import { extractSolidityVersion } from "./utils.mjs"

export interface SolidityFile {
	path: string
	version: string
}

// Function to recursively find all Solidity files in a directory
export function findSolidityFiles(dir: string): SolidityFile[] {
	let results: SolidityFile[] = []
	const list = fs.readdirSync(dir)

	list.forEach((file) => {
		file = path.resolve(dir, file)
		const stat = fs.statSync(file)
		if (stat && stat.isDirectory()) {
			results = results.concat(findSolidityFiles(file))
		} else if (file.endsWith(".sol")) {
			// read first line of file
			const source = fs.readFileSync(file, "utf8")
			const version = extractSolidityVersion(source)
			results.push({ path: file, version })
		}
	})

	return results
}

export function readSolidityFile(file: SolidityFile): string {
	if (!file.path.endsWith(".sol")) {
		throw new Error(
			`Invalid file type. Expected .sol file but got: ${file.path}`,
		)
	}
	return fs.readFileSync(file.path, "utf8")
}
