module pwm_ch (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] period,
  input  logic [15:0] duty,
  output wire        pwm_out
);

    // On as long as counter < duty, off otherwise
    // Thus models our PWM channel behavior

    reg [15:0] counter;
    reg pwm_out_reg;

    assign pwm_out = pwm_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'b0;
            pwm_out <= 1'b0;
        end else begin
            if (counter < period) begin
                counter <= counter + 1;
            end else begin
                counter <= 16'b0;
            end
            
            if (counter < duty) begin
                pwm_out_reg <= 1'b1;
            end else begin
                pwm_out_reg <= 1'b0;
            end
        end
    end
endmodule