// Testbench
`timescale 1ns/1ps

module tb_seven_seg_display;

    // Testbench signals
    logic clk;
    logic reset;
    logic en;
    logic cw;
    logic [6:0] seg;
    logic [6:0] an;

    // Instantiate DUT (Device Under Test)
    rotate_pattern dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .cw(cw),
        .seg(seg),
        .an(an)
    );

    // Clock generation: 10ns period = 100 MHz
    //initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        reset = 1;
        clk = 0;
        en = 0;
        //cw = 0;
        // Reset sequence
        //reset = 1;
        #20;
        reset = 0;
        en = 1;
        cw = 1;
        
        #200
        reset = 1; 
        
        #20
        reset = 0;
        cw = 0;

        // Run simulation for some time
        #200;

        $finish;
    end
