`timescale 1ns / 1ps

module axi4_lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    axi4_lite_if.master axi_if, // The AXI Interface (Master side)
    
    // Simple User Control Signals (How you tell the Master what to do)
    input  logic                  start_write,
    input  logic [ADDR_WIDTH-1:0] user_wr_addr,
    input  logic [DATA_WIDTH-1:0] user_wr_data,
    output logic                  write_done,

    input  logic                  start_read,
    input  logic [ADDR_WIDTH-1:0] user_rd_addr,
    output logic [DATA_WIDTH-1:0] user_rd_data,
    output logic                  read_done
);

    // FSM States
    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA
    } state_t;
    
    state_t state, next_state;

    // Default assignments to prevent latches
    always_comb begin
        axi_if.awvalid = 0;
        axi_if.wvalid  = 0;
        axi_if.bready  = 0;
        axi_if.arvalid = 0;
        axi_if.rready  = 0;
        write_done     = 0;
        read_done      = 0;
        next_state     = state;

        case (state)
            IDLE: begin
                if (start_write)      next_state = WRITE_ADDR_DATA;
                else if (start_read)  next_state = READ_ADDR;
            end

            // --- WRITE SEQUENCE ---
            WRITE_ADDR_DATA: begin
                axi_if.awvalid = 1; // I have a valid address
                axi_if.wvalid  = 1; // I have valid data
                
                // Wait for the Slave to say it is ready for BOTH
                if (axi_if.awready && axi_if.wready) begin
                    next_state = WRITE_RESP;
                end
            end

            WRITE_RESP: begin
                axi_if.bready = 1; // I am ready to receive your success response
                if (axi_if.bvalid) begin // Slave says "Write successful!"
                    write_done = 1;
                    next_state = IDLE;
                end
            end

            // --- READ SEQUENCE ---
            READ_ADDR: begin
                axi_if.arvalid = 1; // I have a valid read address
                if (axi_if.arready) begin // Slave accepted the address
                    next_state = READ_DATA;
                end
            end

            READ_DATA: begin
                axi_if.rready = 1; // I am ready to receive the data
                if (axi_if.rvalid) begin // Slave is sending the data
                    read_done = 1;
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Sequential logic for state transitions and data capture
    always_ff @(posedge axi_if.aclk or negedge axi_if.aresetn) begin
        if (!axi_if.aresetn) begin
            state <= IDLE;
            axi_if.awaddr <= 0;
            axi_if.wdata  <= 0;
            axi_if.wstrb  <= 4'b1111; // Write to all 4 bytes
            axi_if.araddr <= 0;
            user_rd_data  <= 0;
        end else begin
            state <= next_state;
            
            // Capture user inputs when leaving IDLE
            if (state == IDLE) begin
                if (start_write) begin
                    axi_if.awaddr <= user_wr_addr;
                    axi_if.wdata  <= user_wr_data;
                end else if (start_read) begin
                    axi_if.araddr <= user_rd_addr;
                end
            end

            // Capture data from Slave during a Read
            if (state == READ_DATA && axi_if.rvalid && axi_if.rready) begin
                user_rd_data <= axi_if.rdata;
            end
        end
    end

endmodule