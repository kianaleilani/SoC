`timescale 1ns/1ps

module tb_reaction_timer;

    // DUT ports
    logic clk;
    logic reset;
    logic BTNC, BTNU;
    logic [7:0] AN;
    logic [6:0] seg;
    logic [15:0] LED;

    // Instantiate DUT
    top_reaction_timer dut (
        .clk   (clk),
        .reset (reset),
        .BTNC  (BTNC),
        .BTNU  (BTNU),
        .AN    (AN),
        .seg   (seg),
        .LED   (LED)
    );

    // Clock generator (100 MHz -> 10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Simulation shortened LFSR scaling
    localparam SIM_DELAY_SCALE = 10_000; // ~100us per step for sim

    // Stimulus
    initial begin
        $display("=== Reaction Timer Testbench Start ===");
        reset = 1; BTNC = 0; BTNU = 0;
        #100; 
        reset = 0;

        // Check welcome screen "ALOHA"
        #100_000;
        $display("[TB] DUT should display ALOHA");

        // Start reaction timer by pressing BTNC
        $display("[TB] Pressing BTNC to start reaction trial");
        BTNC = 1; #50; BTNC = 0;

        // Wait for LEDs to turn on after random delay
        wait (LED != 16'h0000);
        $display("[TB] LEDs turned ON -> Now waiting to press BTNC");

        // Simulate reaction after ~200us
        #200_000;
        BTNC = 1; #50; BTNC = 0;
        $display("[TB] BTNC pressed after LEDs ON -> Reaction time should display");

        // Hold for observation
        #500_000;

        // Case: Early press before LEDs turn on
        $display("[TB] Testing EARLY press -> should display 9999");
        BTNC = 1; #50; BTNC = 0;  // pressed early
        #100_000;

        // Reset with BTNU
        $display("[TB] Pressing BTNU for reset");
        BTNU = 1; #50; BTNU = 0;
        #100_000;

        $display("=== Reaction Timer Testbench Done ===");
        $finish;
    end

endmodule

