`timescale 1ns/1ps

module axi_lite_slave_tb;

  localparam ADDR_WIDTH = 5;
  localparam DATA_WIDTH = 32;

  logic ACLK, ARESETn;
  logic AWVALID, AWREADY;
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic WVALID, WREADY;
  logic [DATA_WIDTH-1:0] WDATA;
  logic BVALID, BREADY;
  logic ARVALID, ARREADY;
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic RVALID, RREADY;
  logic [DATA_WIDTH-1:0] RDATA;

  // Decoded interface
  logic write_en;
  logic [ADDR_WIDTH-1:0] write_addr;
  logic [DATA_WIDTH-1:0] write_data;
  logic read_en;
  logic [ADDR_WIDTH-1:0] read_addr;
  logic [DATA_WIDTH-1:0] read_data;
  logic read_valid;

  // Simple register file for read_data
  logic [DATA_WIDTH-1:0] regfile [0:31];

  // Clock
  initial ACLK = 0;
  always #5 ACLK = ~ACLK;

  // DUT
  axi_lite_slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .AWADDR(AWADDR),
    .WVALID(WVALID),
    .WREADY(WREADY),
    .WDATA(WDATA),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .ARADDR(ARADDR),
    .RVALID(RVALID),
    .RREADY(RREADY),
    .RDATA(RDATA),
    .write_en(write_en),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_en(read_en),
    .read_addr(read_addr),
    .read_data(read_data),
    .read_valid(read_valid)
  );

  // Register file model for read path
  assign read_data = regfile[read_addr];
  assign read_valid = read_en;

  // Write path: update regfile on write_en
  always_ff @(posedge ACLK) begin
    if (write_en)
      regfile[write_addr] <= write_data;
  end

  // Test sequence
  initial begin
    // Init
    AWVALID = 0; WVALID = 0; BREADY = 0; ARVALID = 0; RREADY = 0;
    AWADDR = 0; WDATA = 0; ARADDR = 0;
    ARESETn = 0;
    repeat (3) @(posedge ACLK);
    ARESETn = 1;
    repeat (2) @(posedge ACLK);

    // Write transaction
    AWADDR = 5'h05; WDATA = 32'hDEADBEEF;
    AWVALID = 1; WVALID = 1;
    @(posedge ACLK);
    wait (AWREADY && WREADY);
    AWVALID = 0; WVALID = 0;
    BREADY = 1;
    wait (BVALID);
    @(posedge ACLK);
    BREADY = 0;

    // Read transaction
    ARADDR = 5'h05;
    ARVALID = 1; RREADY = 1;
    @(posedge ACLK);
    wait (ARREADY);
    ARVALID = 0;
    wait (RVALID);
    $display("Read data: %h (expected DEADBEEF)", RDATA);
    @(posedge ACLK);
    RREADY = 0;

    // Done
    $display("axi_lite_slave_tb completed.");
    $finish;
  end

endmodule