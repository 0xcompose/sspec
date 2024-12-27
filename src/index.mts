#!/usr/bin/env node

import { main } from "./main.mjs"

main(process.argv[2] || "src/", process.argv[3] || "test/")
