// src/warning.mts

// Module to manage warnings
class WarningSystem {
	private warnings: string[] = []

	addWarning(message: string) {
		this.warnings.push(message)
	}

	logWarnings() {
		if (this.warnings.length > 0) {
			console.log("\x1b[33m%s\x1b[0m", "Warnings:")
			this.warnings.forEach((warning, index) => {
				console.log(
					"\x1b[33m%s\x1b[0m",
					`${(index + 1).toString().padStart(3, " ")}. ${warning}`,
				)
			})
		}
	}
}

const warningSystem = new WarningSystem()

// Register the exit event to log warnings at the end of the process
process.on("exit", () => {
	warningSystem.logWarnings()
})

export default warningSystem
