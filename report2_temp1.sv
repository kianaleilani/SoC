module top_reaction_timer(
    input  logic CLK100MHZ,
    input  logic BTNC,  // start/stop
    input  logic BTNU,  // reset
    output logic [15:0] LED,         // board LEDs
    output logic [7:0]  AN,          // 7-seg anodes
    output logic CA, CB, CC, CD, CE, CF, CG, DP // 7-seg cathodes
);

    // FSM States
    typedef enum logic [2:0] {
        S_IDLE,
        S_WAIT_RANDOM,
        S_LIGHT_ON,
        S_REACT,
        S_DISPLAY,
        S_EARLY_STOP
    } state_t;

    state_t state, next_state;

    // Counters
    logic [31:0] counter;
    logic [31:0] reaction_time;
    logic [31:0] random_delay;

    // LFSR for random delay
    logic [15:0] lfsr = 16'hACE1;
    always_ff @(posedge CLK100MHZ) begin
        lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
    end

    // 7-segment scanning
    logic [2:0] an_idx;
    logic [3:0] digit;
    logic [7:0] seg;
    logic stop_pressed;

    logic [16:0] clk_div;
    always_ff @(posedge CLK100MHZ) begin
        if (clk_div == 99999) begin
            clk_div <= 0;
            an_idx <= (an_idx == 7) ? 0 : an_idx + 1;
        end else
            clk_div <= clk_div + 1;
    end

    // FSM sequential
    always_ff @(posedge CLK100MHZ) begin
        if (BTNU) begin
            state <= S_IDLE;
            counter <= 0;
            reaction_time <= 0;
            random_delay <= 0;
            stop_pressed <= 0;
        end else begin
            state <= next_state;

            // Only increment counter if reaction not stopped
            if ((state == S_WAIT_RANDOM) || (state == S_REACT && !stop_pressed))
                counter <= counter + 1;
            else
                counter <= 0;

            // Stop reaction timer when BTNC pressed in REACT
            if (state == S_REACT && BTNC)
                stop_pressed <= 1;

            if (state == S_REACT && BTNC && !stop_pressed)
                reaction_time <= counter;

            // LEDs on during LIGHT_ON and REACT
            if (state == S_LIGHT_ON || state == S_REACT || state == S_DISPLAY)
                LED <= 16'hFFFF;
            else
                LED <= 16'b0;
        end
    end

    // FSM next-state logic
    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: if (BTNC) begin
                        random_delay = 200_000_000 + (lfsr % 1_300_000_000); // 2-15 sec scaled
                        next_state = S_WAIT_RANDOM;
                    end

            S_WAIT_RANDOM: begin
                if (BTNC) next_state = S_EARLY_STOP;
                else if (counter >= random_delay) next_state = S_LIGHT_ON;
            end

            S_LIGHT_ON: next_state = S_REACT;

            S_REACT: if (BTNC) next_state = S_DISPLAY;

            S_DISPLAY: if (BTNU) next_state = S_IDLE;

            S_EARLY_STOP: if (BTNU) next_state = S_IDLE;

            default: next_state = S_IDLE;
        endcase
    end

    // 7-segment anode logic
    always_comb begin
        AN = 8'b11111111; // default all off

        // ALOHA display in S_IDLE
        if (state == S_IDLE)
            AN[7:3] = 5'b00000;

        // Normal scanning for REACT, DISPLAY, EARLY_STOP
        if (state == S_REACT || state == S_DISPLAY || state == S_LIGHT_ON || state == S_EARLY_STOP)
            AN[an_idx] = 0;
    end

    // Digit selection
    always_comb begin
        case (state)
            S_IDLE: begin
                case (an_idx)
                    3'd0: digit = 4'h1; // A
                    3'd1: digit = 4'h2; // L
                    3'd2: digit = 4'h3; // O
                    3'd3: digit = 4'h4; // H
                    3'd4: digit = 4'h1; // A
                    default: digit = 4'hF;
                endcase
            end

            S_REACT, S_LIGHT_ON, S_DISPLAY: begin
                case (an_idx)
                    3'd0: digit = reaction_time[3:0];
                    3'd1: digit = reaction_time[7:4];
                    3'd2: digit = reaction_time[11:8];
                    3'd3: digit = reaction_time[15:12];
                    default: digit = 4'hF;
                endcase
            end

            S_EARLY_STOP: digit = 4'h9;

            default: digit = 4'hF;
        endcase
    end

    // 7-segment hex mapping
    always_comb begin
        case (digit)
            4'h0: seg = 8'b11000000;
            4'h1: seg = 8'b10001000; // A
            4'h2: seg = 8'b11000111; // L
            4'h3: seg = 8'b11000000; // O
            4'h4: seg = 8'b10001001; // H
            4'h5: seg = 8'b11111001; // I
            4'h9: seg = 8'b10011110; // 9
            4'hF: seg = 8'b11111111; // blank
            default: seg = 8'b11111111;
        endcase
    end

    assign {DP, CG, CF, CE, CD, CC, CB, CA} = seg;

endmodule
