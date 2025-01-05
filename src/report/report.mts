import warningSystem from "../warning.mjs"
import {
	ContractName,
	FeatureName,
	FunctionName,
	ScopeType,
	SourceContracts,
	TestFile,
	TestFunction,
} from "../parse/types.mjs"
import { getSourceFunctionNameFromTestName } from "../parse/testFunctionScope.mjs"
import { isSourceFunction } from "../utils/utils.mjs"

type ReportSection = {
	functions: Map<FunctionName, TestFunction[]>
	features: Map<FeatureName, TestFunction[]>
	unidentified: TestFunction[]
}

type ContractReport = Map<ContractName, ReportSection>

// `
//  Source Contract Specification: Source Contract Name
//  	├── sourceFunctionName()
//  	│   ├─ Test Function Description
//  	├── sourceFunctionName()
//  	│   ├─ Test Function Description
//  	├── Feature Name
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
	populateReport(contracts, testFiles)
	printContractsReport(contracts)
}

function initializeContractsMap(
	sourceContracts: SourceContracts,
): ContractReport {
	const contracts: ContractReport = new Map()

	for (const [contractName, functionNames] of sourceContracts) {
		contracts.set(contractName, {
			functions: new Map(functionNames.map((fn) => [fn, []])),
			features: new Map(),
			unidentified: [],
		})
	}

	return contracts
}

function populateReport(
	contracts: ContractReport,
	testFiles: TestFile[],
): void {
	for (const file of testFiles) {
		const contractName = file.targetContract
		const reportSection = contracts.get(contractName)

		if (!reportSection) continue

		for (const test of file.tests) {
			switch (test.scope.type) {
				case ScopeType.Function:
					const functionTests = reportSection.functions.get(
						test.scope.target,
					)
					if (functionTests) {
						functionTests.push(test)
					}
					break

				case ScopeType.Feature:
					const featureName = test.scope.target
					if (!reportSection.features.has(featureName)) {
						reportSection.features.set(featureName, [])
					}
					reportSection.features.get(featureName)!.push(test)
					break

				default:
					reportSection.unidentified.push(test)
			}
		}
	}
}

function printContractsReport(contracts: ContractReport): void {
	console.log("\nSource Contracts Specification:")

	for (const [contractName, section] of contracts) {
		console.log(`\n  Source Contract Specification: ${contractName}`)

		// Print functions
		for (const [functionName, tests] of section.functions) {
			if (tests.length === 0) {
				console.log(`  ├── \x1b[31m${functionName}\x1b[0m`)
				continue
			}
			console.log(`  ├── ${functionName}`)
			printTestsList(tests)
		}

		// Print features
		for (const [featureName, tests] of section.features) {
			console.log(`  ├── ${featureName}`)
			printTestsList(tests)
		}

		// Print unidentified if any exist
		if (section.unidentified.length > 0) {
			console.log(`  ├── Unidentified Tests`)
			printTestsList(section.unidentified)
		}
	}
}

function printTestsList(tests: TestFunction[]): void {
	for (const [index, test] of tests.entries()) {
		const isLast = index === tests.length - 1
		const prefix = isLast ? "└──" : "├──"
		console.log(`  │   ${prefix} ${getTestDescriptionFromName(test)}`)
	}
}

function getTestDescriptionFromName(test: TestFunction): string {
	if (test.scope.type === ScopeType.Unknown) {
		return `\x1b[33m${test.name}\x1b[0m`
	}

	// TODO: unify regexps across the codebase
	const regexp =
		/^test(Fork)?(Fuzz)?(_[a-z][A-Z]+)?(_Revert(If|When|On))?_\w+$/

	if (!regexp.test(test.name)) {
		warningSystem.addWarning(
			`Test name "${test.name}" does not match the expected pattern.`,
		)
		return `\x1b[33m${test.name}\x1b[0m`
	}

	let readableTestName = getReadableTestDescription(test.name)

	// if (test.scope.type === ScopeType.Function) {
	// 	const functionNamePattern = new RegExp(
	// 		`\\b${test.scope.target}\\b`,
	// 		"i",
	// 	)
	// 	readableTestName = readableTestName
	// 		.replace(functionNamePattern, "")
	// 		.trim()
	// }

	return /revert/i.test(test.name)
		? `\x1b[31m${readableTestName}\x1b[0m`
		: readableTestName
}

function getReadableTestDescription(testName: string): string {
	let testNameParts = testName
		.replace(/^(test(Fork)?(Fuzz)?_)/, "")
		.split("_")

	const sourceFunction = isSourceFunction(testNameParts[0])
		? testNameParts.shift() + "()"
		: ""

	return (
		sourceFunction +
		" " +
		testNameParts
			.map((part) =>
				part
					.replace(/([a-z])([A-Z])/g, "$1 $2")
					.replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2"),
			)
			.join(" ")
			.trim()
	).trim()
}
