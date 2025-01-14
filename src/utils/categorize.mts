import path from "path"
import { isSetupFile, isTestFile, isUtilsFile } from "./utils.mjs"
import warningSystem from "../warning.mjs"
import { SolidityFile } from "./files.mjs"

export interface CategorizedFilesFromTestFolder {
	testFiles: SolidityFile[]
	setupFiles: SolidityFile[]
	utilsFiles: SolidityFile[]
}

// Setup files are files that have `Setup` in the filename
// Utils files are files that have `Helper`, `Utils` or `Util` in the filename
// Test files are files that have `.t.sol` in the filename and don't have `Setup` or `Helper` in the filename
// Utils files with `.t.sol` in the filename should be warned about, as they are not test files
// Mock or Harness files are considered utility files
// Any file that is not identified as a test, setup or utility is considered an error
export function categorizeFilesFromTestFolder(
	files: SolidityFile[],
): CategorizedFilesFromTestFolder {
	let cloneFiles = [...files]

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
		warningSystem.addError(
			`${path.basename(file.path)} (${
				file.version
			}) is named as a test file but is a utility file`,
		)
	}

	for (const file of cloneFiles) {
		warningSystem.addError(
			`${path.basename(file.path)} (${
				file.version
			}) was not identified as a test, setup or utility`,
		)
	}

	return { testFiles, setupFiles, utilsFiles }
}
