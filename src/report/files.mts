import path from "path"
import { CategorizedFiles } from "../files.mjs"

function printFileSection(files: any[], sectionName: string) {
	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Identified ${files.length} ${sectionName} files in test/:`)
	console.log(` |`)
	for (const file of files) {
		console.log(` |-- ${path.basename(file.filePath)} (${file.version})`)
	}
}

export function reportFiles(categorizedFiles: CategorizedFiles) {
	const { testFiles, setupFiles, utilsFiles, errors } = categorizedFiles
	const filesLength =
		testFiles.length + setupFiles.length + utilsFiles.length + errors.length

	console.log(` | Identified ${filesLength} solidity files in test/:`)

	printFileSection(testFiles, "test")
	printFileSection(setupFiles, "setup")
	printFileSection(utilsFiles, "utility")
	console.log(` |-------------------------------------\n\n`)
}
