# 5-Stage Pipelined RISC-V Processor

A fully functional **32-bit pipelined RISC-V processor** implemented in Verilog, targeting the RV32I subset with a custom Multiply-Accumulate (MAC) instruction. The design resolves data hazards through forwarding and load-use stalling, and handles control hazards via pipeline flushing — achieving a **CPI of 1.31** across a 32-instruction test program.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
- [Hazard Handling](#hazard-handling)
- [Custom MAC Instruction](#custom-mac-instruction)
- [Supported ISA](#supported-isa)
- [Performance](#performance)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)
- [Author](#author)

---

## Overview

This project implements a classic 5-stage RISC-V pipeline — IF, ID, EX, MEM, WB — in synthesisable Verilog. In addition to this, pipeline is extended with the following:

- **Full data hazard resolution** via MEM→EX and WB→EX forwarding paths, with a dedicated forwarding unit
- **Load-use hazard detection** via a stall unit that inserts a bubble and freezes the PC and IF/ID register for one cycle
- **Branch resolution** via a flush mechanism that clears the IF/ID register when a BEQ is taken
- **Custom MAC instruction** with opcode `0x0B`, extending the base ISA with a multiply-accumulate operation in a dedicated execution unit

---

## Architecture

The diagram below shows the complete datapath: five pipeline stages, four pipeline registers, forwarding paths, the stall unit, and the MAC unit.

![Pipeline Architecture](pipeline_architecture.png)

---

## Pipeline Stages

| Stage | Module(s) | Key function |
|:-----:|:----------|:-------------|
| **IF** | `pc`, `instr_mem` | Fetch instruction at current PC; PC updates to `PC+4` or branch target |
| **ID** | `reg_file`, `imm_gen`, `cntrl` | Decode instruction, read registers, generate immediate, produce control signals |
| **EX** | `alu`, `alu_cntrl`, MAC unit | Execute arithmetic/logic; forwarding muxes select correct operands |
| **MEM** | `data_mem` | Read/write data memory; branch decision finalised here |
| **WB** | `mem_wb` register | Write result back to register file (ALU result or memory data) |

### Pipeline registers

Each stage is separated by a clocked register that propagates both data and control signals:

- `if_id` — flushable on branch taken, stallable on load-use
- `id_ex` — flushable (inserts bubble) on stall or branch taken
- `ex_mem` — passes ALU result, store data, rd, and control signals
- `mem_wb` — passes memory read data and ALU result for write-back selection

---

## Hazard Handling

### Data hazards — forwarding

The `fwdunit` module compares the source registers of the EX-stage instruction (`rs1_ex`, `rs2_ex`) against the destination registers of the MEM and WB stage instructions. It drives two 2-bit select signals:

| `fwdA` / `fwdB` | Source selected |
|:---:|:---|
| `00` | Register file output (no hazard) |
| `10` | ALU result from MEM stage (MEM→EX path) |
| `01` | Write-back data from WB stage (WB→EX path) |

This covers back-to-back RAW hazards (MEM→EX) and two-cycle RAW hazards (WB→EX) without any stalls.

### Load-use hazard — stalling

When a `LW` instruction is in the EX stage and its destination register matches a source register of the next instruction in ID, forwarding alone cannot resolve the hazard (the memory data is not yet available). The `stlunit` module:

1. Detects: `memr_ex == 1` and `rd_ex == rs1_id` or `rd_ex == rs2_id`
2. Freezes the PC (preventing fetch of a new instruction)
3. Freezes the IF/ID register (holding the dependent instruction)
4. Inserts a bubble (NOP) into the ID/EX register for one cycle

This produces exactly **1 stall cycle per load-use hazard**.

### Control hazards — branch flushing

BEQ is resolved at the end of the MEM stage. When `pcsrc = branch_ex & zero` is asserted, the IF/ID register is flushed (cleared to NOP), discarding the incorrectly fetched instruction. This incurs a **1-cycle penalty** on taken branches.

---

## Custom MAC Instruction

The MAC (Multiply-Accumulate) instruction uses the custom opcode `0x0B` (binary `0001011`).

**Operation:** `rd = rs1 × rs2 + rd`

The control unit (`cntrl`) sets `macop = 1` for this opcode, bypassing the standard ALU and routing execution to the dedicated MAC unit. The result is written back to the destination register like any other R-type instruction (`regw = 1`).

This is useful for DSP-style computations such as dot products and FIR filter inner loops.

---

## Supported ISA

| Type | Instructions | Opcode |
|:----:|:-------------|:------:|
| R-type | ADD, SUB, AND, OR | `0110011` |
| I-type | ADDI | `0010011` |
| I-type | LW | `0000011` |
| S-type | SW | `0100011` |
| B-type | BEQ | `1100011` |
| Custom | MAC | `0001011` |

The immediate generator (`imm_gen`) handles sign extension for I-type, S-type, and B-type encodings per the RV32I specification.

---

## Performance

| Metric | Value |
|:-------|:-----:|
| Total instructions | 32 |
| Total cycles | 42 |
| CPI | **1.31** |
| Stall cycles | 3 (load-use only) |
| Branch penalty cycles | 0 (no taken branches in test program) |
| Ideal CPI (no hazards) | 1.0 |
| Pipeline efficiency | ~76% |

The 3 stall cycles arise from load-use hazards (a `LW` followed immediately by an instruction that reads its destination). All data hazards between non-load instructions are resolved by forwarding with zero stall overhead.

---

## Project Structure

```
RISCV_Pipeline/
│
├── riscv.v                  # Complete processor — all modules in one file
│   ├── alu                  # ALU: ADD, SUB, AND, OR
│   ├── reg_file             # 32×32 register file with write-first forwarding
│   ├── imm_gen              # Immediate generator (I / S / B types)
│   ├── cntrl                # Main control unit
│   ├── alu_cntrl            # ALU control (decodes funct3/funct7)
│   ├── pc                   # Program counter register
│   ├── instr_mem            # Instruction memory (reads test.hex)
│   ├── data_mem             # Data memory (word-addressed, 256 words)
│   ├── riscv1               # Top-level processor (datapath + control)
│   ├── if_id                # IF/ID pipeline register (stallable, flushable)
│   ├── id_ex                # ID/EX pipeline register (flushable)
│   ├── ex_mem               # EX/MEM pipeline register
│   ├── mem_wb               # MEM/WB pipeline register
│   ├── fwdunit              # Forwarding unit (MEM→EX, WB→EX)
│   ├── stlunit              # Stall unit (load-use hazard detection)
│   └── risc_tb              # Testbench (reads test.hex + expected.hex)
│
├── test.hex                 # Test program in hex (loaded into instr_mem)
├── expected.hex             # Expected register values for automated checking
├── pipeline_architecture.png  # Architecture diagram
└── README.md
```

---

## How to Run

### Prerequisites

- ModelSim (or any Verilog simulator supporting `$readmemh`)
- A hex assembler or hand-assembled `test.hex` file

### Step 1 — Prepare instruction memory

Write your RISC-V program, assemble it to hex, and save as `test.hex`. Each line is one 32-bit instruction in hex, e.g.:

```
00500093   // ADDI x1, x0, 5
00A00113   // ADDI x2, x0, 10
002081B3   // ADD  x3, x1, x2
```

### Step 2 — Prepare expected outputs

Fill `expected.hex` with the expected register values after the program completes. Use `xxxxxxxx` for registers you don't want to check:

```
xxxxxxxx   // x0  (always 0, skip)
00000005   // x1  (expect 5)
0000000A   // x2  (expect 10)
0000000F   // x3  (expect 15)
```

### Step 3 — Simulate in ModelSim

```tcl
vlog riscv.v
vsim risc_tb
run -all
```

The testbench will print `PASS` or `FAIL` for each checked register at the end of simulation.

---

## Author

**Madhusudan K**  
[LinkedIn](https://www.linkedin.com/in/madhusudan-kannan/) 
[Email](mailto:maddyoff.04@gmail.com)
