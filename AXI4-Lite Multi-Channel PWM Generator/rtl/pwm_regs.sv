// Module used to control hardware from software (bridge between hw & sw)
// Software sets register values, which are inputs to the pwm core 

module pwm_regs #(
  parameter  int REG_WIDTH      = 16,
  parameter  int NUM_CHANNELS   = 4
  localparam int DEPTH          = 1 + 2*NUM_CHANNELS // 1 for prescale, 2 for each channel (period and duty)
  localparam int ADDR_WIDTH     = $clog2(DEPTH) // Address width for the register file
)(
  input  logic                     clk,
  input  logic                     rst_n,

  // AXI-decoded write port
  input  logic                     write_en,
  input  logic [ADDR_WIDTH-1:0]    write_addr,
  input  logic [REG_WIDTH-1:0]              write_data,

  // AXI-decoded read port
  input  logic                     read_en,
  input  logic [ADDR_WIDTH-1:0]    read_addr,
  output logic [REG_WIDTH-1:0]              read_data,
  output logic                     read_valid,

  // Outputs to PWM core
  output logic [REG_WIDTH-1:0]     prescale,
  output logic [REG_WIDTH-1:0]     period   [NUM_CHANNELS-1:0],
  output logic [REG_WIDTH-1:0]     duty     [NUM_CHANNELS-1:0]
);

  // Forcing BRAM inference
  (*ram_style = "block"*)
  logic [REG_WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Clear the memory on reset
      for (int i = 0; i< DEPTH; i++) begin
        mem[i] <= '0;
      end
    end else if (write_en && (write_addr < DEPTH)) begin 
      mem[write_addr] <= write_data[REG_WIDTH-1:0];
    end 
  end

  always_comb begin
    if (read_en && (read_addr < DEPTH)) begin
      read_data = mem[read_addr];
      read_valid = 1'b1;
    end else begin
      read_data = 0; // Default value when not reading
      read_valid = 1'b0;
    end
  end

  assign prescale = mem[0]; // Prescale register at address 0
  for (int i = 0; i < NUM_CHANNELS; i++) begin
    period[i] = mem[1 + 2*i]; // Period register for channel i at address 1 + 2*i
    duty[i]   = mem[2 + 2*i]; // Duty register for channel i at address 2 + 2*i
  end

endmodule
