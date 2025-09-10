module rotate_seg(
    input  logic clk,        // main clock
    input  logic reset, // reset
  	input logic en = 0,
  	input logic cw,
    output logic [6:0] seg,  // 7-segment LEDs (abcdefg)
    output logic [3:0] an    // digit enable (active low)
);

    // Segment & anode pattern lookup
    always_comb begin
        seg = 7'b0000000; // default off
        an  = 4'b0000;    // all digits off
      
        case(cw)
              // Top row (rightward rotation)
              3'd0: begin seg = 7'b1100011; an = 4'b1000; end 
              3'd1: begin seg = 7'b1100011; an = 4'b0100; end // digit1
              3'd2: begin seg = 7'b1100011; an = 4'b0010; end // digit2
              3'd3: begin seg = 7'b1100011; an = 4'b0001; end // digit3

              // Bottom row (leftward rotation back)
              3'd4: begin seg = 7'b0011101; an = 4'b0001; end // "segment 
              3'd5: begin seg = 7'b0011101; an = 4'b0010; end // digit2
              3'd6: begin seg = 7'b0011101; an = 4'b0100; end // digit1
              3'd7: begin seg = 7'b0011101; an = 4'b1000; end // digit0
        endcase

        case(~cw)
                      // Top row (rightward rotation)
              3'd0: begin seg = 7'b1100011; an = 4'b1000; end 
              3'd1: begin seg = 7'b0011101; an = 4'b1000; end // digit1
              3'd2: begin seg = 7'b0011101; an = 4'b0100; end // digit2
              3'd3: begin seg = 7'b0011101; an = 4'b0010; end // digit3

              // Bottom row (leftward rotation back)
              3'd4: begin seg = 7'b0011101; an = 4'b0001; end // "segment 
              3'd5: begin seg = 7'b1100011; an = 4'b0001; end // digit2
              3'd6: begin seg = 7'b1100011; an = 4'b0010; end // digit1
              3'd7: begin seg = 7'b1100011; an = 4'b0100; end // digit0
        endcase
      
    end

endmodule
