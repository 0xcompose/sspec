import path from "path"
import { CategorizedFiles } from "./files.mjs"
import { TestFunction, TestStructure } from "./parse/test.mjs"
import warningSystem from "./warning.mjs"

export function reportFiles(categorizedFiles: CategorizedFiles) {
	const { testFiles, setupFiles, utilsFiles, errors } = categorizedFiles
	const filesLength =
		testFiles.length + setupFiles.length + utilsFiles.length + errors.length

	console.log(` | Identified ${filesLength} solidity files in test/:`)

	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Found ${testFiles.length} test files in test/:`)
	console.log(` |`)
	for (const file of testFiles) {
		console.log(` |-- ${path.basename(file.filePath)} (${file.version})`)
	}
	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Found ${setupFiles.length} setup files in test/:`)
	console.log(` |`)
	for (const file of setupFiles) {
		console.log(` |-- ${path.basename(file.filePath)} (${file.version})`)
	}
	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Found ${utilsFiles.length} utility files in test/:`)
	console.log(` |`)
	for (const file of utilsFiles) {
		console.log(` |-- ${path.basename(file.filePath)} (${file.version})`)
	}
	console.log(` |-------------------------------------\n\n`)
}

// TODO: handle
export function reportTests(testFiles: TestStructure[]) {
	// Group tests by contract name

	const contracts: Map<string, TestFunction[]> = new Map()

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

function getTestDescriptionFromName(test: TestFunction): string {
	let testName = test.name

	const regexp = /^test(Fork)?(Fuzz)?(_Revert(If|When|On))?_(\w+)*$/

	// Check if the test name matches the pattern
	if (!regexp.test(testName)) {
		warningSystem.addWarning(
			`Test name "${testName}" does not match the expected pattern.`,
		)

		// Highlight the test name in yellow
		return `\x1b[33m${testName}\x1b[0m` // ANSI escape code for yellow
	}

	testName = testName.replace(/^(test(Fork)?(Fuzz)?_)/, "")

	// If matching, process the test name to make it human-readable
	const readableTestName = testName
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
