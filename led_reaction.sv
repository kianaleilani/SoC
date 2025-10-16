`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2025 10:27:11 PM
// Design Name: 
// Module Name: led_reaction
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//=====================================================
// Nexys 4 DDR - Reaction Timer Game
// BTNC starts random timer -> LED on -> 
// Press BTNC again -> LED off & time recorded
//=====================================================

//=====================================================
// Nexys 4 DDR - Reaction Timer Game
// BTNC starts random timer -> LED on -> 
// Press BTNC again -> LED off & time recorded
//=====================================================


//=====================================================
// Nexys 4 DDR - Reaction Timer Game w/ 7-Segment Display
//=====================================================
//=====================================================
// Nexys 4 DDR - Reaction Timer Game
// - BTNC starts game
// - LED0 turns on after random delay (2-15s)
// - BTNC again stops timer
// - 7-seg shows reaction time in seconds.xxx
//=====================================================


module reaction_timer_game (
    input  logic clk,        // 100 MHz system clock
    input  logic BTNC,       // Center pushbutton
    output logic LED,        // LED indicator
    output logic [6:0] SEG,  // Seven-segment segments a-g (active low)
    output logic DP,         // Decimal point (active low)
    output logic [7:0] AN    // Seven-segment digit enables (active low)
);

    //=====================================================
    // Parameters
    //=====================================================
    parameter int CLK_FREQ        = 100_000_000; // 100 MHz
    parameter int MIN_DELAY_S     = 2;
    parameter int MAX_DELAY_S     = 15;
    parameter int DEBOUNCE_COUNT  = 200_000; // 2 ms debounce
    parameter int PENALTY_DISPLAY_MS = 2000;
    parameter int TIMEOUT_S       = 10;

    //=====================================================
    // Custom 7-segment codes for letters and blank
    //=====================================================
    localparam logic [3:0] DIGIT_A = 4'd10;
    localparam logic [3:0] DIGIT_L = 4'd11;
    localparam logic [3:0] DIGIT_O = 4'd12;
    localparam logic [3:0] DIGIT_H = 4'd13;
    localparam logic [3:0] DIGIT_BLANK = 4'd15;

    //=====================================================
    // Debounce Logic
    //=====================================================
    logic btn_sync_0, btn_sync_1;
    logic btn_debounced;
    logic [17:0] debounce_counter;

    // Synchronizer
    always_ff @(posedge clk) begin
        btn_sync_0 <= BTNC;
        btn_sync_1 <= btn_sync_0;
    end

    // Debounce filter
    always_ff @(posedge clk) begin
        if (btn_sync_1 != btn_debounced) begin
            debounce_counter <= debounce_counter + 1;
            if (debounce_counter >= DEBOUNCE_COUNT) begin
                btn_debounced <= btn_sync_1;
                debounce_counter <= 0;
            end
        end else begin
            debounce_counter <= 0;
        end
    end

    // Edge detect
    logic btn_last;
    always_ff @(posedge clk) begin
        btn_last <= btn_debounced;
    end
    wire btn_pressed = btn_debounced & ~btn_last;

    //=====================================================
    // LFSR for pseudo-random delay
    //=====================================================
    logic [15:0] lfsr = 16'hACE1;
    always_ff @(posedge clk) begin
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    int rand_delay_cycles;
    int delay_counter;

    //=====================================================
    // State Machine
    //=====================================================
    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        WAIT_DELAY= 3'b001,
        LED_ON    = 3'b010,
        DONE      = 3'b011,
        PENALTY   = 3'b100,
        TIMEOUT   = 3'b101
    } state_t;

    state_t state = IDLE;

    int start_counter;
    int reaction_time_ms;
    int penalty_counter;

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                LED <= 0;
                reaction_time_ms <= 0;
                penalty_counter <= 0;

                if (btn_pressed) begin
                    rand_delay_cycles <= ((lfsr % (MAX_DELAY_S - MIN_DELAY_S + 1)) + MIN_DELAY_S) * CLK_FREQ;
                    delay_counter <= 0;
                    state <= WAIT_DELAY;
                end
            end

            WAIT_DELAY: begin
                delay_counter <= delay_counter + 1;
                if (btn_pressed) begin
                    state <= PENALTY;
                    penalty_counter <= 0;
                end else if (delay_counter >= rand_delay_cycles) begin
                    LED <= 1;
                    start_counter <= 0;
                    state <= LED_ON;
                end
            end

            LED_ON: begin
                start_counter <= start_counter + 1;

                if (btn_pressed) begin
                    LED <= 0;
                    reaction_time_ms <= start_counter / (CLK_FREQ / 1000);
                    state <= DONE;
                end else if (start_counter >= (TIMEOUT_S * CLK_FREQ)) begin
                    LED <= 0;
                    state <= TIMEOUT;
                end
            end

            DONE: begin
                if (btn_pressed) begin
                    rand_delay_cycles <= ((lfsr % (MAX_DELAY_S - MIN_DELAY_S + 1)) + MIN_DELAY_S) * CLK_FREQ;
                    delay_counter <= 0;
                    reaction_time_ms <= 0;
                    state <= WAIT_DELAY;
                end
            end

            PENALTY: begin
                penalty_counter <= penalty_counter + 1;
                if (penalty_counter >= (PENALTY_DISPLAY_MS * (CLK_FREQ/1000))) begin
                    state <= IDLE;
                end
            end

            TIMEOUT: begin
                penalty_counter <= penalty_counter + 1;
                if (penalty_counter >= (PENALTY_DISPLAY_MS * (CLK_FREQ/1000))) begin
                    state <= IDLE;
                end
            end
        endcase
    end

    //=====================================================
    // 7-Segment Display Logic
    //=====================================================
    logic [3:0] digit [7:0];
    int seconds;
    int milliseconds;

    always_comb begin
        if (state == IDLE) begin
            // Display "ALOHA"
            digit[0] = DIGIT_A;
            digit[1] = DIGIT_H;
            digit[2] = DIGIT_O;
            digit[3] = DIGIT_L;
            digit[4] = DIGIT_A;
            digit[5] = DIGIT_BLANK;
            digit[6] = DIGIT_BLANK;
            digit[7] = DIGIT_BLANK;
        end else if (state == PENALTY) begin
            // Display "9999"
            digit[0] = 4'd9;
            digit[1] = 4'd9;
            digit[2] = 4'd9;
            digit[3] = 4'd9;
            digit[4] = DIGIT_BLANK;
            digit[5] = DIGIT_BLANK;
            digit[6] = DIGIT_BLANK;
            digit[7] = DIGIT_BLANK;
        end else if (state == TIMEOUT) begin
            // Display "1111"
            digit[0] = 4'd1;
            digit[1] = 4'd1;
            digit[2] = 4'd1;
            digit[3] = 4'd1;
            digit[4] = DIGIT_BLANK;
            digit[5] = DIGIT_BLANK;
            digit[6] = DIGIT_BLANK;
            digit[7] = DIGIT_BLANK;
        end else begin
            seconds = reaction_time_ms / 1000;
            milliseconds = reaction_time_ms % 1000;
            digit[0] = milliseconds % 10;
            digit[1] = (milliseconds / 10) % 10;
            digit[2] = (milliseconds / 100) % 10;
            digit[3] = seconds % 10;
            digit[4] = (seconds / 10) % 10;
            digit[5] = DIGIT_BLANK;
            digit[6] = DIGIT_BLANK;
            digit[7] = DIGIT_BLANK;
        end
    end

    //=====================================================
    // Refresh Logic
    //=====================================================
    logic [19:0] refresh_counter = 0;
    logic [2:0]  current_digit = 0;

    always_ff @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        current_digit <= refresh_counter[19:17];
    end

    assign AN = ~(8'b00000001 << current_digit);
    assign DP = (current_digit == 3) ? 1'b0 : 1'b1;

    //=====================================================
    // Segment Decoder (active low)
    //=====================================================
    always_comb begin
        case (digit[current_digit])
            4'd0: SEG = 7'b1000000;
            4'd1: SEG = 7'b1111001;
            4'd2: SEG = 7'b0100100;
            4'd3: SEG = 7'b0110000;
            4'd4: SEG = 7'b0011001;
            4'd5: SEG = 7'b0010010;
            4'd6: SEG = 7'b0000010;
            4'd7: SEG = 7'b1111000;
            4'd8: SEG = 7'b0000000;
            4'd9: SEG = 7'b0010000;
            DIGIT_A: SEG = 7'b0001000;      // A
            DIGIT_L: SEG = 7'b1000111;      // L
            DIGIT_O: SEG = 7'b1000000;      // O
            DIGIT_H: SEG = 7'b0001001;      // H
            DIGIT_BLANK: SEG = 7'b1111111;  // Blank
            default: SEG = 7'b1111111;
        endcase
    end

endmodule


