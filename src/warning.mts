// src/warning.mts

// Module to manage warnings
class WarningSystem {
	private warnings: Set<string> = new Set()
	private errors: Set<string> = new Set()

	addWarning(message: string) {
		this.warnings.add(message)
	}

	addError(message: string) {
		this.errors.add(message)
	}

	logWarnings() {
		if (this.warnings.size == 0) return

		let counter = 1
		console.log("\x1b[33m%s\x1b[0m", "Warnings:")

		this.warnings.forEach((warning) => {
			console.log(
				"\x1b[33m%s\x1b[0m",
				`${counter.toString().padStart(3, " ")}. ${warning}`,
			)
			counter++
		})
	}

	logErrors() {
		if (this.errors.size == 0) return

		let counter = 1
		console.log("\x1b[31m%s\x1b[0m", "Errors:")

		this.errors.forEach((error) => {
			console.log(
				"\x1b[31m%s\x1b[0m",
				`${counter.toString().padStart(3, " ")}. ${error}`,
			)
			counter++
		})
	}

	hasErrors() {
		return this.errors.size > 0
	}
}

const warningSystem = new WarningSystem()

// Register the exit event to log warnings at the end of the process
process.on("exit", () => {
	warningSystem.logWarnings()
	warningSystem.logErrors()

	if (warningSystem.hasErrors()) {
		process.exit(1)
	}
})

export default warningSystem
