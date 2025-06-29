// Top-level wrapper for AXI PWM 
// This module connects the AXI Lite Slave -> PWM Register Interface -> PWM Core

module axi_pwm #(
    parameter PWM_WIDTH = 8,             // Width of the PWM signal
    parameter AXI_ADDR_WIDTH = 5,        // Address width for AXI interface
    parameter AXI_DATA_WIDTH = 32,       // Data width for AXI interface
    parameter NUM_CHANNELS      = 4,     // Number of PWM channels
    parameter REG_WIDTH         = 16,    // Width of i_period/i_duty registers
    parameter PRESCALER_WIDTH   = 16     // Width of i_prescaler register
)(
    input wire clk,
    input wire rst_n,
    
    // AXI Lite Slave Interface
    input wire axi_awvalid,
    output wire axi_awready,
    input wire [AXI_ADDR_WIDTH-1:0] axi_awaddr,

    input wire axi_wvalid,
    output wire axi_wready,
    input wire [AXI_DATA_WIDTH-1:0] axi_wdata,

    output wire axi_bvalid,
    input wire axi_bready,

    input wire axi_arvalid,
    output wire axi_arready,
    input wire [AXI_ADDR_WIDTH-1:0] axi_araddr,

    output wire axi_rvalid,
    input wire axi_rready,
    output wire [AXI_DATA_WIDTH-1:0] axi_rdata,

    // PWM Core enable
    input wire pwm_enable,

    // PWM Core Output
    output wire [NUM_CHANNELS-1:0] pwm_out,
);
    
    // Internal signals for AXI-lite <-> regs
    wire                  write_en;
    wire [AXI_ADDR_WIDTH-1:0] write_addr;
    wire [AXI_DATA_WIDTH-1:0] write_data;
    wire                  read_en;
    wire [AXI_ADDR_WIDTH-1:0] read_addr;
    wire [AXI_DATA_WIDTH-1:0] read_data;
    wire                  read_valid;

    // Internal signals for regs <-> core
    wire [REG_WIDTH-1:0] prescale;
    wire [REG_WIDTH-1:0] period   [NUM_CHANNELS-1:0];
    wire [REG_WIDTH-1:0] duty     [NUM_CHANNELS-1:0];

    // PWM output bus
    wire [NUM_CHANNELS-1:0] pwm_out_vec;

    // AXI4-Lite Slave
    axi_lite_slave #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) u_axi_lite_slave (
        .ACLK      (clk),
        .ARESETn   (rst_n),
        .AWVALID   (axi_awvalid),
        .AWREADY   (axi_awready),
        .AWADDR    (axi_awaddr),
        .WVALID    (axi_wvalid),
        .WREADY    (axi_wready),
        .WDATA     (axi_wdata),
        .BVALID    (axi_bvalid),
        .BREADY    (axi_bready),
        .ARVALID   (axi_arvalid),
        .ARREADY   (axi_arready),
        .ARADDR    (axi_araddr),
        .RVALID    (axi_rvalid),
        .RREADY    (axi_rready),
        .RDATA     (axi_rdata),
        .write_en  (write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_en   (read_en),
        .read_addr (read_addr),
        .read_data (read_data),
        .read_valid(read_valid)
    );

    // PWM Register File
    pwm_regs #(
        .REG_WIDTH(REG_WIDTH),
        .NUM_CHANNELS(NUM_CHANNELS)
    ) u_pwm_regs (
        .clk        (clk),
        .rst_n      (rst_n),
        .write_en   (write_en),
        .write_addr (write_addr),
        .write_data (write_data),
        .read_en    (read_en),
        .read_addr  (read_addr),
        .read_data  (read_data),
        .prescale   (prescale),
        .period     (period),
        .duty       (duty)
    );

    // PWM Core
    pwm_core #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .REG_WIDTH(REG_WIDTH),
        .PRESCALER_WIDTH(PRESCALER_WIDTH)
    ) u_pwm_core (
        .i_clk      (clk),
        .i_resetn   (rst_n),
        .i_prescale (prescale),
        .i_period   (period),
        .i_duty     (duty),
        .i_enable   (pwm_enable), // Always enabled, or add a register if needed
        .o_pwm_out  (pwm_out_vec)
    );

    assign pwm_out   = pwm_out_vec;
    
endmodule