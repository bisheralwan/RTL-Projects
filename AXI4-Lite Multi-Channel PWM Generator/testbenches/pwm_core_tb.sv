`timescale 1ns/1ps

module pwm_core_tb;

  //===========================================================================
  // Parameters (Match DUT)
  //===========================================================================
  localparam int NUM_CHANNELS     = 4;
  localparam int REG_WIDTH        = 16;
  localparam int PRESCALER_WIDTH  = 16;

  //===========================================================================
  // Signals
  //===========================================================================
  logic                              clk;
  logic                              resetn;
  logic [PRESCALER_WIDTH-1:0]        i_prescale;
  logic [REG_WIDTH-1:0][NUM_CHANNELS-1:0] i_period;
  logic [REG_WIDTH-1:0][NUM_CHANNELS-1:0] i_duty;
  logic                              i_enable;
  logic [NUM_CHANNELS-1:0]           o_pwm_out;

  //===========================================================================
  // Clock Generation (10ns period => 100MHz)
  //===========================================================================
  always #5 clk = ~clk;

  //===========================================================================
  // DUT Instantiation
  //===========================================================================
  pwm_core #(
    .NUM_CHANNELS(NUM_CHANNELS),
    .REG_WIDTH(REG_WIDTH),
    .PRESCALER_WIDTH(PRESCALER_WIDTH)
  ) dut (
    .i_clk      (clk),
    .i_resetn   (resetn),
    .i_prescale (i_prescale),
    .i_period   (i_period),
    .i_duty     (i_duty),
    .i_enable   (i_enable),
    .o_pwm_out  (o_pwm_out)
  );

  //===========================================================================
  // Monitor Task
  //===========================================================================
  task monitor_pwm;
    input int channel;
    input int cycles;

    int high_count = 0;
    int low_count = 0;
    real duty_percent;  // Explicitly declare here

    for (int i = 0; i < cycles; i++) begin
      @(posedge clk);
      if (o_pwm_out[channel])
        high_count++;
      else
        low_count++;
    end

    duty_percent = 100.0 * high_count / (high_count + low_count);
    $display("PWM Channel %0d: HIGH=%0d LOW=%0d ? Duty=%.1f%%", 
             channel, high_count, low_count, duty_percent);
  endtask


  //===========================================================================
  // Initial Block: Stimulus
  //===========================================================================
  initial begin
    $display("Starting PWM Core Testbench...");
    clk = 0;
    resetn = 0;
    i_enable = 0;
    i_prescale = 0;
    i_period = '{default:'0};
    i_duty   = '{default:'0};

    #20;
    resetn = 1;

    // Basic Enable
    i_enable = 1;

    // Setup prescaler for easy viewing (e.g., prescale=4 => tick every 5 clk cycles)
    i_prescale = 4;

    // PWM Channel Configurations
    // CH0: 50% duty, CH1: 25%, CH2: 100%, CH3: 0%
    for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
        i_period[ch] = 16'd9;
        i_duty[ch]   = (ch == 0) ? 16'd5 :
                 (ch == 1) ? 16'd2 :
                 (ch == 2) ? 16'd10 :
                             16'd0;
    end


    // Allow some time for observation
    #1000;

    // Monitor each PWM channel for one full PWM cycle (prescale + 1)*(period + 1)
    for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
      monitor_pwm(ch, 100);
    end

    $display("Test complete.");
    $finish;
  end

  //===========================================================================
  // Waveform Dump for Vivado
  //===========================================================================
  initial begin
    $dumpfile("pwm_core_tb.vcd");
    $dumpvars(0, pwm_core_tb);
  end

endmodule
