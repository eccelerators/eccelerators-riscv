# Single-core operating-system target

The first operating-system target is a single-hart, 32-bit Linux system. It is
deliberately one qualified composition rather than a promise that every core
variation can boot the same software. The ISA providers, privilege provider,
translation provider and physical-memory fabric remain reusable components.
Small machine-mode presets do not acquire any of the OS-only hardware.

## Qualified configuration

| Property | Target |
|---|---|
| Hart count | One hart, hart ID 0 |
| Core | Pipeline engine with a dual-read register file |
| ISA | `rv32imac_zicsr_zifencei_zicntr` |
| ABI | `ilp32` |
| Byte order | Little-endian |
| Privileged architecture | RISC-V Privileged Architecture 1.12 |
| Privilege modes | M, S and U |
| Address translation | Sv32 with ASIDs and `SFENCE.VMA` |
| Physical memory protection | Eight PMP entries with TOR and NAPOT matching |
| Misaligned scalar memory access | Precise exception; no hardware fix-up requirement |
| Clock | 50 MHz |
| Console | NS16550A-compatible UART at 115200 baud, 8-N-1 |

The qualified preset uses the full A extension, including `Zaamo` and `Zalrsc`.
Floating-point, bit-manipulation, vector and hypervisor extensions are outside
this target. They can remain separately composable and must not become Linux
dependencies. The sequential engine may reuse the new providers, but the first
OS qualification and its performance claims apply only to the pipeline engine.

The reproducible software baseline is:

- Linux `v6.18`, an upstream long-term release;
- OpenSBI `v1.9` using a platform configuration for this memory map;
- Buildroot `2026.08.1` with a BusyBox initramfs and no shared-library runtime.

Exact configurations, source checksums and compiler versions belong to the board
project that builds the image. Updating one version requires rerunning the boot
acceptance suite; it does not silently change the qualified baseline. Linux
requires an RV32 kernel image to start on a 4 MiB boundary, which determines the
layout below. See the upstream
[RISC-V boot requirements](https://docs.kernel.org/arch/riscv/boot.html),
[OpenSBI releases](https://github.com/riscv-software-src/opensbi/releases) and
[Buildroot downloads](https://buildroot.org/downloads/).

## Physical platform contract

The platform presents the same addresses on simulation, the Tang Primer 25K and
the Tang Mega 138K. Board-specific memory controllers implement the physical
memory provider behind this contract.

| Address range | Size | Function |
|---|---:|---|
| `0x02000000`-`0x0200ffff` | 64 KiB | One-hart CLINT-compatible software interrupt and timer |
| `0x0c000000`-`0x0fffffff` | 64 MiB | PLIC-compatible external interrupt controller |
| `0x10000000`-`0x10000fff` | 4 KiB | NS16550A-compatible UART |
| `0x10001000`-`0x10001fff` | 4 KiB | Read-only platform information |
| `0x80000000`-`0x83ffffff` | 64 MiB | External RAM qualification window |

The CLINT exposes `msip`, `mtimecmp` and `mtime` for hart 0. The PLIC initially
supports 16 interrupt sources and M-mode and S-mode contexts for that hart. The
UART is source 1; unused sources read inactive. The device tree is the authority
for populated sources and clock frequencies.

The initial RAM layout is:

| Address | Content |
|---|---|
| `0x80000000` | OpenSBI firmware entry and M-mode runtime |
| `0x80400000` | Uncompressed Linux `Image`, aligned to the RV32 requirement |
| Loader-selected region after the kernel | BusyBox initramfs |
| `0x83f00000` | Flattened device tree, limited to the final 1 MiB |

The first 4 MiB is reserved for M-mode firmware, its data and stacks. PMP denies
S-mode and U-mode access to that reservation after OpenSBI has initialized it.
The image builder places the initramfs after the kernel without overlap and fails
if all payloads, alignment and working space do not fit in the 64 MiB window.

## Boot contract

The FPGA CLI is the provisioning and supervision layer. It keeps the hart reset
or halted, loads OpenSBI, Linux, the initramfs and device tree into external RAM,
checks every destination and payload checksum, and then starts hart 0 at
`0x80000000`. Large generated images do not become Livt package sources or FPGA
bitstream contents.

OpenSBI begins in M-mode with `a0 = 0` and `a1 = 0x83f00000`. It owns machine
trap handling, PMP setup and the SBI base, timer, debug-console and system-reset
services. It enters Linux in S-mode at `0x80400000` with `a0 = 0`, `a1` still
pointing at the device tree, interrupts disabled and `satp = 0`. Linux owns Sv32,
user processes, the UART driver and the initramfs after entry.

The minimum kernel command line is:

```text
console=ttyS0,115200 earlycon=uart8250,mmio,0x10000000 rdinit=/sbin/init
```

The hardware owns precise traps, privilege enforcement, translation, counters,
atomicity and interrupt delivery. OpenSBI owns machine-mode policy and SBI calls.
The FPGA CLI owns loading, reset, halt and diagnosis; it does not emulate an ISA
operation or a device transaction while the hart runs.

## Dependency matrix

| Requirement | Reusable basis | Required work | Roadmap |
|---|---|---|---|
| RV32I and Zicsr | Existing decoders, integer semantics and CSR port | Extend privilege-dependent CSR behavior | OS02 |
| Full M | Existing iterative multiply provider | Add divide and remainder operations | I01 |
| Zifencei | Existing instruction-fetch fence provider | Reuse unchanged | Complete |
| Zicntr | Existing cycle and retirement accounting | Add privilege enables and standard counter views | OS02 |
| C | RV32C decompression, mixed-width instruction framing and engine length tracking | Measure FPGA resources, CPI and routed timing | I04 |
| A | RV32A decode, engine dispatch and atomic single-port RAM contract | Qualify traps, external memory and future multi-master arbitration | I05 |
| M/S/U and PMP | Existing machine trap and CSR ownership | Add cohesive privilege/PMP provider and delegation | OS02 |
| Sv32 | Existing fetch and load/store ports | Add translation ports, TLBs and a page-table walker | OS03 |
| External RAM | Existing physical fetch/load-store behavior | Add optional accepted-request/response protocol and board adapters | A03, OS04 |
| Provider recovery | Existing pause and restart controls | Specify liveness and isolate late responses | A04 |
| Timer and software interrupt | Existing timer and interrupt concepts | Provide the CLINT-compatible register map | OS04 |
| External interrupts | Existing external interrupt input | Add PLIC-compatible routing and contexts | OS04 |
| UART | Existing UART datapath concepts | Provide the NS16550A-compatible register contract | OS04 |
| SBI and Linux payloads | Existing firmware loading and FPGA supervision | Add OpenSBI platform support and reproducible images | OS05 |
| Caches | Fetch synchronization and physical memory providers | Optional instruction and data caches after uncached boot | OS06 |

The rows identify reusable ownership and semantics, not an instruction to widen
one universal interface. A provider receives a new interface when its timing,
state or completion contract differs from the compact machine core.

## Simulation platform

Architectural development uses the same addresses with a sparse 64 MiB RAM
model, so simulation allocates only written pages. The RAM model supports fixed
and variable response latency and injected access failures. CLINT, PLIC, UART and
platform-information models expose the same register contracts as hardware.

Validation proceeds in four layers:

1. Directed component tests cover C, A, privilege, PMP and Sv32 behavior.
2. A small M-mode/S-mode payload tests delegated traps, page tables and SBI calls.
3. The pinned OpenSBI and Linux images boot to the initramfs shell in simulation.
4. The identical payload set boots on the selected FPGA board.

The sparse platform is a validation composition. It does not replace the board
memory controller, timing qualification or physical interrupt tests.

## Board and resource gates

The Tang Primer 25K remains the first target when its external SDRAM module is
available. Its onboard block RAM is insufficient for the 64 MiB contract. The
Tang Mega 138K is the fallback and uses the first 64 MiB of its onboard DDR3,
keeping the device tree and software images unchanged. The capacity and logic
budgets come from Sipeed's
[Tang Primer 25K](https://en.wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html),
[SDRAM module](https://en.wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html)
and [Tang Mega 138K](https://en.wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k.html)
documentation.

| Gate | Tang Primer 25K | Tang Mega 138K fallback |
|---|---:|---:|
| External memory | 64 MiB SDRAM module, qualified at the target clock | First 64 MiB of onboard DDR3 |
| Routed CPU clock | At least 50 MHz | At least 50 MHz |
| LUT utilization | At most 18,432, 80% of 23,040 | At most 110,592, 80% of 138,240 |
| Flip-flop utilization | At most 18,432, 80% of 23,040 | At most 110,592, 80% of 138,240 |
| Block RAM utilization | At most 44 of 56 blocks | At most 272 of 340 blocks |
| Uncached sequential RAM read | At least 16 MiB/s | At least 16 MiB/s |
| Uncached sequential RAM write | At least 16 MiB/s | At least 16 MiB/s |
| Reset release to shell prompt | At most 120 seconds | At most 120 seconds |

Move qualification to the Mega as soon as the Primer lacks the SDRAM module,
exceeds one utilization limit, fails 50 MHz timing, misses either bandwidth
limit or cannot fit the payloads. The decision does not change a core or device
interface. Measurements may later relax the 64 MiB software window on the Mega,
but expansion is a separate platform profile.

The main Primer risk is not the integer datapath. The SDRAM controller, Sv32
translation, PMP, PLIC and routing margin compete for its limited LUT and block
RAM budget. This makes the Primer target feasible but resource-sensitive. The
Mega has ample logic and memory capacity; its principal qualification risk is
the DDR controller and clock-domain integration. Both boards therefore use the
same functional simulation before their separate synthesis and memory tests.
