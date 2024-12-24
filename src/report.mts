import path from "path"
import { SolidityFile } from "./files.mjs"

export function reportFiles(files: SolidityFile[]) {
	console.log(` | Found ${files.length} solidity files in test/:`)

	const { testFiles, setupFiles, utilsFiles, errors } = categorizeFiles(files)

	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Found ${testFiles.length} test files in test/:`)
	console.log(` |`)
	for (const file of testFiles) {
		console.log(` |-- ${path.basename(file.filePath)} (${file.version})`)
	}
	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Found ${errors.length} errors in test/:`)
	console.log(` |`)
	for (const error of errors) {
		console.log(` |-- ${error.message}`)
	}
	console.log(` |-------------------------------------`)
}

// Setup files are files that have `Setup` in the filename
// Utils files are files that have `Helper`, `Utils` or `Util` in the filename
// Test files are files that have `.t.sol` in the filename and don't have `Setup` or `Helper` in the filename
// Utils files with `.t.sol` in the filename should be warned about, as they are not test files
// Mock or Harness files are files that have `Mock` or `Harness` in the filename
function categorizeFiles(files: SolidityFile[]): {
	testFiles: SolidityFile[]
	setupFiles: SolidityFile[]
	utilsFiles: SolidityFile[]
	errors: {
		message: string
		file: SolidityFile
	}[]
} {
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
			message: `${path.basename(file.filePath)} (${file.version}) is named as a test file but is a utility file`,
			file,
		})
	}

	for (const file of cloneFiles) {
		errors.push({
			message: `${path.basename(file.filePath)} (${file.version}) was not identified as a test, setup or utility`,
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
	return file.filePath.includes("Helper") || file.filePath.includes("Utils") || file.filePath.includes("Util")
}
