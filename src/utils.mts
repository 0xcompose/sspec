export const DEFAULT_SOLIDITY_VERSION = "0.8.22"

export function extractSolidityVersion(source: string): string {
	const matches = source.match(/pragma solidity \^(\d+\.\d+\.\d+);/)
	return matches?.[1] ?? DEFAULT_SOLIDITY_VERSION
}
