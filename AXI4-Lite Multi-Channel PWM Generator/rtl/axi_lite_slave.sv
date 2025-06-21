//==============================================================================
// axi_lite_slave.sv
// Simple AXI4-Lite slave that presents a single-beat read/write interface.
// Decoded outputs: write_en, write_addr, write_data, read_en, read_addr.
// Connect this to your pwm_regs or any register file.
//==============================================================================

module axi_lite_slave #(
  parameter ADDR_WIDTH = 5,    // Width of word-aligned address (e.g. 5 → 32×4B = 128B space)
  parameter DATA_WIDTH = 32
)(
  input  logic                 ACLK,
  input  logic                 ARESETn,

  // AXI4-Lite Slave Write Address Channel
  input  logic                 AWVALID,
  output logic                 AWREADY,
  input  logic [ADDR_WIDTH-1:0] AWADDR,

  // AXI4-Lite Slave Write Data Channel
  input  logic                 WVALID,
  output logic                 WREADY,
  input  logic [DATA_WIDTH-1:0] WDATA,

  // AXI4-Lite Slave Write Response Channel
  output logic                 BVALID,
  input  logic                 BREADY,

  // AXI4-Lite Slave Read Address Channel
  input  logic                 ARVALID,
  output logic                 ARREADY,
  input  logic [ADDR_WIDTH-1:0] ARADDR,

  // AXI4-Lite Slave Read Data Channel
  output logic                 RVALID,
  input  logic                 RREADY,
  output logic [DATA_WIDTH-1:0] RDATA,

  // Decoded single-beat interface
  output logic                 write_en,    // pulses for one cycle when write occurs
  output logic [ADDR_WIDTH-1:0] write_addr,
  output logic [DATA_WIDTH-1:0] write_data,
  output logic                 read_en,     // pulses for one cycle when read occurs
  output logic [ADDR_WIDTH-1:0] read_addr,
  input  logic [DATA_WIDTH-1:0] read_data,   // fed by register file
  input  logic                 read_valid   // register file drives valid when read_data is ready
);

  //==========================================================================
  // Handshake tracking
  //==========================================================================
  // Track accepting AW + W before issuing B
  logic aw_handshake;
  logic w_handshake;

  // Write address ready when we’re not already holding one
  assign AWREADY = !aw_handshake;
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)       aw_handshake <= 1'b0;
    else if (AWVALID && AWREADY) aw_handshake <= 1'b1;
    else if (BREADY && BVALID)   aw_handshake <= 1'b0;
  end

  // Write data ready when not holding one
  assign WREADY = !w_handshake;
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)       w_handshake <= 1'b0;
    else if (WVALID && WREADY)   w_handshake <= 1'b1;
    else if (BREADY && BVALID)   w_handshake <= 1'b0;
  end

  // Issue write response when both address & data received
  assign BVALID = aw_handshake && w_handshake;

  // latch AWADDR + WDATA
  always_ff @(posedge ACLK) begin
    if (AWVALID && AWREADY) write_addr <= AWADDR;
    if (WVALID  && WREADY ) write_data <= WDATA;
  end

  // Pulse write_en when BVALID first asserted
  assign write_en = (BVALID && !BREADY);

  //==========================================================================
  // Read channel
  //==========================================================================
  // Track accepting AR before issuing R
  logic ar_handshake;

  assign ARREADY = !ar_handshake;
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)           ar_handshake <= 1'b0;
    else if (ARVALID && ARREADY) ar_handshake <= 1'b1;
    else if (RREADY && RVALID)   ar_handshake <= 1'b0;
  end

  // Latch read address
  always_ff @(posedge ACLK) begin
    if (ARVALID && ARREADY) read_addr <= ARADDR;
  end

  // RVALID when read data arrives (pipelined by user logic)
  assign RVALID  = ar_handshake && read_valid;
  assign RDATA   = read_data;

  // Pulse read_en when address accepted
  assign read_en = (ARVALID && ARREADY);

endmodule
