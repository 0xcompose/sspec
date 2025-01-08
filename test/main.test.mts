import { main } from "../src/main.mjs"
import { expect } from "chai"

describe("Main Function", () => {
	it("should run without errors", () => {
		const options = {
			includeInternal: false,
			srcDir: "./samples/src/",
			testDir: "./samples/test/"
		}
		expect(() => main(options)).not.to.throw()
	})
})
