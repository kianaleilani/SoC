`timescale 1ns/1ps

`timescale 1ns/1ps

module tb_reaction_timer;

    logic CLK100MHZ;
    logic BTNC;
    logic BTNU;
    logic [15:0] LED;
    logic [7:0]  AN;
    logic CA, CB, CC, CD, CE, CF, CG, DP;

    // Instantiate DUT
    top_reaction_timer dut (
        .CLK100MHZ(CLK100MHZ),
        .BTNC(BTNC),
        .BTNU(BTNU),
        .LED(LED),
        .AN(AN),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
    );

    // Clock generation
    initial CLK100MHZ = 0;
    always #5 CLK100MHZ = ~CLK100MHZ; // 100 MHz

    // Helper tasks
    task press_btnc(input integer cycles);
        begin
            BTNC = 1;
            repeat(cycles) @(posedge CLK100MHZ);
            BTNC = 0;
        end
    endtask

    task press_btnu(input integer cycles);
        begin
            BTNU = 1;
            repeat(cycles) @(posedge CLK100MHZ);
            BTNU = 0;
        end
    endtask

    // Test sequence
    initial begin
        BTNC = 0;
        BTNU = 0;

        $display("=== TEST START ===");

        // Check IDLE displays ALOHA
        @(posedge CLK100MHZ);
        if (AN != 8'b11111000) $display("ERROR: AN not correct in S_IDLE");
        $display("S_IDLE: 'ALOHA' should be displayed");

        // Press BTNC to start reaction timer
        press_btnc(2);
        $display("Pressed BTNC: timer started (random delay begins)");

        // Simulate some cycles before LEDs turn on
        repeat(50) @(posedge CLK100MHZ);

        // Press BTNC early (before LEDs)
        press_btnc(2);
        $display("Early BTNC press: LEDs off, should go to 9999");
        @(posedge CLK100MHZ);
        $display("Digit displayed: %b", {CA, CB, CC, CD, CE, CF, CG, DP});

        // Reset DUT
        press_btnu(2);
        $display("Pressed BTNU: reset to S_IDLE");

        // Normal flow: start timer
        press_btnc(2);
        $display("Pressed BTNC: start normal reaction timer");

        // Wait until LEDs turn on (simulate random delay)
        repeat(500) @(posedge CLK100MHZ); // adjust cycles to ensure LIGHT_ON occurs

        $display("LEDs should be ON now for REACT");
        @(posedge CLK100MHZ);
        if (LED != 16'hFFFF) $display("ERROR: LEDs not on during REACT");

        // Press BTNC to stop timer
        press_btnc(2);
        $display("Pressed BTNC during REACT: timer should freeze");

        @(posedge CLK100MHZ);
        $display("Reaction time captured: %h", dut.reaction_time);

        // Press BTNU to reset FSM
        press_btnu(2);
        $display("Pressed BTNU: FSM reset to S_IDLE");

        $display("=== TEST END ===");
        $stop;
    end

endmodule
