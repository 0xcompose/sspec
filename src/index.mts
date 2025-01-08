#!/usr/bin/env node

import { main } from "./main.mjs"

const args = process.argv.slice(2)

export interface CliOptions {
    includeInternal: boolean
    srcDir: string
    testDir: string
}

const options: CliOptions = {
    includeInternal: false,
    srcDir: "",
    testDir: ""
}

const helpMessage = `
Usage: sspec [options] [srcDir] [testDir]

Options:
  --include-internal    Include internal functions in analysis
  --help, -h            Show this help message

Arguments:
  srcDir          Source directory (default: "src/")
  testDir         Test directory (default: "test/")
`

// Parse arguments
for (let i = 0; i < args.length; i++) {
    if (args[i] === "--include-internal") {
        options.includeInternal = true
	} else if (args[i] === "--help" || args[i] === "-h") {
		console.log(helpMessage)
		process.exit(0)
	} else if (!options.srcDir) {
		options.srcDir = args[i]
	} else if (!options.testDir) {
		options.testDir = args[i]
	}
}

if (!options.srcDir) {
    options.srcDir = "src/"
}

if (!options.testDir) {
    options.testDir = "test/"
}

main(options)


