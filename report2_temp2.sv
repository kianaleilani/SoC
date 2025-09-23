module reaction_led_fsm (
    input  logic clk,
    input  logic reset,
    input  logic BTNC,  // Start/Stop
    input  logic BTNU,  // Clear
    input  logic BTNL,  // (unused for now)
    input  logic BTNR,  // (unused for now)
    input  logic BTND,  // (unused for now)
    output logic [15:0] LED,  // All board LEDs
    output logic [6:0] seg,
    output logic [3:0] an
);

    // FSM state encoding
    typedef enum logic [1:0] { S_IDLE, S_WAIT, S_RUNNING, S_STOPPED } state_t;
    state_t state, next_state;

    // Timer and random delay
    logic [31:0] timer;
    logic [15:0] lfsr;

    // LED logic (all on/off)
    assign LED = (state == S_RUNNING) ? 16'hFFFF : 16'h0000;

    // LFSR random delay generator
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    // FSM sequential
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            timer <= 0;
        end else begin
            state <= next_state;
            if (state == S_RUNNING)
                timer <= timer + 1;
            else if (state == S_IDLE)
                timer <= 0;
        end
    end

    // FSM combinational
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:    if (BTNC) next_state = S_WAIT;
            S_WAIT:    if (lfsr[3:0] == 4'b0000) next_state = S_RUNNING; // random-ish delay
            S_RUNNING: if (BTNC) next_state = S_STOPPED;
            S_STOPPED: if (BTNU) next_state = S_IDLE;
        endcase
    end

    // For now, keep 7-seg off
    assign seg = 7'b1111111;
    assign an  = 4'b1111;

endmodule
