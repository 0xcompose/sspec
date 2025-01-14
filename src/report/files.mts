import path from "path"
import { CategorizedFilesFromTestFolder } from "../utils/categorize.mjs"

function printFileSection(files: any[], sectionName: string) {
	console.log(` |-------------------------------------`)
	console.log(` |`)
	console.log(` | Identified ${files.length} ${sectionName} files in test/:`)
	console.log(` |`)
	for (const file of files) {
		console.log(` |-- ${path.basename(file.path)} (${file.version})`)
	}
}

export function reportFilesFromTestFolder(
	categorizedFiles: CategorizedFilesFromTestFolder,
) {
	const { testFiles, setupFiles, utilsFiles } = categorizedFiles
	const filesLength = testFiles.length + setupFiles.length + utilsFiles.length

	console.log(` | Identified ${filesLength} solidity files in test/:`)

	printFileSection(testFiles, "test")
	printFileSection(setupFiles, "setup")
	printFileSection(utilsFiles, "utility")
	console.log(` |-------------------------------------\n\n`)
}
