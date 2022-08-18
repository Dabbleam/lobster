import pretty from "pretty"
import getStdin from "get-stdin"

const stdin = await getStdin()
const prettified = pretty( stdin, { ocd: true } )

// I hate using console.log but writing to stdout can fail with EAGAIN
console.log( prettified )