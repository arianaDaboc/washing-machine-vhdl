# Washing Machine Controller in VHDL

A digital **washing machine controller** for FPGA, written in VHDL as a set of **finite state machines**. It supports automatic programs and a manual mode with configurable temperature, spin speed, prewash and extra rinse, and shows the remaining time and the current state on a seven-segment display and LEDs.

📄 [Project documentation (Word)](documentation/documentation.docx)

![VHDL](https://img.shields.io/badge/language-VHDL-blue) ![FPGA](https://img.shields.io/badge/target-FPGA%20(100%20MHz)-orange) ![Vivado](https://img.shields.io/badge/tools-Xilinx%20Vivado-red)

---

## Features

- **Automatic mode** with 5 built-in programs
- **Manual mode**: choose temperature, spin speed, prewash and extra rinse yourself
- **Door safety**: the cycle only starts with the door closed, and the door stays locked while washing
- Full washing sequence: fill → prewash → heat → main wash → rinse → (extra rinse) → spin → complete
- **Remaining time** calculated from the chosen settings and counted down every second
- Three-stage spin that ramps up as the cycle nears its end
- Seven-segment display and status LEDs
- Global reset back to idle at any time

## Automatic programs

| `preset_sel` | Program | Temperature | Spin speed | Prewash | Extra rinse |
|---|---|---|---|---|---|
| `000` | Quick Wash | 30 °C | 1200 rpm | – | – |
| `001` | Shirts | 60 °C | 800 rpm | – | – |
| `010` | Dark Colors | 40 °C | 1000 rpm | – | ✔ |
| `011` | Dirty Laundry | 40 °C | 1000 rpm | ✔ | – |
| `100` | Antiallergenic | 90 °C | 1200 rpm | – | ✔ |

In manual mode, `temp_sel` picks 30 / 40 / 60 / 90 °C (`00`–`11`) and `speed_sel` picks 800 / 1000 / 1200 rpm (`00`–`10`).

## State machines

**Main controller**

```text
IDLE → MODE_SELECT → CHECK_MODE ─┬─ auto ──► AUTO_PRESET ─────────────────────────────┐
                                 └─ manual ► MANUAL_TEMP → MANUAL_SPEED → MANUAL_OPTIONS ┤
                                                                                        ▼
                                                                         READY → WASHING → IDLE
```

**Washing sub-states**

```text
FILL_WATER → PRE_WASH → DRAIN_PRE → HEAT_WATER → MAIN_WASH → DRAIN_MAIN
          → RINSE_FILL → RINSE → EXTRA_RINSE_CHECK → [EXTRA_RINSE] → DRAIN_RINSE → SPIN → COMPLETE
```

Prewash and extra rinse are skipped when they're not enabled. When the cycle completes, the door unlocks and the controller returns to `IDLE`.

## Interface (top-level entity `main`)

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | 100 MHz system clock |
| `reset` | in | 1 | Global reset to `IDLE` |
| `start_btn` | in | 1 | Starts the cycle |
| `door_closed` | in | 1 | Door sensor |
| `mode_auto` | in | 1 | `1` = automatic, `0` = manual |
| `preset_sel` | in | 3 | Automatic program |
| `temp_sel` | in | 2 | Manual temperature |
| `speed_sel` | in | 2 | Manual spin speed |
| `prewash_btn` | in | 1 | Enables prewash (manual) |
| `extra_rinse_btn` | in | 1 | Enables extra rinse (manual) |
| `config_saved` | in | 1 | Confirms the current setting |
| `ssd_display` | out | 8 | Seven-segment display |
| `state_leds` | out | 4 | Current state indicator |

## Design structure

```text
main (top level)
├── state_transition_module   main FSM: mode selection and configuration flow
├── signal_handler_module     washing sub-states, timers, actuators (motor, valves, heater, door lock)
├── spin_decoder_module       spin phase and speed decoding
└── display_controller_module seven-segment display and status LEDs
washing_machine_pkg           shared types, constants, time calculation and counter helpers
```

## Repository layout

```text
src/             synthesizable RTL design
tb1/             testbenches (main, state transitions, signal handler, spin, display)
documentation/   project documentation
```

## Simulation and synthesis

1. Create a new project in **Xilinx Vivado** and add the files from `src/` as design sources.
2. Add the files from `tb1/` as simulation sources and set the testbench you want (for example `main_tb`) as top.
3. Run **Behavioral Simulation** to watch the transitions from `IDLE` to `COMPLETE`.
4. For hardware, set `main` as the top module, add a constraints file (`.xdc`) for your board, then synthesise, implement and generate the bitstream.

> The timers assume a 100 MHz clock (`CLOCK_FREQ` in `washing_machine_pkg.vhd`). Change it to match your board.
