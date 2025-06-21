// Module used to control hardware from software (bridge between hw & sw)
// Software sets register values, which are inputs to the pwm core 

module pwm_regs #(
  parameter int REG_WIDTH      = 16,
  parameter int NUM_CHANNELS   = 4
)(
  input  logic                     clk,
  input  logic                     rst_n,

  // AXI-decoded write port
  input  logic                     write_en,
  input  logic [4:0]               write_addr,
  input  logic [31:0]              write_data,

  // AXI-decoded read port
  input  logic                     read_en,
  input  logic [4:0]               read_addr,
  output logic [31:0]              read_data,

  // Outputs to PWM core
  output logic [REG_WIDTH-1:0]     prescale,
  output logic [REG_WIDTH-1:0]     period   [NUM_CHANNELS-1:0],
  output logic [REG_WIDTH-1:0]     duty     [NUM_CHANNELS-1:0]
);

  // Internal registers
  logic [REG_WIDTH-1:0] reg_prescale;
  logic [REG_WIDTH-1:0] reg_period [NUM_CHANNELS-1:0];
  logic [REG_WIDTH-1:0] reg_duty   [NUM_CHANNELS-1:0];

  // Register write logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_prescale <= '0;
      for (int i = 0; i < NUM_CHANNELS; i++) begin
        reg_period[i] <= '0;
        reg_duty[i]   <= '0;
      end
    end else if (write_en) begin
      case (write_addr)
        5'h00: reg_prescale         <= write_data[REG_WIDTH-1:0];
        5'h01: reg_period[0]        <= write_data[REG_WIDTH-1:0];
        5'h02: reg_duty[0]          <= write_data[REG_WIDTH-1:0];
        5'h03: reg_period[1]        <= write_data[REG_WIDTH-1:0];
        5'h04: reg_duty[1]          <= write_data[REG_WIDTH-1:0];
        5'h05: reg_period[2]        <= write_data[REG_WIDTH-1:0];
        5'h06: reg_duty[2]          <= write_data[REG_WIDTH-1:0];
        5'h07: reg_period[3]        <= write_data[REG_WIDTH-1:0];
        5'h08: reg_duty[3]          <= write_data[REG_WIDTH-1:0];
        default: ; //do nothing
      endcase
    end
  end

  // Register read logic (for debug)
  always_comb begin
    case (read_addr)
      5'h00: read_data = {16'h0, reg_prescale};
      5'h01: read_data = {16'h0, reg_period[0]};
      5'h02: read_data = {16'h0, reg_duty[0]};
      5'h03: read_data = {16'h0, reg_period[1]};
      5'h04: read_data = {16'h0, reg_duty[1]};
      5'h05: read_data = {16'h0, reg_period[2]};
      5'h06: read_data = {16'h0, reg_duty[2]};
      5'h07: read_data = {16'h0, reg_period[3]};
      5'h08: read_data = {16'h0, reg_duty[3]};
      default: read_data = 32'h0;
    endcase
  end

  // Outputs to core
  assign prescale = reg_prescale;
  assign period   = reg_period;
  assign duty     = reg_duty;

endmodule
