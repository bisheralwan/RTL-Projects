`timescale 1ns/1ps

module pwm_regs_tb;

  localparam REG_WIDTH = 16;
  localparam NUM_CHANNELS = 4;

  logic clk, rst_n;
  logic write_en;
  logic [4:0] write_addr;
  logic [31:0] write_data;
  logic read_en;
  logic [4:0] read_addr;
  logic [31:0] read_data;
  logic [REG_WIDTH-1:0] prescale;
  logic [REG_WIDTH-1:0] period [NUM_CHANNELS-1:0];
  logic [REG_WIDTH-1:0] duty   [NUM_CHANNELS-1:0];

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  pwm_regs #(
    .REG_WIDTH(REG_WIDTH),
    .NUM_CHANNELS(NUM_CHANNELS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .write_en(write_en),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_en(read_en),
    .read_addr(read_addr),
    .read_data(read_data),
    .prescale(prescale),
    .period(period),
    .duty(duty)
  );

  initial begin
    write_en = 0; write_addr = 0; write_data = 0;
    read_en = 0; read_addr = 0;
    rst_n = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // Write prescale
    write_addr = 5'h00; write_data = 32'd123; write_en = 1;
    @(posedge clk); write_en = 0;

    // Write period/duty for channel 0
    write_addr = 5'h01; write_data = 32'd1000; write_en = 1;
    @(posedge clk); write_en = 0;
    write_addr = 5'h02; write_data = 32'd500; write_en = 1;
    @(posedge clk); write_en = 0;

    // Write period/duty for channel 1
    write_addr = 5'h03; write_data = 32'd2000; write_en = 1;
    @(posedge clk); write_en = 0;
    write_addr = 5'h04; write_data = 32'd1000; write_en = 1;
    @(posedge clk); write_en = 0;

    // Read back prescale
    read_addr = 5'h00; read_en = 1;
    @(posedge clk);
    $display("Prescale: %0d (expected 123)", read_data[15:0]);
    read_en = 0;

    // Read back period/duty for channel 0
    read_addr = 5'h01; read_en = 1; @(posedge clk);
    $display("Period[0]: %0d (expected 1000)", read_data[15:0]);
    read_addr = 5'h02; @(posedge clk);
    $display("Duty[0]: %0d (expected 500)", read_data[15:0]);
    read_en = 0;

    // Read back period/duty for channel 1
    read_addr = 5'h03; read_en = 1; @(posedge clk);
    $display("Period[1]: %0d (expected 2000)", read_data[15:0]);
    read_addr = 5'h04; @(posedge clk);
    $display("Duty[1]: %0d (expected 1000)", read_data[15:0]);
    read_en = 0;

    // Check outputs
    $display("prescale=%0d period[0]=%0d duty[0]=%0d", prescale, period[0], duty[0]);
    $display("period[1]=%0d duty[1]=%0d", period[1], duty[1]);

    $display("pwm_regs_tb completed.");
    $finish;
  end

endmodule