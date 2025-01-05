import { categorizeFilesFromTestFolder } from "./utils/categorize.mjs"
import { reportTests } from "./report/report.mjs"
import { parseSolidityTestFile } from "./parse/testFile.mjs"
import { reportFilesFromTestFolder } from "./report/files.mjs"
import { TestFile } from "./parse/types.mjs"
import { findSolidityFiles, SolidityFile } from "./utils/files.mjs"
import sourceContractsSingleton from "./parse/sourceContractsSingleton.mjs"

// Main function to parse all test files
export function main(sourceDirectory: string, testDirectory: string) {
	console.time("Total Execution Time")

	/* ============= PARSE SOURCE ============= */

	sourceContractsSingleton.initialize(sourceDirectory)
	const parsedSource = sourceContractsSingleton.getSourceContracts()

	/* ============= PARSE TESTS ============= */

	const solidityFilesFromTestFolder = findSolidityFiles(testDirectory)

	const categorizedFiles = categorizeFilesFromTestFolder(
		solidityFilesFromTestFolder,
	)

	reportFilesFromTestFolder(categorizedFiles)

	/* ============= PARSE TESTS ============= */

	const { testFiles } = categorizedFiles

	const parsedTestFiles = analyzeTestFiles(testFiles)

	reportTests(parsedSource, parsedTestFiles)

	console.timeEnd("Total Execution Time")
}

function analyzeTestFiles(testFiles: SolidityFile[]): TestFile[] {
	let totalTests = 0

	const parsedTestFiles: TestFile[] = []

	for (const file of testFiles) {
		const testFile = parseSolidityTestFile(file)

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
