`timescale 1ns / 1ps

module axi4_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256 // 256 words * 4 bytes = 1KB memory
)(
    // Pass the interface we created earlier. The .slave selects the modport!
    axi4_lite_if.slave axi_if 
);

    // Core Memory Array (The actual data storage)
    logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // Internal registers for handshaking
    logic aw_ready_reg, w_ready_reg, b_valid_reg;
    logic ar_ready_reg, r_valid_reg;
    logic [DATA_WIDTH-1:0] r_data_reg;

    // Connect internal registers to the interface outputs
    assign axi_if.awready = aw_ready_reg;
    assign axi_if.wready  = w_ready_reg;
    assign axi_if.bresp   = 2'b00; // 00 means "OKAY" (Transaction successful)
    assign axi_if.bvalid  = b_valid_reg;

    assign axi_if.arready = ar_ready_reg;
    assign axi_if.rdata   = r_data_reg;
    assign axi_if.rresp   = 2'b00; // OKAY response
    assign axi_if.rvalid  = r_valid_reg;

    // Word-aligned address index (divide by 4 since each address is a byte, but memory is 32-bit words)
    wire [31:0] write_index = axi_if.awaddr >> 2;
    wire [31:0] read_index  = axi_if.araddr >> 2;

    // =========================================================================
    // WRITE CHANNEL LOGIC
    // =========================================================================
    always_ff @(posedge axi_if.aclk or negedge axi_if.aresetn) begin
        if (!axi_if.aresetn) begin
            aw_ready_reg <= 0;
            w_ready_reg  <= 0;
            b_valid_reg  <= 0;
        end else begin
            // 1. Wait for valid address and data from Master
            if (axi_if.awvalid && axi_if.wvalid && !aw_ready_reg && !w_ready_reg) begin
                aw_ready_reg <= 1; // Say "I am ready for the address"
                w_ready_reg  <= 1; // Say "I am ready for the data"
                
                // Perform the actual memory write
                if (write_index < MEM_DEPTH) begin
                    memory[write_index] <= axi_if.wdata;
                end
            end else begin
                // Drop ready signals after 1 clock cycle
                aw_ready_reg <= 0;
                w_ready_reg  <= 0;
            end

            // 2. Send Write Response (B-Channel)
            // If we just accepted a write, assert BVALID. 
            if (aw_ready_reg && w_ready_reg) begin
                b_valid_reg <= 1;
            end else if (axi_if.bready && b_valid_reg) begin
                // If master accepted our response, clear BVALID
                b_valid_reg <= 0;
            end
        end
    end

    // =========================================================================
    // READ CHANNEL LOGIC
    // =========================================================================
    always_ff @(posedge axi_if.aclk or negedge axi_if.aresetn) begin
        if (!axi_if.aresetn) begin
            ar_ready_reg <= 0;
            r_valid_reg  <= 0;
            r_data_reg   <= 0;
        end else begin
            // 1. Wait for valid read address from Master
            if (axi_if.arvalid && !ar_ready_reg) begin
                ar_ready_reg <= 1; // Accept the address
                
                // Fetch data from memory
                if (read_index < MEM_DEPTH) begin
                    r_data_reg <= memory[read_index];
                end else begin
                    r_data_reg <= 32'hDEADBEEF; // Error/Dummy data for out of bounds
                end
            end else begin
                ar_ready_reg <= 0;
            end

            // 2. Send Read Data back (R-Channel)
            if (ar_ready_reg) begin
                r_valid_reg <= 1; // Tell master data is valid
            end else if (axi_if.rready && r_valid_reg) begin
                // If master captured the data, clear RVALID
                r_valid_reg <= 0;
            end
        end
    end

endmodule