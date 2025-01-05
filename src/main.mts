import { categorizeFilesFromTestFolder } from "./utils/categorize.mjs"
import { reportTests } from "./report/report.mjs"
import { parseSoliditySourceFiles } from "./parse/src.mjs"
import { parseSolidityTestFile } from "./parse/testFile.mjs"
import { reportFilesFromTestFolder } from "./report/files.mjs"
import { SourceContracts, TestFile } from "./parse/types.mjs"
import { findSolidityFiles, SolidityFile } from "./utils/files.mjs"

// Main function to parse all test files
export function main(sourceDirectory: string, testDirectory: string) {
	console.time("Total Execution Time")

	/* ============= PARSE SOURCE ============= */

	const solidityFilesFromSourceFolder = findSolidityFiles(sourceDirectory)

	const parsedSource = parseSoliditySourceFiles(solidityFilesFromSourceFolder)

	/* ============= PARSE TESTS ============= */

	const solidityFilesFromTestFolder = findSolidityFiles(testDirectory)

	const categorizedFiles = categorizeFilesFromTestFolder(
		solidityFilesFromTestFolder,
	)

	reportFilesFromTestFolder(categorizedFiles)

	/* ============= PARSE TESTS ============= */

	const { testFiles } = categorizedFiles

	const parsedTestFiles = analyzeTestFiles(testFiles, parsedSource)

	reportTests(parsedSource, parsedTestFiles)

	console.timeEnd("Total Execution Time")
}

function analyzeTestFiles(
	testFiles: SolidityFile[],
	parsedSource: SourceContracts,
): TestFile[] {
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

	console.log(`\n\nTotal tests found: ${totalTests}`)

	return parsedTestFiles
}
