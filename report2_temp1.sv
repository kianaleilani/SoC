odule top_reaction_timer(
    input  logic CLK100MHZ,
    input  logic BTNC,  // start/stop
    input  logic BTNU,  // clear
    output logic [15:0] LED,
    output logic [7:0]  AN,
    output logic CA, CB, CC, CD, CE, CF, CG, DP
);

    // FSM states
    typedef enum logic [2:0] {
        S_IDLE,
        S_WAIT_RANDOM,
        S_LIGHT_ON,
        S_REACT,
        S_DISPLAY
    } state_t;

    state_t state, next_state;

    // Counters
    logic [31:0] counter;
    logic [31:0] reaction_time;

    // Early stop flag
    logic early_stop;

    // Random delay (2 to 15 seconds)
    logic [15:0] lfsr = 16'hACE1;
    logic [31:0] random_delay;

    always_ff @(posedge CLK100MHZ) begin
        // LFSR for randomness
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        // random delay in clock cycles (1ms resolution)
        random_delay <= (2_000 + (lfsr % 13_000)) * 100_000; // 2-15 sec
    end

    // FSM sequential
    always_ff @(posedge CLK100MHZ) begin
        if (BTNU) begin
            state <= S_IDLE;
            counter <= 0;
            reaction_time <= 0;
            early_stop <= 0;
        end else begin
            state <= next_state;

            // Counter increments in WAIT_RANDOM and REACT
            if (state == S_WAIT_RANDOM || state == S_REACT)
                counter <= counter + 1;
            else
                counter <= 0;

            // Capture reaction time when stop pressed during REACT
            if (state == S_REACT && BTNC)
                reaction_time <= counter / 100_000; // convert to ms

            // Detect early stop
            if ((state == S_WAIT_RANDOM) && BTNC)
                early_stop <= 1;
        end
    end

    // FSM next state logic
    always_comb begin
        next_state = state;
        case(state)
            S_IDLE:        if (BTNC) next_state = S_WAIT_RANDOM;
            S_WAIT_RANDOM: begin
                if (early_stop) next_state = S_DISPLAY;
                else if (counter >= random_delay) next_state = S_LIGHT_ON;
            end
            S_LIGHT_ON:    next_state = S_REACT;
            S_REACT:       if (BTNC || counter >= 100_000_000) next_state = S_DISPLAY; // 1 sec max
            S_DISPLAY:     if (BTNU) next_state = S_IDLE;
        endcase
    end

    // LED output
    always_comb begin
        if (early_stop)
            LED = 16'b0;  // LEDs off if early stop
        else if (state == S_LIGHT_ON || state == S_REACT)
            LED = 16'hFFFF; // LEDs on
        else
            LED = 16'b0;
    end

    // 7-segment scanning (~1kHz)
    logic [16:0] clk_div;
    logic [2:0] an_idx;
    always_ff @(posedge CLK100MHZ) begin
        if (clk_div == 99999) begin
            clk_div <= 0;
            an_idx <= (an_idx == 7) ? 0 : an_idx + 1;
        end else
            clk_div <= clk_div + 1;
    end

    // Anode control
    always_comb begin
        AN = 8'b11111111;
        AN[an_idx] = 0; // active low
    end

    // 7-segment display digits
    logic [3:0] digit;
    always_comb begin
        if (state == S_IDLE) begin
            // Display "HI"
            case(an_idx)
                3'd0: digit = 4'h1; // A
                3'd1: digit = 4'h4; // L
                3'd2: digit = 4'h3; // O
                3'd3: digit = 4'h2; // H
                3'd4: digit = 4'h1; // A
                default: digit = 4'hF;
            endcase
        end else if (early_stop) begin
            // Display 9999 on early stop
            case(an_idx)
                3'd0: digit = 4'd9;
                3'd1: digit = 4'd9;
                3'd2: digit = 4'd9;
                3'd3: digit = 4'd9;
                default: digit = 4'hF;
            endcase
        end else begin
            // Display reaction_time in ms (up to 9999)
            case(an_idx)
                3'd0: digit = reaction_time % 10;
                3'd1: digit = (reaction_time / 10) % 10;
                3'd2: digit = (reaction_time / 100) % 10;
                3'd3: digit = (reaction_time / 1000) % 10;
                default: digit = 4'hF;
            endcase
        end
    end

    // 7-segment cathodes
    logic [7:0] seg;
    always_comb begin
        case(digit)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b10001000; // A
            4'd2: seg = 8'b11000111; // L
            4'd3: seg = 8'b11000000; // O
            4'd4: seg = 8'b10001001; // H
            4'd5: seg = 8'b11111001; // I
            4'd9: seg = 8'b10010000;
            4'hF: seg = 8'b11111111; // blank
            default: seg = 8'b11111111;
        endcase
    end

    assign {DP, CG, CF, CE, CD, CC, CB, CA} = seg;

endmodule
