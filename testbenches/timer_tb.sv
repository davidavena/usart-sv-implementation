`timescale 1ns/1ps

module timer_tb();
    logic clock;
    logic reset;
    logic enable;
    logic out;
    logic out_2;
    logic out_3;

    timer #(
        .MAIN_CLOCK_FREQ(38_000_000),
        .TARGET_FREQ(950000)
    ) timer_a (
        .clock_i(clock),
        .reset_n_i(reset),
        .enable_i(enable),
        .tick_o(out)
    );

    timer #(
        .MAIN_CLOCK_FREQ(38_000_000),
        .TARGET_FREQ(475000)
    ) timer_b (
        .clock_i(clock),
        .reset_n_i(reset),
        .enable_i(enable),
        .tick_o(out_2)
    );

     timer #(
        .MAIN_CLOCK_FREQ(38_000_000),
        .TARGET_FREQ(118750)
    ) timer_c (
        .clock_i(clock),
        .reset_n_i(reset),
        .enable_i(enable),
        .tick_o(out_3)
    );

    initial begin
        clock = 0;
        reset = 0;
        enable = 0;

        #50

        reset = 1;
        enable = 1;

        #500_000
        $finish;
    end
    
    always #13.158 clock = ~clock;

endmodule