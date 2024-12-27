import { categorizeFiles, findSolidityFiles } from "./files.mjs"
import { reportTests } from "./report/report.mjs"
import { parseSoliditySourceFiles } from "./parse/src.mjs"
import { TestFile, parseSolidityTestFile } from "./parse/testFile.mjs"
import { reportFiles } from "./report/files.mjs"

// Main function to parse all test files
export function main(sourceDirectory: string, testDirectory: string) {
	console.time("Total Execution Time")

	/* ============= PARSE SOURCE ============= */

	const solidityFilesFromSourceFolder = findSolidityFiles(sourceDirectory)

	const parsedSource = parseSoliditySourceFiles(solidityFilesFromSourceFolder)

	/* ============= PARSE TESTS ============= */

	const solidityFilesFromTestFolder = findSolidityFiles(testDirectory)

	const categorizedFiles = categorizeFiles(solidityFilesFromTestFolder)

	reportFiles(categorizedFiles)

	const { testFiles } = categorizeFiles(solidityFilesFromTestFolder)

	let totalTests = 0
	const parsedTestFiles: TestFile[] = []

	for (const file of testFiles) {
		const testFile = parseSolidityTestFile(file, parsedSource)

		if (!testFile) {
			// Error is printed in parseSolidityFile
			continue
		}

		totalTests += testFile.tests.length
		parsedTestFiles.push(testFile)
	}

	reportTests(parsedSource, parsedTestFiles)

	console.log(`\n\nTotal tests found: ${totalTests}`)
	console.timeEnd("Total Execution Time")
}
