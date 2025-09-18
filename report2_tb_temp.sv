module top_reaction_timer (
    input  logic clk,
    input  logic rst,      // BTNU -> reset
    input  logic btnc,     // BTNC -> start/stop
    output logic [15:0] led,
    output logic [7:0]  an,
    output logic [6:0]  seg
);

    // FSM states
    typedef enum logic [2:0] {
        S_IDLE,
        S_WAIT,
        S_REACT,
        S_DONE
    } state_t;

    state_t state, next_state;

    // LFSR for random delay
    logic [7:0] lfsr;
    logic lfsr_feedback;
    assign lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 8'h1;
        else
            lfsr <= {lfsr[6:0], lfsr_feedback};
    end

    // Simple LED + 7-seg driver logic
    logic [31:0] counter;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            counter <= 0;
        end else begin
            state <= next_state;
            counter <= counter + 1;
        end
    end

    // FSM transition
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE: if (btnc) next_state = S_WAIT;
            S_WAIT: if (counter[15:0] == {8'h00, lfsr}) next_state = S_REACT;
            S_REACT: if (btnc) next_state = S_DONE;
            S_DONE: if (rst) next_state = S_IDLE;
        endcase
    end

    // Display logic
    always_comb begin
        led = 16'b0;
        an  = 8'b11111111;
        seg = 7'b1111111; // blank
        case (state)
            S_IDLE: begin
                // Show "ALOHA" rotating (simplified to 'A' on digit0 for demo)
                an = 8'b11111110;
                seg = 7'b0001000; // A
            end
            S_WAIT: begin
                // Blank until LEDs flash
                an = 8'b11111111;
                seg = 7'b1111111;
            end
            S_REACT: begin
                led = 16'hFFFF; // all LEDs ON
                an = 8'b11111110;
                seg = 7'b0000110; // "E" = react indicator
            end
            S_DONE: begin
                // Freeze LEDs
                led = 16'hFFFF;
                an = 8'b11111110;
                seg = 7'b1000111; // "F" = done
            end
        endcase
    end

endmodule
