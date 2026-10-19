`timescale 1ns / 1ps

module tb_axi4_lite_accel;

    // Global Signals
    logic clk;
    logic resetn;

    // Master Control Signals (You acting as the CPU)
    logic        start_write, start_read;
    logic [31:0] user_wr_addr, user_wr_data, user_rd_addr, user_rd_data;
    logic        write_done, read_done;

    // Dummy Accelerator Signals
    logic        accel_start;
    logic [31:0] accel_threshold;
    logic        accel_done;

    // 1. The Interface
    axi4_lite_if axi_bus (.aclk(clk), .aresetn(resetn));

    // 2. The Master (The CPU)
    axi4_lite_master master_inst (
        .axi_if(axi_bus.master), 
        .start_write(start_write), .user_wr_addr(user_wr_addr), .user_wr_data(user_wr_data), .write_done(write_done),
        .start_read(start_read), .user_rd_addr(user_rd_addr), .user_rd_data(user_rd_data), .read_done(read_done)
    );

    // 3. The Slave (The Control Registers)
    axi4_lite_ctrl_regs ctrl_regs_inst (
        .axi_if(axi_bus.slave),
        .accel_start(accel_start),
        .accel_threshold(accel_threshold),
        .accel_done(accel_done)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // --- FIXED: Dummy Hardware Accelerator Logic ---
    // Using an initial block allows us to legally use delays in a testbench
    initial begin
        accel_done = 0;
        forever begin
            @(posedge clk);
            if (accel_start) begin
                $display("[%0t] HARDWARE: Accelerator started with threshold %0d!", $time, accel_threshold);
                // Simulate 20 clock cycles of computation delay
                repeat(20) @(posedge clk); 
                accel_done = 1; // Signal that computation is finished
                $display("[%0t] HARDWARE: Accelerator finished!", $time);
                
                // Hold the done signal for 1 clock cycle, then clear it
                //@(posedge clk);
                //accel_done = 0; 
            end
        end
    end

    // --- Main CPU Simulation Sequence ---
    initial begin
        // Initialize
        clk = 0; resetn = 0;
        start_write = 0; start_read = 0;
        user_wr_addr = 0; user_wr_data = 0; user_rd_addr = 0;

        #20 resetn = 1; #20;
        $display("--- Starting System Simulation ---");

        // STEP 1: CPU writes to Threshold Register (Offset 0x04)
        @(posedge clk); #1;
        user_wr_addr = 32'h0000_0004; 
        user_wr_data = 32'd128; // Set threshold to 128
        start_write  = 1;
        
        @(posedge clk); #1; 
        start_write = 0;
        
        wait(write_done);
        @(posedge clk); // Finalize state
        $display("[%0t] CPU: Wrote Threshold = 128", $time);
        #20;

        // STEP 2: CPU writes to Control Register to START (Offset 0x00)
        @(posedge clk); #1;
        user_wr_addr = 32'h0000_0000; 
        user_wr_data = 32'h0000_0001; // Bit 0 is the start bit
        start_write  = 1;
        
        @(posedge clk); #1; 
        start_write = 0;
        
        wait(write_done);
        @(posedge clk); // Finalize state
        $display("[%0t] CPU: Sent START command", $time);

        // STEP 3: CPU polls the Status Register (Offset 0x08) until DONE
        user_rd_addr = 32'h0000_0008; 
        user_rd_data = 32'h0;
        
        while (user_rd_data[0] == 0) begin
            #10; // Wait a bit between reads
            @(posedge clk); #1;
            start_read = 1;
            
            @(posedge clk); #1; 
            start_read = 0;
            
            wait(read_done);
            @(posedge clk); #1; // FIXED: Wait for data to latch!
            $display("[%0t] CPU: Polled Status Register. Data = %b", $time, user_rd_data);
        end

        $display("[%0t] CPU: Hardware reported DONE. Simulation Successful!", $time);
        
        #50;
        $finish;
    end

endmodule