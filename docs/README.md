# Documentation

| Guide | Contents |
|---|---|
| [Architecture](architecture.md) | Component boundaries, ownership and namespaces |
| [Core selection](cores.md) | Presets, generics and execution behavior |
| [System composition](system.md) | Default memories, explicit routing and UART |
| [Integration](integration.md) | Memory protocol, register storage, reset and controls |
| [Atomic memory](atomic-memory.md) | LR/SC ownership, AMO indivisibility and multi-master obligations |
| [Machine support](machine.md) | CSR map, exceptions, MRET and interrupts |
| [Peripherals](peripherals.md) | Timer and external interrupt components |
| [Platform information](platform-info.md) | Software-visible composition identity and implementation choices |
| [Custom components](custom-components.md) | Explicit composition and extension contracts |
| [ISA extension boundaries](isa-extensions.md) | Reuse map for standard and custom extensions |
| [Operating-system target](os-target.md) | Single-core Linux ISA, platform, boot and board contract |
| [Testing](testing.md) | Functional tests and release validation |

Declaration comments in [src](../src) specify the detailed signal and timing
contracts. The operating-system target is an explicit qualification contract for
planned work; the other guides describe implemented behavior. A storage hint or
capability declaration does not establish resource usage, timing closure or ISA
certification for a new composition.
