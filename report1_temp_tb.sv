// Testbench
`timescale 1ns/1ps

module tb_seg;

    // Testbench signals
    logic clk;
    logic reset;
    logic en;
    logic cw;
    logic [6:0] seg;
    logic [3:0] an;

    // Instantiate DUT
    rotate_seg dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .cw(cw),
        .seg(seg),
        .an(an)
    );

    // Clock generator: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
      $display("Initialization");
        clk   = 0;
        reset = 1;
        en    = 1;
        cw    = 1;   // start clockwise
        #10;         // hold reset for a little bit

        reset = 0;
        //en    = 1;   // enable circulation

        // Let it run for a while
        #5;

        // Change direction to counter-clockwise
        $display("CCW");
        cw = 0;
        #5;

        // Pause circulation
      $display("Pause");
        en = 0;
        #10;

        // Resume circulation
      $display("Resume");
        en = 1;
        #5;
      $display("Finish");

        $finish;  // end simulation
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | en=%b cw=%b | seg=%b an=%b",
                  $time, en, cw, seg, an);
    end

endmodule
