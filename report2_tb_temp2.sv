`timescale 1ns/1ps

module tb_reaction_led_fsm;

    // Testbench signals
    logic clk;
    logic reset;
    logic BTNC, BTNU, BTNL, BTNR, BTND;
    logic [15:0] LED;
    logic [6:0] seg;
    logic [3:0] an;

    // Instantiate DUT
    reaction_led_fsm dut (
        .clk(clk),
        .reset(reset),
        .BTNC(BTNC),
        .BTNU(BTNU),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .LED(LED),
        .seg(seg),
        .an(an)
    );

    // Generate 100 MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Init
        reset = 1;
        BTNC = 0; BTNU = 0; BTNL = 0; BTNR = 0; BTND = 0;
        #50;
        reset = 0;
        $display("[%0t] Reset deasserted", $time);

        // Press Start
        #100;
        $display("[%0t] Pressing START (BTNC)", $time);
        BTNC = 1; #20; BTNC = 0;

        // Wait for LED turn on
        #500000;
        $display("[%0t] LEDs = %h", $time, LED);

        // Press Stop
        $display("[%0t] Pressing STOP (BTNC)", $time);
        BTNC = 1; #20; BTNC = 0;

        #100000;
        $display("[%0t] FSM STOPPED, LEDs = %h", $time, LED);

        // Press Clear
        $display("[%0t] Pressing CLEAR (BTNU)", $time);
        BTNU = 1; #20; BTNU = 0;

        #200000;
        $display("[%0t] FSM back to IDLE, LEDs = %h", $time, LED);

        $stop;
    end

endmodule
