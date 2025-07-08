//==============================================================================
// PWM Core Module
// Description: Generates multiple independent PWM channels with shared prescaler
// Features: Parameterizable channels, configurable bit widths, edge-aligned PWM
//==============================================================================
// PWM TIMING AND CALCULATION FORMULAS
//==============================================================================
//
// 1. DUTY CYCLE CALCULATION:
//    Duty Cycle (%) = (duty_register / period_register) × 100%
//    
//    Examples:
//    - duty = 500, period = 1000  → 50% duty cycle
//    - duty = 250, period = 1000  → 25% duty cycle
//    - duty = 750, period = 1000  → 75% duty cycle
//
//    Special Cases:
//    - duty = 0           → 0% duty cycle
//    - duty >= period     → 100% duty cycle
//    - period = 0         → 100% duty cycle (handled in code)
//
// 2. PWM PERIOD CALCULATION:
//    Actual PWM Period = (prescale + 1) × (period + 1) × Clock_Period
//    PWM Frequency = Clock_Frequency / [(prescale + 1) × (period + 1)]
//
//    Breakdown:
//    - prescale = 0  → tick every 1 clock cycle (no division)
//    - prescale = N  → tick every (N+1) clock cycles
//    - period = 0    → PWM cycle completes in 1 tick
//    - period = N    → PWM cycle completes in (N+1) ticks
//
// 3. TIMING EXAMPLES:
//    Example 1: 100MHz Clock, 1kHz PWM
//    - Clock = 100MHz (10ns period)
//    - prescale = 99     → Divide by 100 → 1μs tick period
//    - period = 999      → 1000 ticks → 1ms PWM period → 1kHz
//    - duty = 499        → 500 ticks → 50% duty cycle
//
//    Example 2: 50MHz Clock, 500Hz PWM
//    - Clock = 50MHz (20ns period)  
//    - prescale = 49     → Divide by 50 → 1μs tick period
//    - period = 1999     → 2000 ticks → 2ms PWM period → 500Hz
//    - duty = 599        → 600 ticks → 30% duty cycle
//
// 4. PWM TIMING LOGIC:
//    PWM output is HIGH when: counter < duty_register
//    
//    Timing diagram (period=8, duty=3):
//    Counter:  0  1  2  3  4  5  6  7  0  1  2  3  4  5  6  7
//    PWM Out:  1  1  1  0  0  0  0  0  1  1  1  0  0  0  0  0
//              ^^^^^^^                 ^^^^^^^
//              High for 3 counts       High for 3 counts (37.5%)
//
// 5. RESOLUTION CALCULATION:
//    Duty cycle resolution = 1 / (period + 1) × 100%
//    
//    Examples:
//    - period = 999   → resolution = 0.1%
//    - period = 65535 → resolution ≈ 0.0015% (16-bit max)
//
//==============================================================================

module pwm_core #(
  parameter int NUM_CHANNELS      = 4,     // Number of PWM channels
  parameter int REG_WIDTH         = 16     // Width of i_period/i_duty registers
)(
  input  logic                                        i_clk,            // System clock
  input  logic                                        i_resetn,         // Active-low reset
  input  logic [REG_WIDTH-1:0]                        i_prescale,       // Clock division factor (0 = no division)
  input  logic [REG_WIDTH-1:0][NUM_CHANNELS-1:0]      i_period,         // i_period values (packed array)
  input  logic [REG_WIDTH-1:0][NUM_CHANNELS-1:0]      i_duty,           // i_duty cycle values (packed array)
  input  logic [NUM_CHANNELS:0]                       i_pwm_enable_reg, 
  output logic [NUM_CHANNELS-1:0]                     o_pwm_out         // PWM channel outputs
);

  //============================================================================
  // Enable Signals
  //============================================================================
  logic [NUM_CHANNELS-1:0] channel_enable; // Enable for each channel
  logic enable; // Global enable signal
  always_comb begin
    // Extract enable bits for each channel from i_pwm_enable_reg
    for (int i = 0; i < NUM_CHANNELS; i++) begin
      channel_enable[i] = i_pwm_enable_reg[i+1]; // i_pwm_enable_reg[0] is global enable
    end
    enable = i_pwm_enable_reg[0]; // Global enable is the first bit
  end

  //============================================================================
  // Internal Signals
  //============================================================================
  logic                           tick;           // i_prescaler tick pulse
  logic [REG_WIDTH-1:0]   prescale_cnt;     // i_prescaler counter

  //============================================================================
  // i_prescaler: Generate tick pulse every (i_prescale+1) clock cycles
  // When i_prescale = 0, tick is always high (no division)
  //============================================================================
  always_ff @(posedge i_clk or negedge i_resetn) begin
    if (!i_resetn || !enable) begin
      prescale_cnt <= '0;
      tick         <= 1'b0;
    end else begin
      if (i_prescale == '0 || prescale_cnt >= i_prescale) begin
        prescale_cnt <= '0;
        tick         <= 1'b1;
      end else begin
        prescale_cnt <= prescale_cnt + 1'b1;
        tick         <= 1'b0;
      end
    end
  end

  //============================================================================
  // PWM Channel Generation
  //============================================================================
  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i++) begin : gen_pwm_channel
      
      logic [REG_WIDTH-1:0] counter = '0; 
      logic                 pwm_reg = '0; 
      
      always_ff @(posedge i_clk or negedge i_resetn) begin
        if (!i_resetn || !enable) begin
          counter  <= '0;
          pwm_reg  <= 1'b0;
        end else if (tick) begin
          // Handle counter wraparound
          if (counter >= i_period[i] || i_period[i] == '0) begin
            counter <= '0;
          end else begin
            counter <= counter + 1'b1;
          end
          
          // Generate PWM output
          // PWM is high when counter < i_duty_cycle, handles i_duty = 0 and i_duty >= i_period
          if (i_duty[i] == '0) begin
            pwm_reg <= 1'b0;  // 0% i_duty cycle
          end else if (i_duty[i] >= i_period[i]) begin
            pwm_reg <= 1'b1;  // 100% i_duty cycle
          end else begin
            pwm_reg <= (counter < i_duty[i]) ? 1'b1 : 1'b0;
          end
        end
      end
      
      // Output assignment
      assign o_pwm_out[i] = channel_enable[i] ? pwm_reg : 1'b0;

    end : gen_pwm_channel
  endgenerate
endmodule
