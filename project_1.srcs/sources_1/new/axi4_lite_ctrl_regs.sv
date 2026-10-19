`timescale 1ns / 1ps

module axi4_lite_ctrl_regs #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    axi4_lite_if.slave axi_if,
    
    // --- Hardware Accelerator Connections ---
    // These wires would connect to your actual AI/CNN Logic
    output logic        accel_start,     // Register 0: Start signal
    output logic [31:0] accel_threshold, // Register 1: Configuration parameter
    input  logic        accel_done       // Register 2: Status signal from hardware
);

    // Internal AXI Handshake Registers
    logic aw_ready_reg, w_ready_reg, b_valid_reg;
    logic ar_ready_reg, r_valid_reg;
    logic [DATA_WIDTH-1:0] r_data_reg;

    assign axi_if.awready = aw_ready_reg;
    assign axi_if.wready  = w_ready_reg;
    assign axi_if.bresp   = 2'b00; 
    assign axi_if.bvalid  = b_valid_reg;
    assign axi_if.arready = ar_ready_reg;
    assign axi_if.rdata   = r_data_reg;
    assign axi_if.rresp   = 2'b00; 
    assign axi_if.rvalid  = r_valid_reg;

    // The actual hardware registers
    logic [31:0] reg_control;   // Offset 0x00
    logic [31:0] reg_threshold; // Offset 0x04
    logic [31:0] reg_status;    // Offset 0x08

    // Map registers to output ports
    assign accel_start     = reg_control[0]; // Bit 0 is the start signal
    assign accel_threshold = reg_threshold;
    
    // Continuously update the status register with the hardware's 'done' signal
    always_comb begin
        reg_status = 32'h0;
        reg_status[0] = accel_done; 
    end

    wire [31:0] write_addr = axi_if.awaddr;
    wire [31:0] read_addr  = axi_if.araddr;

    // =========================================================================
    // WRITE CHANNEL LOGIC (Processor configuring the hardware)
    // =========================================================================
    always_ff @(posedge axi_if.aclk or negedge axi_if.aresetn) begin
        if (!axi_if.aresetn) begin
            aw_ready_reg  <= 0;
            w_ready_reg   <= 0;
            b_valid_reg   <= 0;
            reg_control   <= 0;
            reg_threshold <= 0;
        end else begin
            if (axi_if.awvalid && axi_if.wvalid && !aw_ready_reg && !w_ready_reg) begin
                aw_ready_reg <= 1; 
                w_ready_reg  <= 1; 
                
                // Write data to the specific register based on Address Offset
                case (write_addr)
                    32'h0000_0000: reg_control   <= axi_if.wdata;
                    32'h0000_0004: reg_threshold <= axi_if.wdata;
                    // Note: reg_status at 0x08 is Read-Only! We don't write to it.
                    default: ; // Do nothing for invalid addresses
                endcase
            end else begin
                aw_ready_reg <= 0;
                w_ready_reg  <= 0;
            end

            // Write Response logic
            if (aw_ready_reg && w_ready_reg) b_valid_reg <= 1;
            else if (axi_if.bready && b_valid_reg) b_valid_reg <= 0;
            
            // Auto-clear the start bit so it behaves like a push-button pulse
            if (reg_control[0] == 1) reg_control[0] <= 0; 
        end
    end

    // =========================================================================
    // READ CHANNEL LOGIC (Processor checking the hardware status)
    // =========================================================================
    always_ff @(posedge axi_if.aclk or negedge axi_if.aresetn) begin
        if (!axi_if.aresetn) begin
            ar_ready_reg <= 0;
            r_valid_reg  <= 0;
            r_data_reg   <= 0;
        end else begin
            if (axi_if.arvalid && !ar_ready_reg) begin
                ar_ready_reg <= 1; 
                
                // Read data from the specific register based on Address Offset
                case (read_addr)
                    32'h0000_0000: r_data_reg <= reg_control;
                    32'h0000_0004: r_data_reg <= reg_threshold;
                    32'h0000_0008: r_data_reg <= reg_status;
                    default:       r_data_reg <= 32'h1EE7C0DE; // Error code
                endcase
            end else begin
                ar_ready_reg <= 0;
            end

            // Read Response logic
            if (ar_ready_reg) r_valid_reg <= 1;
            else if (axi_if.rready && r_valid_reg) r_valid_reg <= 0;
        end
    end

endmodule
