# Platform information

`RvPlatformInfo` is a read-only load/store device through which software can
inspect the concrete FPGA composition selected by its application. RISC-V CSRs
describe architectural state; they do not identify whether an implementation is
sequential or pipelined, uses an iterative or DSP multiplier, or maps its integer
register file to a particular FPGA resource. Those facts belong to the platform.

The composition root supplies every value as a generic parameter. The component
does not probe hardware and does not configure the processor. This keeps named
presets and explicit compositions equally describable without adding state or
optional ports to a core.

## Register map

The default base is `0x40000400`. All registers are aligned, read-only 32-bit
words. Writes, unaligned accesses and unsupported offsets complete as errors
without effects.

| Offset | Value |
|---:|---|
| `0x00` | Application-defined composition ID |
| `0x04` | ISA and machine capability bits |
| `0x08` | Execution engine ID |
| `0x0c` | Multiplier implementation ID |
| `0x10` | Integer register-file implementation ID |
| `0x14` | Platform clock frequency in hertz |

`RvPlatformInfoValues` defines the current values. ISA bits include RV32I,
Zmmul, Zicsr, machine traps, timer interrupts and external interrupts. Engine
IDs distinguish sequential and pipeline implementations. Multiplier IDs are
none, iterative and DSP; register-file IDs are array, distributed and block.
Readers must preserve and display unknown future values numerically.

## Composition

The following describes a 50 MHz named machine pipeline with iterative multiply
and block-register storage:

```livt
const ISA: uint = RvPlatformInfoValues.RV32I
	| RvPlatformInfoValues.ZMMUL
	| RvPlatformInfoValues.ZICSR
	| RvPlatformInfoValues.MACHINE_TRAPS
	| RvPlatformInfoValues.TIMER_INTERRUPTS
	| RvPlatformInfoValues.EXTERNAL_INTERRUPTS

info = new RvPlatformInfo<0x40000400, 0x00030001, ISA,
	RvPlatformInfoValues.ENGINE_PIPELINE,
	RvPlatformInfoValues.MULTIPLIER_ITERATIVE,
	RvPlatformInfoValues.REGISTER_FILE_BLOCK, 50000000>()
```

Route its 24-byte window like any other `IRv32LoadStorePort`. The composition ID
is deliberately application-defined: a project may use it as a stable board image
or product identifier, while the remaining registers describe independently
composable attributes. The reported fields are declarations and require the same
review and qualification as the composition itself.
