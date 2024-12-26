import { categorizeFiles, findSolidityFiles } from "./files.mjs"
import { reportFiles, reportTests } from "./report.mjs"
import { parseSolidityTestFile, TestStructure } from "./parse/test.mjs"

// Main function to parse all test files
export function main(testDirectory: string) {
	console.time("Total Execution Time")

	// Get the test directory from command-line arguments, default to "test/" if not provided
	const solidityFiles = findSolidityFiles(testDirectory)

	const categorizedFiles = categorizeFiles(solidityFiles)

	reportFiles(categorizedFiles)

	const { testFiles } = categorizeFiles(solidityFiles)

	let totalTests = 0
	const testStructures: TestStructure[] = []

	for (const file of testFiles) {
		const testFile = parseSolidityTestFile(file)

		if (!testFile) {
			// Error is printed in parseSolidityFile
			continue
		}

		totalTests += testFile.tests.length
		testStructures.push(testFile)
	}

	reportTests(testStructures)

	console.log(`\n\nTotal tests found: ${totalTests}`)
	console.timeEnd("Total Execution Time")
}
