import fs from "fs"
import { expect } from "chai"
import { parseSoliditySourceFile } from "../../src/parse/src.mjs"
import { extractSolidityVersion } from "../../src/utils.mjs"
import { fail } from "assert"

describe("Parse Source File", () => {
	// Single Contract File
	const singleContractPath = "./samples/src/core/MaatVaultV1.sol"
	const singleContractSource = fs.readFileSync(singleContractPath, "utf8")

	const singleSolidityVersion = extractSolidityVersion(singleContractSource)

	// Multiple Contracts File
	const multipleContractsPath = "./samples/src/core/execute/Executor.sol"
	const multipleContractsSource = fs.readFileSync(
		multipleContractsPath,
		"utf8",
	)
	const multipleSolidityVersion = extractSolidityVersion(
		multipleContractsSource,
	)

	it("should parse the source file", () => {
		const result = parseSoliditySourceFile({
			filePath: "./samples/src/core/MaatVaultV1.sol",
			version: singleSolidityVersion,
		})

		if (!result) {
			fail("Result is undefined")
		}

		expect(result).to.be.an.instanceOf(Map)
		expect(result).to.have.lengthOf(1)
		expect(result.has("MaatVaultV1")).to.be.true
	})

	it.skip("should parse the source file with multiple contracts", () => {
		const source = fs.readFileSync(
			"./samples/src/core/MaatVaultV1.sol",
			"utf8",
		)
	})

	it("should parse functions in a contract", () => {
		const result = parseSoliditySourceFile({
			filePath: singleContractPath,
			version: singleSolidityVersion,
		})

		if (!result) {
			fail("Result is undefined")
		}

		const functions = result.get("MaatVaultV1")

		expect(functions).to.be.an.instanceOf(Array)
		expect(functions).to.have.lengthOf(8)
	})

	it.skip("should parse the source file with multiple contracts and functions", () => {
		const source = fs.readFileSync(
			"./samples/src/core/MaatVaultV1.sol",
			"utf8",
		)
	})
})
