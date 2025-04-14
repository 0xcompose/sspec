import chalk from "chalk"

/**
 * This color scheme provides clear visual distinction between:
 * 💛 Revert tests (yellow) - shows failure conditions
 * 🟣 Fuzz tests (magenta) - property-based testing
 * 🔵 Fork tests (cyan) - mainnet fork testing
 * 🌐 Integration tests (blue) - multi-contract interactions
 * 💚 Regular unit tests (green) - basic functionality
 * The colors are chosen to be visually distinct while still being readable on both light and dark terminals.
 */

export function getColoredTestName(testName: string): string {
	switch (true) {
		case /revert/i.test(testName):
			return chalk.yellow(testName) // Revert tests in red
		case /emits/i.test(testName) ||
			/expectEmit/i.test(testName) ||
			/event/i.test(testName):
			return chalk.magenta(testName) // Fuzz tests in magenta
		default:
			return chalk.green(testName) // Regular unit tests in green
	}
}
