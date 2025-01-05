import { SourceContracts } from "./types.mjs"
import { parseSoliditySourceFiles } from "./src.mjs"
import { findSolidityFiles } from "../utils/files.mjs"

class SourceContractsSingleton {
	private static instance: SourceContractsSingleton
	private sourceContracts: SourceContracts | null = null

	private constructor() {}

	public static getInstance(): SourceContractsSingleton {
		if (!SourceContractsSingleton.instance) {
			SourceContractsSingleton.instance = new SourceContractsSingleton()
		}
		return SourceContractsSingleton.instance
	}

	public initialize(sourceDirectory: string): void {
		if (this.sourceContracts) return

		const solidityFiles = findSolidityFiles(sourceDirectory)
		this.sourceContracts = parseSoliditySourceFiles(solidityFiles)
	}

	public getSourceContracts(): SourceContracts {
		if (!this.sourceContracts) {
			throw new Error(
				"SourceContracts not initialized. Call initialize() first.",
			)
		}
		return this.sourceContracts
	}
}

export default SourceContractsSingleton.getInstance()
