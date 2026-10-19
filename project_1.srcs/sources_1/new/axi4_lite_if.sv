`timescale 1ns / 1ps

interface axi4_lite_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic aclk,    // Global Clock
    input logic aresetn  // Global Reset (Active Low)
);

    // 1. Write Address Channel (AW)
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    // 2. Write Data Channel (W)
    logic [DATA_WIDTH-1:0] wdata;
    logic [3:0]            wstrb;   // Write Strobe (tells which bytes are valid)
    logic                  wvalid;
    logic                  wready;

    // 3. Write Response Channel (B)
    logic [1:0]            bresp;   // Response status (00 = OKAY)
    logic                  bvalid;
    logic                  bready;

    // 4. Read Address Channel (AR)
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    // 5. Read Data Channel (R)
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;   // Response status (00 = OKAY)
    logic                  rvalid;
    logic                  rready;

    // Modport for the Master (Defines direction of signals)
    modport master (
        input  aclk, aresetn,
        output awaddr, awvalid, input  awready,
        output wdata, wstrb, wvalid, input  wready,
        input  bresp, bvalid, output bready,
        output araddr, arvalid, input  arready,
        input  rdata, rresp, rvalid, output rready
    );

    // Modport for the Slave (Defines direction of signals)
    modport slave (
        input  aclk, aresetn,
        input  awaddr, awvalid, output awready,
        input  wdata, wstrb, wvalid, output wready,
        output bresp, bvalid, input  bready,
        input  araddr, arvalid, output arready,
        output rdata, rresp, rvalid, input  rready
    );

endinterface