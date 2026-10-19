`timescale 1ns / 1ps

module tb_axi4_lite;

    // Clock and Reset Signals
    logic clk;
    logic resetn;

    // User Control Signals to the Master
    logic        start_write;
    logic [31:0] user_wr_addr;
    logic [31:0] user_wr_data;
    logic        write_done;

    logic        start_read;
    logic [31:0] user_rd_addr;
    logic [31:0] user_rd_data;
    logic        read_done;

    // 1. Instantiate the Interface
    axi4_lite_if axi_bus (.aclk(clk), .aresetn(resetn));

    // 2. Instantiate the Master
    axi4_lite_master master_inst (
        .axi_if      (axi_bus.master),
        .start_write (start_write),
        .user_wr_addr(user_wr_addr),
        .user_wr_data(user_wr_data),
        .write_done  (write_done),
        .start_read  (start_read),
        .user_rd_addr(user_rd_addr),
        .user_rd_data(user_rd_data),
        .read_done   (read_done)
    );

    // 3. Instantiate the Slave (1KB Memory)
    axi4_lite_slave slave_inst (
        .axi_if      (axi_bus.slave)
    );

    // Generate a 100MHz Clock
    always #5 clk = ~clk;

    // The Simulation Sequence
    initial begin
        // Initialize everything
        clk = 0;
        resetn = 0;
        start_write = 0;
        start_read = 0;
        user_wr_addr = 0;
        user_wr_data = 0;
        user_rd_addr = 0;

        // Apply Reset
        #20 resetn = 1; 
        #20;

        $display("--- Starting AXI4-Lite Simulation ---");

        // --- TEST 1: Write Data to Memory ---
        @(posedge clk); #1; // The #1 prevents testbench race conditions!
        user_wr_addr = 32'h0000_0004; 
        user_wr_data = 32'h1EE7C0DE;  
        start_write  = 1;
        
        @(posedge clk); #1;
        start_write  = 0; 

        // Wait for the Master to finish writing
        wait(write_done);
        @(posedge clk); // Wait for the clock edge to finalize state
        $display("Write Complete! Data 0x%h written to Address 0x%h", user_wr_data, user_wr_addr);
        #20;

        // --- TEST 2: Read Data Back from Memory ---
        @(posedge clk); #1;
        user_rd_addr = 32'h0000_0004; 
        start_read   = 1;
        
        @(posedge clk); #1;
        start_read   = 0;

        // Wait for the Master to finish reading
        wait(read_done);
        
        // *** THE CRUCIAL FIX ***
        // Wait for the next clock edge so the Master has time to latch rdata into user_rd_data
        @(posedge clk); #1; 
        
        $display("Read Complete! Data 0x%h read from Address 0x%h", user_rd_data, user_rd_addr);

        // Verification Check
        if (user_rd_data == 32'h1EE7C0DE) begin
            $display("SUCCESS: Read data matches Write data!");
        end else begin
            $display("ERROR: Data mismatch!");
        end

        #50;
        $finish; 
    end

endmodule