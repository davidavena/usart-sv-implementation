module timer #(
    parameter integer MAIN_CLOCK_FREQ = 2_080_000,
    parameter integer TARGET_FREQ = 9600
) (
    input logic     clock_i,
    input logic     reset_n_i,
    input logic     enable_i,
    
    input integer   target_freq_override_i,
    input logic     override_i,

    output logic    tick_o,
    output logic    previous_state_o
);

localparam integer  CLOCKS_PER_TICK = (MAIN_CLOCK_FREQ / TARGET_FREQ) - 1;
localparam integer  COUNTER_WIDTH = (CLOCKS_PER_TICK <= 1) ? 1 : $clog2(CLOCKS_PER_TICK + 1);

logic [COUNTER_WIDTH : 0] counter;

always_ff @(posedge clock_i) begin
    if (!reset_n_i || !enable_i) begin
        initialize();
    end else begin
        if (enable_i) begin
            if (override_i) begin
                counter_logic(target_freq_override_i);
            end else begin
                counter_logic(CLOCKS_PER_TICK);
            end
        end
    end
end

function void initialize();
    override_i <= '0;
    tick_o <= '0;
    counter <= '0;
    target_freq_override_i <= CLOCKS_PER_TICK;
endfunction

function void counter_logic(input integer clock_cycle_count);
    if (counter == clock_cycle_count) begin
        counter <= '0;
        tick_o <= 1'd1;
    end else begin
        previous_state_o <= tick_o;
        tick_o <= '0;
        counter <= counter + 1;
    end
endfunction

endmodule