import path from "path"
import fs from "fs"
import { extractSolidityVersion } from "./utils.mjs"

export interface SolidityFile {
	filePath: string
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
			results.push({ filePath: file, version })
		}
	})

	return results
}

export function readSolidityFile(file: SolidityFile): string {
	if (!file.filePath.endsWith(".sol")) {
		throw new Error(
			`Invalid file type. Expected .sol file but got: ${file.filePath}`,
		)
	}
	return fs.readFileSync(file.filePath, "utf8")
}
