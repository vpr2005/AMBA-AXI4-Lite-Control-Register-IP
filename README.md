# AMBA AXI4-Lite Control Register IP

A modular, synthesizable **AMBA AXI4-Lite Control Register Interface** implemented in SystemVerilog, designed for connecting host processors (CPUs/SoCs) with hardware accelerators, AI/CNN inference engines, or custom FPGA compute blocks.

---

## 🚀 Overview

The AXI4-Lite protocol is a lightweight subset of the AMBA AXI4 specification tailored for simple memory-mapped register access. This repository provides:
- **`axi4_lite_if.sv`**: SystemVerilog interface encapsulating all five AXI4-Lite channels (`AW`, `W`, `B`, `AR`, `R`) with dedicated `master` and `slave` modports.
- **`axi4_lite_master.sv`**: Synthesizable FSM-based master controller that bridges simple single-cycle user requests (`start_write`, `start_read`) into full AXI4-Lite protocol handshakes.
- **`axi4_lite_slave.sv`**: General-purpose memory-mapped slave with word-aligned addressing and 1KB (256 × 32-bit) internal memory.
- **`axi4_lite_ctrl_regs.sv`**: Memory-mapped control and status register (CSR) block exposing hardware handshake control lines (`accel_start`, `accel_threshold`, `accel_done`) to control an attached accelerator core.
- **`tb_axi4_lite.sv`**: Testbench verifying fundamental AXI4-Lite read/write memory operations.
- **`tb_axi4_lite_accel.sv`**: End-to-end system testbench simulating CPU register configuration, accelerator execution, and interrupt/status polling.

---

## 📋 Register Map (`axi4_lite_ctrl_regs`)

| Address Offset | Register Name | Access | Bit(s) | Description |
|:---:|:---:|:---:|:---:|:---|
| **`0x00`** | `REG_CONTROL` | R/W | `[0]` | **Start Bit (`accel_start`)**: Write `1` to trigger accelerator execution. |
| | | | `[31:1]` | Reserved. |
| **`0x04`** | `REG_THRESHOLD` | R/W | `[31:0]` | **Configuration Threshold (`accel_threshold`)**: Parameter passed to the accelerator core. |
| **`0x08`** | `REG_STATUS` | R | `[0]` | **Status Done (`accel_done`)**: Read-only status flag (`1` = accelerator completed task). |
| | | | `[31:1]` | Reserved (reads `0`). |

---

## 📂 Project Structure

```plaintext
.
├── .gitignore
├── README.md
├── project_1.xpr                               # AMD Vivado project file
└── project_1.srcs/
    ├── sources_1/new/
    │   ├── axi4_lite_if.sv                     # AXI4-Lite SystemVerilog Interface
    │   ├── axi4_lite_ctrl_regs.sv              # Accelerator Control Registers IP
    │   ├── axi4_lite_master.sv                 # AXI4-Lite Master FSM Controller
    │   └── axi4_lite_slave.sv                  # AXI4-Lite Slave Memory Block
    └── sim_1/new/
        ├── tb_axi4_lite.sv                     # Testbench for memory read/write
        └── tb_axi4_lite_accel.sv               # System-level accelerator testbench
```

---

## 🔄 Protocol Channels

The SystemVerilog interface implements all 5 AXI4-Lite channels:
1. **Write Address Channel (`AW`)**: `awaddr`, `awvalid`, `awready`
2. **Write Data Channel (`W`)**: `wdata`, `wstrb`, `wvalid`, `wready`
3. **Write Response Channel (`B`)**: `bresp`, `bvalid`, `bready`
4. **Read Address Channel (`AR`)**: `araddr`, `arvalid`, `arready`
5. **Read Data Channel (`R`)**: `rdata`, `rresp`, `rvalid`, `rready`

---

## 🛠️ Getting Started with AMD Vivado

### Open Project
1. Launch **AMD Vivado** (2020.2 or later).
2. Open `project_1.xpr` via **File > Open Project**.

### Run Simulation
To run the accelerator system testbench:
1. In the **Sources** hierarchy, set `tb_axi4_lite_accel` as the top simulation module (right-click > **Set as Top**).
2. Click **Run Simulation > Run Behavioral Simulation**.
3. In the Tcl console, verify the output:
   ```text
   --- Starting System Simulation ---
   [40000] CPU: Wrote Threshold = 128
   [60000] CPU: Sent START command
   [65000] HARDWARE: Accelerator started with threshold 128!
   [265000] HARDWARE: Accelerator finished!
   ...
   [280000] CPU: Polled Status Register. Data = 00000000000000000000000000000001
   [280000] CPU: Hardware reported DONE. Simulation Successful!
   ```

---

## 📜 License

This project is licensed under the MIT License - feel free to use and modify for your FPGA and ASIC designs.
