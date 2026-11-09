# Documentation

| Guide | Contents |
|---|---|
| [Architecture](architecture.md) | Component boundaries, ownership and namespaces |
| [Core selection](cores.md) | Presets, generics and execution behavior |
| [Integration](integration.md) | Memory protocol, register storage, reset and controls |
| [Machine support](machine.md) | CSR map, exceptions, MRET and interrupts |
| [Peripherals](peripherals.md) | Timer and external interrupt components |
| [Custom components](custom-components.md) | Explicit composition and extension contracts |
| [Testing](testing.md) | Functional tests and release validation |

Declaration comments in [src](../src) specify the detailed signal and timing
contracts. The guides describe implemented behavior; a storage hint or capability
declaration does not establish resource usage, timing closure or ISA certification
for a new composition.
