import { main } from "../src/main.mjs"
import { expect } from "chai"

describe("Main Function", () => {
	it("should run without errors", () => {
		expect(() => main()).not.to.throw()
	})
})
