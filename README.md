 # AHB-Lite Protocol — Verilog RTL Implementation

A synthesizable Verilog implementation of an **AMBA AHB-Lite** subsystem: one master, an address decoder, two slaves, and a response multiplexer. Includes a self-checking testbench and full documentation diagrams.

This is the companion project to the [APB implementation](../apb_project) — together they demonstrate the two most common AMBA on-chip buses: AHB-Lite (pipelined, high-performance system bus) and APB (simple, low-power peripheral bus).

## Architecture

![AHB-Lite Protocol Diagram](docs/ahb_protocol_diagram.png)

The system is built from five independent modules connected inside `ahb_top`:

| Module | File | Description |
|---|---|---|
| `ahb_master` | `rtl/ahb_master.v` | Converts a simple `start/write/addr/wdata` request into a standard AHB-Lite transfer (Address phase → Data phase) |
| `ahb_decoder` | `rtl/ahb_decoder.v` | Combinational address decoder, generates per-slave `HSEL` lines |
| `ahb_slave` | `rtl/ahb_slave.v` | Generic parameterized 4×32-bit register bank, zero wait-state, latches write intent at the address phase and commits it at the data phase |
| `ahb_mux` | `rtl/ahb_mux.v` | Routes `HRDATA` / `HREADYOUT` / `HRESP` from the selected slave back to the master |
| `ahb_top` | `rtl/ahb_top.v` | Top-level integration of all of the above |

## Address Map

| Region | Range | Target |
|---|---|---|
| Slave 0 | `0x0000_0000` – `0x0000_00FF` | `ahb_slave0` (4 registers, word-aligned) |
| Slave 1 | `0x0000_0100` – `0x0000_01FF` | `ahb_slave1` (4 registers, word-aligned) |

Selection is based on `HADDR[8]` (`0` → slave0, `1` → slave1).

## AHB-Lite vs APB — Key Difference

AHB-Lite is **pipelined**: the address phase (`HTRANS = NONSEQ`, address/control valid) and the data phase (`HWDATA` driven / `HRDATA` sampled) are separate, back-to-back clock cycles — unlike APB, where address and data essentially settle within a single SETUP+ACCESS pair. This is why `ahb_slave` latches the write intent and target register during the address phase, then commits the actual write one cycle later during the data phase.

## Diagrams

| Diagram | File |
|---|---|
| System block / protocol diagram | [`docs/ahb_protocol_diagram.png`](docs/ahb_protocol_diagram.png) |
| Master FSM state diagram | [`docs/ahb_master_fsm.png`](docs/ahb_master_fsm.png) |
| Pin diagram (`ahb_top`) | [`docs/ahb_pin_diagram.png`](docs/ahb_pin_diagram.png) |
| Master ↔ Slave interfacing diagram | [`docs/ahb_interfacing_diagram.png`](docs/ahb_interfacing_diagram.png) |

(Source `.svg` files are included alongside the `.png` renders for easy editing.)

## Directory Structure

```
ahb_project/
├── rtl/
│   ├── ahb_master.v
│   ├── ahb_slave.v
│   ├── ahb_decoder.v
│   ├── ahb_mux.v
│   └── ahb_top.v
├── tb/
│   └── ahb_tb.v
├── docs/
│   ├── ahb_protocol_diagram.png / .svg
│   ├── ahb_master_fsm.png / .svg
│   ├── ahb_pin_diagram.png / .svg
│   └── ahb_interfacing_diagram.png / .svg
└── README.md
```

## `ahb_top` Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `HCLK` | in | 1 | System clock |
| `HRESETn` | in | 1 | Active-low asynchronous reset |
| `start` | in | 1 | Pulse to begin a transfer |
| `write` | in | 1 | `1` = write, `0` = read |
| `addr` | in | 32 | Target address |
| `wdata` | in | 32 | Write data |
| `rdata` | out | 32 | Read data, valid when `done = 1` |
| `done` | out | 1 | 1-cycle pulse on transfer completion |
| `busy` | out | 1 | High while a transfer is in progress |

## Simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/):

```bash
iverilog -g2012 -o sim.out rtl/ahb_master.v rtl/ahb_decoder.v rtl/ahb_mux.v rtl/ahb_slave.v rtl/ahb_top.v tb/ahb_tb.v
vvp sim.out
```

Expected output:

```
ALL TESTS PASSED
```

A waveform dump (`ahb_tb.vcd`) is also generated for viewing in GTKWave.

## Synthesis

All files under `rtl/` are fully synthesizable (verified with [Yosys](https://yosyshq.net/yosys/)):

```bash
yosys -p "read_verilog rtl/*.v; hierarchy -top ahb_top; proc; opt; synth -top ahb_top; stat"
```

`tb/ahb_tb.v` is simulation-only and is not part of the synthesizable design.

## License

MIT — see [LICENSE](LICENSE).
