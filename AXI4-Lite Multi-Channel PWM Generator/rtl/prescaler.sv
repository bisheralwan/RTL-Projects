module prescaler (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [15:0] div_value,
  output logic        tick
);

    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick <= 1'b0;
            counter <= 16'b0; // Reset counter on reset
        end else begin
            // If div_value is zero, we do not generate any ticks
            if (div_value == 16'b0) begin
                tick <= 1'b0;
            end else begin
                // Use a counter to generate the tick
                counter <= counter + 1;
                if (counter >= div_value) begin
                    tick <= 1'b1;
                    counter <= 16'b0; // Reset counter after generating a tick
                end else begin
                    tick <= 1'b0; // No tick until the counter reaches div_value
                end
            end
        end
    end
endmodule