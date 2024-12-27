import { TestFunction } from "../parse/testFunction.mjs"
import warningSystem from "../warning.mjs"
import { FunctionName, SourceContracts } from "../parse/src.mjs"
import { ContractName, TestFile } from "../parse/testFile.mjs"

// `
//  Source Contract Specification: Source Contract Name
//  	├── Source Function Name
//  	│   ├─ Test Function Description
//  	├── Source Function Name
//  	│   ├─ Test Function Description
//  	├── Unidentified Tests?
//  	│   ├─ Test Function Description
// `
// Group tests by contract name
export function reportTests(
	sourceContracts: SourceContracts,
	testFiles: TestFile[],
) {
	const contracts = initializeContractsMap(sourceContracts)
	const unlinkedTests = new Map<
		ContractName,
		Map<FunctionName, TestFunction[]>
	>()

	populateTestFunctions(contracts, testFiles, unlinkedTests)
	printContractsReport(contracts, "Source Contracts Specification")
	printContractsReport(unlinkedTests, "Unlinked Test Contracts Specification")
}

type ContractReport = Map<ContractName, Map<FunctionName, TestFunction[]>>

function initializeContractsMap(
	sourceContracts: SourceContracts,
): ContractReport {
	const contracts: ContractReport = new Map()

	for (const [contractName, functionNames] of sourceContracts) {
		const contractFunctions = new Map()
		contracts.set(contractName, contractFunctions)

		// Add all source functions
		for (const functionName of functionNames) {
			contractFunctions.set(functionName, [])
		}

		// Add "Unidentified Tests" category
		contractFunctions.set("Unidentified Tests", [])
	}

	return contracts
}

function populateTestFunctions(
	contracts: ContractReport,
	testFiles: TestFile[],
	unlinkedTests: Map<ContractName, Map<FunctionName, TestFunction[]>>,
): void {
	for (const file of testFiles) {
		if (file.scope.type !== "contract") continue

		const contractName = file.scope.target!
		const contractFunctions = contracts.get(contractName)

		if (contractFunctions) {
			for (const test of file.tests) {
				const functionScope = determineTestScope(test)
				ensureFunctionScopeExists(contractFunctions, functionScope)
				contractFunctions.get(functionScope)!.push(test)
			}
		} else {
			if (!unlinkedTests.has(contractName)) {
				unlinkedTests.set(
					contractName,
					new Map([["Unidentified Tests", []]]),
				)
			}
			const unlinkedFunctions = unlinkedTests.get(contractName)!
			for (const test of file.tests) {
				const functionScope = determineTestScope(test)
				ensureFunctionScopeExists(unlinkedFunctions, functionScope)
				unlinkedFunctions.get(functionScope)!.push(test)
			}
		}
	}
}

function determineTestScope(test: TestFunction): string {
	return test.scope?.type === "function"
		? test.scope.sourceFunction || "Unidentified Tests"
		: "Unidentified Tests"
}

function ensureContractExists(
	contracts: Map<string, Map<string, TestFunction[]>>,
	contractName: string,
): void {
	if (!contracts.has(contractName)) {
		contracts.set(contractName, new Map([["Unidentified Tests", []]]))
	}
}

function ensureFunctionScopeExists(
	contractFunctions: Map<string, TestFunction[]>,
	functionScope: string,
): void {
	if (!contractFunctions.has(functionScope)) {
		contractFunctions.set(functionScope, [])
	}
}

function printContractsReport(
	contracts: Map<string, Map<string, TestFunction[]>>,
	title: string,
): void {
	const INDENT = "  "
	console.log(`\n${title}:`)

	for (const [contractName, functions] of contracts) {
		console.log(`\n${INDENT}Source Contract Specification: ${contractName}`)

		for (const [functionName, tests] of functions) {
			if (tests.length === 0 && functionName !== "Unidentified Tests") {
				console.log(`${INDENT}├── \x1b[31m${functionName}\x1b[0m`)
				continue
			}

			console.log(`${INDENT}├── ${functionName}`)
			printTestsList(tests, INDENT)
		}
	}
}

function printTestsList(tests: TestFunction[], indent: string): void {
	for (const [index, test] of tests.entries()) {
		const isLast = index === tests.length - 1
		const prefix = isLast ? "└──" : "├──"
		console.log(
			`${indent}│   ${prefix} ${getTestDescriptionFromName(test)}`,
		)
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
