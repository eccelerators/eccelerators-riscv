# Functional tests

Run `livt test` from the package root. Test components and their local helpers are
checked in; normal test execution needs neither an FPGA board nor a RISC-V
firmware toolchain.

The `fixtures` JSON files preserve independent expected traces behind the Livt
tables. They cover operand pairs, instruction words and ordered retirement
results. Keep these expectations independent of the implementation under test.

Each stateful scenario initializes the processor and memories it uses. Protocol
tests additionally check held requests, delayed responses and exactly-once effects.
See [testing](../docs/testing.md) for the suite's scope and validation limits.
