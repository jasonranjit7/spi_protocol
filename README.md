# SPI Protocol — RTL Implementation in Verilog

A synthesizable Verilog implementation of a complete SPI (Serial Peripheral Interface) system comprising a master, a slave, and a top-level wrapper that connects them. Simulated with Icarus Verilog and targeting Xilinx Artix-7 FPGA (xc7a35tftg256-1) via Vivado.

---

## Repository Structure

```
spi_protocol/
├── design/
│   ├── spi_master.v   # SPI Master — 3-state FSM, drives SCLK, MOSI, CS
│   └── spi_slave.v    # SPI Slave  — 2-state FSM, clocked on SCLK negedge
|   └── spi_top.v      # Top-level wrapper — master ↔ slave full-duplex loopback
└── test/
    └── tb_spi_top.v
```

---

## Protocol Overview

SPI is a synchronous, full-duplex, master-slave serial protocol. Four wires connect master and slave:

| Signal | Direction      | Description                                   |
|--------|----------------|-----------------------------------------------|
| `sclk` | Master → Slave | Serial clock; gated — only active during TRANSFER |
| `mosi` | Master → Slave | Master Out Slave In; MSB-first                |
| `miso` | Slave → Master | Master In Slave Out; MSB-first                |
| `cs`   | Master → Slave | Chip Select; **active-low** (slave enabled when `cs = 0`) |

Data is exchanged MSB-first. Both master and slave shift simultaneously — every transaction is a full-duplex 8-bit exchange.

---

## Clock Scheme — SPI Mode 0 (CPOL=0, CPHA=0)

```
SCLK  ____/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\____
MOSI  ----< D7  D6  D5  D4  D3  D2  D1  D0 >----   driven at posedge clk (master)
MISO  ----< Q7  Q6  Q5  Q4  Q3  Q2  Q1  Q0 >----   sampled at negedge clk (master)
```

- `sclk` is gated: `assign sclk = (state == TRANSFER) ? clk : 0`
- Master **drives** MOSI and shifts `master_out_reg` on **posedge clk**
- Master **samples** MISO into `master_in_reg` on **negedge clk**
- Slave **drives** MISO and shifts `sl_out` on **negedge sclk**
- Slave **captures** MOSI into `sl_in` on **negedge sclk**

---

## Module Descriptions

### `spi_master`

Drives SCLK, MOSI, and CS; captures incoming MISO data.

**Ports:**

| Port   | Dir       | Width | Description                              |
|--------|-----------|-------|------------------------------------------|
| `clk`  | input     | 1     | System clock                             |
| `rst`  | input     | 1     | Synchronous active-high reset            |
| `en`   | input     | 1     | Pulse high to start a transfer           |
| `data` | input     | 8     | Byte to send over MOSI                   |
| `miso` | input     | 1     | Serial data in from slave                |
| `mosi` | output reg| 1     | Serial data out to slave (MSB-first)     |
| `cs`   | output reg| 1     | Chip select (active-low)                 |
| `sclk` | output    | 1     | Gated serial clock                       |

**FSM — 3 states:**

```
         en asserted
  IDLE ──────────────► SETUP ──── 1 clk ──► TRANSFER ──── count==8 ──► IDLE
                        (cs=0,               (shift MOSI,                (cs=1,
                        load data)            sample MISO,               c_rst)
                                              count++)
```

- **IDLE**: CS deasserted (`cs=1`), waiting for `en`
- **SETUP**: CS asserted (`cs=0`), `master_out_reg` loaded from `data` input; lasts exactly one clock
- **TRANSFER**: SCLK running, `master_out_reg[7]` driven onto MOSI each cycle, left-shifted when `count > 0`; MISO sampled into `master_in_reg` on negedge; `count` increments each posedge; returns to IDLE when `count == 8` and resets counter via `c_rst`

**Shift register behaviour:**

```verilog
// TX: shift left, MSB out first
master_out_reg <= {master_out_reg[6:0], 1'b0};

// RX: shift left, MISO appended as LSB
master_in_reg  <= {master_in_reg[6:0], miso};
```

---

### `spi_slave`

Receives MOSI data and drives MISO; clocked entirely on `negedge sclk` — no system clock dependency.

**Ports:**

| Port    | Dir       | Width | Description                              |
|---------|-----------|-------|------------------------------------------|
| `sclk`  | input     | 1     | Serial clock from master                 |
| `rst`   | input     | 1     | Synchronous reset (on negedge sclk)      |
| `mosi`  | input     | 1     | Serial data in from master               |
| `cs`    | input     | 1     | Chip select (active-low)                 |
| `miso`  | output reg| 1     | Serial data out to master (MSB-first)    |
| `sl_in` | output reg| 8     | Deserialized byte received from master   |

**FSM — 2 states:**

```
         !cs (chip select low)
  IDLE ──────────────────────► TRANSFER ──── count==8 or cs high ──► IDLE
                                 (shift sl_out → MISO,
                                  capture MOSI → sl_in,
                                  count++)
```

- **IDLE**: Waits for `cs` to go low; `miso` driven 0
- **TRANSFER**: On each `negedge sclk`, `sl_out` shifts left (MSB → MISO), `mosi` bit appended into `sl_in`; exits when `count == 8` or CS deasserted

**Shift register behaviour:**

```verilog
// TX: shift left, MSB driven on MISO
sl_out <= {sl_out[6:0], 1'b0};

// RX: build received byte LSB-to-index; MOSI appended into bit 0 each cycle
sl_in  <= {sl_in[6:0], mosi};
```

`sl_out` is initialized to `8'hFF` on reset — slave transmits all-ones by default until loaded with real data.

---

### `spi_top`

Top-level loopback wrapper. Connects master and slave directly for simulation.

**Ports:**

| Port     | Dir    | Width | Description                          |
|----------|--------|-------|--------------------------------------|
| `clk`    | input  | 1     | System clock                         |
| `rst`    | input  | 1     | Synchronous active-high reset        |
| `en`     | input  | 1     | Start transfer                       |
| `m_data` | input  | 8     | Byte for master to send              |
| `sl_data`| output | 8     | Byte received by slave from master   |

Internal wires `mosi`, `miso`, `cs`, and `sclk` connect master and slave. A testbench can assert `en`, drive `m_data`, and read `sl_data` to verify a complete round-trip.

---

## Simulation

Tested with [Icarus Verilog](https://steveicarus.github.io/iverilog/):

```bash
# Compile (spi_master.v and spi_slave.v are `include'd automatically)
iverilog -o spi_sim test/spi_top.v

# Run
vvp spi_sim

# View waveforms
gtkwave dump.vcd
```

A typical testbench asserts `en = 1` for one clock, drives `m_data = 8'hA5`, then checks that `sl_data == 8'hA5` after 8 SCLK cycles.

---

## Key Design Decisions

| Decision | Detail |
|---|---|
| **Gated SCLK** | `sclk = (state == TRANSFER) ? clk : 0` — eliminates spurious edges outside a transaction; SCLK is exactly 8 cycles per transfer |
| **Dual clock edges** | Master drives MOSI on `posedge clk`, samples MISO on `negedge clk`; meets SPI Mode 0 setup/hold requirements |
| **Slave on negedge sclk** | Slave uses only `negedge sclk` for all sequential logic — eliminates system clock dependency, models a real standalone SPI peripheral |
| **SETUP state** | One dedicated clock cycle to assert CS and load `data` into `master_out_reg` before shifting begins; prevents first-bit corruption |
| **`c_rst` counter reset** | Counter cleared combinationally at `count == 8` before returning to IDLE, ensuring it is zero at the next transfer start |
| **MSB-first throughout** | Both master and slave shift left and drive `reg[7]` onto the serial line, conforming to the SPI convention used by most sensors and peripherals |
| **Default slave TX = 0xFF** | `sl_out` resets to `8'hFF`; slave drives `1` on MISO when no data is loaded — line idles high |

---

## Author

Jason Ranjit J  
MS Electrical & Computer Engineering — University of Wisconsin–Madison  
GitHub: [@jasonranjit7](https://github.com/jasonranjit7)
