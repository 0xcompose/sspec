import path from "path"
import { CategorizedFiles } from "./files.mjs"
import { TestStructure } from "./parse.mjs"
import warningSystem from "./warning.mjs"

export function reportFiles(categorizedFiles: CategorizedFiles) {
	const { testFiles, setupFiles, utilsFiles, errors } = categorizedFiles
	const filesLength = testFiles.length + setupFiles.length + utilsFiles.length

	console.log(` | Found ${filesLength} solidity files in test/:`)

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
	console.log(` |-------------------------------------\n\n`)
}

// TODO: handle
export function reportTests(testFiles: TestStructure[]) {
	// Group tests by contract name

	const contracts: Map<string, string[]> = new Map()

	for (const file of testFiles) {
		if (file.scope.type === "contract") {
			const existingTests = contracts.get(file.scope.name)

			if (existingTests) {
				contracts.set(file.scope.name, [
					...existingTests,
					...file.tests,
				])
			} else {
				contracts.set(file.scope.name, file.tests)
			}
		}
	}

	for (const [contractName, tests] of contracts) {
		console.log(`\nContract Specification: ${contractName}`)

		for (const [index, test] of tests.entries()) {
			let startingSymbol = "├──"
			if (index === 0) startingSymbol = "├──"
			if (index === tests.length - 1) startingSymbol = "└──"

			console.log(`${startingSymbol} ${getTestDescriptionFromName(test)}`)
		}
	}
}

function getTestDescriptionFromName(testName: string): string {
	// Define the regular expression pattern
	const regexp = /^test(Fork)?(Fuzz)?(_Revert(If|When|On))?_(\w+)*$/

	// Check if the test name matches the pattern
	if (!regexp.test(testName)) {
		warningSystem.addWarning(
			`Test name "${testName}" does not match the expected pattern.`,
		)
		// If not matching, split by "_" and return
		return testName
	}

	if (!testName.startsWith("test")) {
		warningSystem.addWarning(
			`Test name "${testName}" does not start with "test".`,
		)
		return testName
	}

	// If matching, process the test name to make it human-readable
	const readableTestName = testName
		.split("test")[1]
		.split("_") // First split by underscores
		.map(
			(part) =>
				part
					.replace(/([a-z])([A-Z])/g, "$1 $2") // Then split by capital letters
					.replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2"), // Handle continuous capitals
		)
		.join(" ") // Join the parts back with spaces
		.trim()

	// Check if the test name contains 'revert' or 'reverts' and make it red
	if (/revert/i.test(testName)) {
		return `\x1b[31m${readableTestName}\x1b[0m` // ANSI escape code for red
	}

	return readableTestName
}
