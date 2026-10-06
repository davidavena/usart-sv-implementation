module timer #(
    parameter integer MAIN_CLOCK_FREQ = 2_080_000,
    parameter integer TARGET_FREQ = 9600
) (
    input logic clock_i,
    input logic reset_n_i,
    input logic enable_i,
    output logic tick_o
);

localparam integer CLOCKS_PER_TICK = (MAIN_CLOCK_FREQ / TARGET_FREQ) - 1;
localparam integer COUNTER_WIDTH = (CLOCKS_PER_TICK <= 1) ? 1 : $clog2(CLOCKS_PER_TICK + 1);

logic [COUNTER_WIDTH - 1 : 0] counter;

always_ff @(posedge clock_i) begin
    if (!reset_n_i || !enable_i) begin
        initialize();
    end else begin
        if (enable_i) begin
            if (counter == CLOCKS_PER_TICK) begin
                counter <= '0;
                tick_o <= 1'd1;
            end else begin
                tick_o <= '0;
                counter <= counter + 1;
            end
        end
    end
end

function void initialize();
    tick_o <= '0;
    counter <= '0;
endfunction

endmodule