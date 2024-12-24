import fs from "fs"
import path from "path"
import { extractSolidityVersion } from "./utils.mjs"

export interface SolidityFile {
	filePath: string
	version: string
}

export interface CategorizedFiles {
	testFiles: SolidityFile[]
	setupFiles: SolidityFile[]
	utilsFiles: SolidityFile[]
	errors: {
		message: string
		file: SolidityFile
	}[]
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

// Setup files are files that have `Setup` in the filename
// Utils files are files that have `Helper`, `Utils` or `Util` in the filename
// Test files are files that have `.t.sol` in the filename and don't have `Setup` or `Helper` in the filename
// Utils files with `.t.sol` in the filename should be warned about, as they are not test files
// Mock or Harness files are files that have `Mock` or `Harness` in the filename
export function categorizeFiles(files: SolidityFile[]): CategorizedFiles {
	let cloneFiles = [...files]
	const errors = []

	// Filter out setup files
	const setupFiles = cloneFiles.filter((file) => isSetupFile(file))
	cloneFiles = cloneFiles.filter((file) => !setupFiles.includes(file))

	// Filter out test files
	const testFiles = cloneFiles.filter((file) => isTestFile(file))
	cloneFiles = cloneFiles.filter((file) => !testFiles.includes(file))

	// Filter out utils files
	const utilsFiles = cloneFiles.filter((file) => isUtilsFile(file))
	cloneFiles = cloneFiles.filter((file) => !utilsFiles.includes(file))

	// Filter out test files that are utils files
	const utilsNamedAsTest = utilsFiles.filter((file) => isTestFile(file))

	for (const file of utilsNamedAsTest) {
		errors.push({
			message: `${path.basename(file.filePath)} (${
				file.version
			}) is named as a test file but is a utility file`,
			file,
		})
	}

	for (const file of cloneFiles) {
		errors.push({
			message: `${path.basename(file.filePath)} (${
				file.version
			}) was not identified as a test, setup or utility`,
			file,
		})
	}

	return { testFiles, setupFiles, utilsFiles, errors }
}

function isTestFile(file: SolidityFile): boolean {
	return file.filePath.includes(".t.sol")
}

function isSetupFile(file: SolidityFile): boolean {
	return file.filePath.includes("Setup")
}

function isUtilsFile(file: SolidityFile): boolean {
	return (
		file.filePath.includes("Helper") ||
		file.filePath.includes("Utils") ||
		file.filePath.includes("Util")
	)
}
