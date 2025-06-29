`timescale 1ns/1ps

module axi_pwm_tb;

  // Parameters
  localparam AXI_ADDR_WIDTH = 5;
  localparam AXI_DATA_WIDTH = 32;
  localparam NUM_CHANNELS   = 4;
  localparam REG_WIDTH      = 16;
  localparam PRESCALER_WIDTH= 16;

  // DUT signals
  logic clk;
  logic rst_n;

  // AXI4-Lite signals
  logic axi_awvalid;
  logic axi_awready;
  logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;

  logic axi_wvalid;
  logic axi_wready;
  logic [AXI_DATA_WIDTH-1:0] axi_wdata;

  logic axi_bvalid;
  logic axi_bready;

  logic axi_arvalid;
  logic axi_arready;
  logic [AXI_ADDR_WIDTH-1:0] axi_araddr;

  logic axi_rvalid;
  logic axi_rready;
  logic [AXI_DATA_WIDTH-1:0] axi_rdata;

  logic pwm_enable;
  logic [NUM_CHANNELS-1:0] pwm_out;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100MHz

  // DUT instantiation
  axi_pwm #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .NUM_CHANNELS(NUM_CHANNELS),
    .REG_WIDTH(REG_WIDTH),
    .PRESCALER_WIDTH(PRESCALER_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_awaddr(axi_awaddr),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    .axi_wdata(axi_wdata),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_araddr(axi_araddr),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    .axi_rdata(axi_rdata),
    .pwm_enable(pwm_enable),
    .pwm_out(pwm_out)
  );

  // AXI4-Lite Master Task Helpers
  task axi_write(input [AXI_ADDR_WIDTH-1:0] addr, input [AXI_DATA_WIDTH-1:0] data);
    begin
      @(posedge clk);
      axi_awvalid <= 1;
      axi_awaddr  <= addr;
      axi_wvalid  <= 1;
      axi_wdata   <= data;
      wait (axi_awready && axi_wready);
      @(posedge clk);
      axi_awvalid <= 0;
      axi_wvalid  <= 0;
      axi_bready  <= 1;
      wait (axi_bvalid);
      @(posedge clk);
      axi_bready  <= 0;
    end
  endtask

  task axi_read(input [AXI_ADDR_WIDTH-1:0] addr, output [AXI_DATA_WIDTH-1:0] data);
    begin
      @(posedge clk);
      axi_arvalid <= 1;
      axi_araddr  <= addr;
      axi_rready  <= 1;
      wait (axi_arready);
      @(posedge clk);
      axi_arvalid <= 0;
      wait (axi_rvalid);
      data = axi_rdata;
      @(posedge clk);
      axi_rready <= 0;
    end
  endtask

  // Test sequence
  initial begin
    // Initialize
    axi_awvalid = 0;
    axi_wvalid  = 0;
    axi_bready  = 0;
    axi_arvalid = 0;
    axi_rready  = 0;
    axi_awaddr  = 0;
    axi_wdata   = 0;
    axi_araddr  = 0;
    pwm_enable  = 0;
    rst_n       = 0;

    // Reset
    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // Enable PWM core
    pwm_enable = 1;

    // Write prescaler (address 0)
    axi_write(5'h00, 32'd9); // prescale = 9 (divide by 10)

    // Write period and duty for channel 0
    axi_write(5'h01, 32'd19); // period = 19 (20 ticks)
    axi_write(5'h02, 32'd10); // duty = 10 (50%)

    // Write period and duty for channel 1
    axi_write(5'h03, 32'd9);  // period = 9 (10 ticks)
    axi_write(5'h04, 32'd5);  // duty = 5 (50%)

    // Write period and duty for channel 2
    axi_write(5'h05, 32'd4);  // period = 4 (5 ticks)
    axi_write(5'h06, 32'd2);  // duty = 2 (40%)

    // Write period and duty for channel 3
    axi_write(5'h07, 32'd99); // period = 99 (100 ticks)
    axi_write(5'h08, 32'd25); // duty = 25 (25%)

    // Read back and check
    logic [31:0] rdata;
    axi_read(5'h00, rdata); // prescale
    $display("Read prescale: %0d", rdata[15:0]);
    axi_read(5'h01, rdata); // period ch0
    $display("Read period[0]: %0d", rdata[15:0]);
    axi_read(5'h02, rdata); // duty ch0
    $display("Read duty[0]: %0d", rdata[15:0]);

    // Observe PWM outputs
    repeat (200) @(posedge clk);

    // Change duty cycle on channel 0
    axi_write(5'h02, 32'd15); // duty = 15 (75%)
    repeat (100) @(posedge clk);

    // Set channel 0 to 0% and 100%
    axi_write(5'h02, 32'd0);  // duty = 0 (0%)
    repeat (50) @(posedge clk);
    axi_write(5'h02, 32'd19); // duty = 19 (100%)
    repeat (50) @(posedge clk);

    // Finish
    $display("Testbench completed.");
    $finish;
  end

endmodule