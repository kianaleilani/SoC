module top_reaction_timer(
    input  logic CLK100MHZ,
    input  logic BTNC,  // button for start and stop
      input  logic BTNU,  // button for reset
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
        S_DISPLAY
    } state_t;

    state_t state, next_state;

    // Counters
    logic [31:0] counter;
    logic [31:0] reaction_time;

  // Random delay - Linear Shift Feedback Register
    logic [15:0] lfsr = 16'hACE1;
    always_ff @(posedge CLK100MHZ) begin
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    // 7-segment display signals
    logic [3:0] digit;
    logic [7:0] seg;  // {DP, CG, CF, CE, CD, CC, CB, CA}
    logic [2:0] an_idx;

    // Slow clock divider for 7-segment scanning (~1 kHz)
    logic [16:0] clk_div;
    always_ff @(posedge CLK100MHZ) begin
        if (clk_div == 99999) begin
            clk_div <= 0;
            an_idx <= (an_idx == 7) ? 0 : an_idx + 1;
        end else
            clk_div <= clk_div + 1;
    end

    // FSM Sequential
    always_ff @(posedge CLK100MHZ) begin
      if (BTNU) begin
            state <= S_IDLE;
            counter <= 0;
            reaction_time <= 0;
       end else begin
            state <= next_state;
            if (state == S_WAIT_RANDOM || state == S_REACT)
                counter <= counter + 1;
            else
                counter <= 0;

            if (state == S_REACT && BTNC)   // stop timer
                reaction_time <= counter;
        end
    end

    // FSM Next-State Logic
    always_comb begin
        next_state = state;
        case (state)
          S_IDLE:        if (BTNU) next_state = S_WAIT_RANDOM;
            S_WAIT_RANDOM: if (counter > {lfsr, 10'd0}) next_state = S_LIGHT_ON;
            S_LIGHT_ON:    next_state = S_REACT;
            S_REACT:       if (BTNC) next_state = S_DISPLAY;
          S_DISPLAY:     if (BTNU) next_state = S_IDLE;
        endcase
    end

    // LED Output
    always_comb begin
        LED = 16'b0;
        if (state == S_LIGHT_ON || state == S_REACT)
            LED = 16'hFFFF; // all LEDs on during reaction timer
    end

    // 7-segment anode logic
    always_comb begin
        AN = 8'b11111111;        // default all off
        if (state == S_IDLE || state == S_REACT || state == S_DISPLAY)
            AN[an_idx] = 0;      // active low
    end

    // Display logic
    always_comb begin
        case (state)
            S_IDLE: begin
              // Display "ALOHA" across 5 digits
              case (an_idx)
                  3'd0: digit = 4'h1; // "A"
                  3'd1: digit = 4'h2; // "L"
                  3'd2: digit = 4'h3; // "O"
                  3'd3: digit = 4'h4; // "H"
                  3'd4: digit = 4'h1; // "A" again
                  default: digit = 4'hF; // blank
              endcase
            end
            S_WAIT_RANDOM, S_LIGHT_ON, S_REACT, S_DISPLAY: begin
                // Display reaction_time (hex) on 4 digits
                case (an_idx)
                    3'd0: digit = reaction_time[3:0];
                    3'd1: digit = reaction_time[7:4];
                    3'd2: digit = reaction_time[11:8];
                    3'd3: digit = reaction_time[15:12];
                    default: digit = 4'hF;
                endcase
            end
            default: digit = 4'hF;
        endcase
    end

  
    always_comb begin
    case (digit)
        4'h0: seg = 8'b11000000; // 0
        4'h1: seg = 8'b10001000; // A
        4'h2: seg = 8'b11000111; // L
        4'h3: seg = 8'b11000000; // O
        4'h4: seg = 8'b10001001; // H
        4'h5: seg = 8'b11111001; // I (if needed later)
        4'hF: seg = 8'b11111111; // blank
        default: seg = 8'b11111111;
    endcase
end

    // Assign physical pins
    assign {DP, CG, CF, CE, CD, CC, CB, CA} = seg;

endmodule

