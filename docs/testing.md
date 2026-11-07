# Testing and release validation

From the package root:

```sh
livt sync
livt test
```

The manifest lists the functional test components. Tests include instruction
semantics and decode, reference APIs, register-file behavior, memory protocols,
sequential/pipeline execution, control draining, multiplication, CSR access,
precise traps and timer/external interrupts. Checked-in Livt vectors make these
tests independent of a firmware compiler, a physical board and benchmark tools.
JSON fixtures retain the independent expected traces used to generate the tables.

Passing simulation establishes functional regression coverage. It does not prove
ISA certification, resource use, timing closure, power or correctness on a physical
board. Changed sources, tools, providers or parameters require their own relevant
validation; historical hardware records describe only their exact source trees.

Before a release, run the suite from the intended source revision, review public
contracts and update the changelog/version. The current Livt publisher selects
`livt.toml` and files under the configured source and test directories. It does not
upload the repository's `docs` directory. Keep generated output outside `src` and
`tests`; host the documentation with the repository/release.
