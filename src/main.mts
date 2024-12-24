import { findSolidityFiles } from "./files.mjs"
import { reportFiles } from "./report.mjs"
import { parseSolidityFile } from "./parse.mjs"

// Main function to parse all test files
function main() {
	console.time("Total Execution Time")

	const testDirectory = "src/test-samples/"
	const solidityFiles = findSolidityFiles(testDirectory)

	reportFiles(solidityFiles)

	let totalTests = 0

	for (const file of solidityFiles) {
		const testFile = parseSolidityFile(file)

		totalTests += testFile.tests.length
	}

	console.log(`Total tests found: ${totalTests}`)
	console.timeEnd("Total Execution Time")
}

main()
