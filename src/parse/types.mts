export type SourceContracts = Map<ContractName, FunctionName[]>

export type FunctionName = string
export type ContractName = string
export type FeatureName = string
export type SourceContractName = ContractName

// Feature tests and integration tests are unsupported, that's why we have an unknown scope type
export enum ScopeType {
	Function = "function",
	Contract = "contract",
	Feature = "feature",
	Unknown = "unknown",
}

export type TestFileScope =
	| ContractScope
	| FunctionScope
	| FeatureScope
	| UnknownScope

// Doesn't include contract scope
export type TestFunctionScope = FunctionScope | FeatureScope | UnknownScope

// Assumes there is only one contract in the file
// otherwise throws an error
export interface TestFile {
	filePath: string
	testContract: ContractName
	targetContract: ContractName
	scope: TestFileScope
	tests: TestFunction[]
	setUps: string[] // setUp(), _setUp(), _afterSetup(), _beforeSetup()
}

// FunctionScope is usually expected to a Unit test for specific function, constructor or feature
export interface TestFunction {
	name: FunctionName
	scope: TestFunctionScope
}

export interface Scope {
	type: ScopeType
	target?: string
}

export interface FeatureScope extends Scope {
	type: ScopeType.Feature
	target: FeatureName
}

export interface FunctionScope extends Scope {
	type: ScopeType.Function
	target: FunctionName
}

export interface ContractScope extends Scope {
	type: ScopeType.Contract
	target: SourceContractName
}

export interface UnknownScope extends Scope {
	type: ScopeType.Unknown
}
