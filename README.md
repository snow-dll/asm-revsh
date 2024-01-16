# asm-revsh
x64 ASM Rev Shell

## Request Patterns
The agent sends requests to 2 endpoints:
    - GET /tasks
    - POST /results

## Command Execution
Currently, asm-revsh only supports execution of binaries, given a full path.
Execution is performed through an execve child process.

## Networking
asm-revsh connects to localhost:3000 by default.
