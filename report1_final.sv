// Code your design here
module rotate_pattern(
    input  logic clk,        // main clock
    input  logic reset, // reset
  	input logic en,
  	input logic cw,
    output logic [6:0] seg,  // 7-segment LEDs (abcdefg)
  output logic [6:0] an    // digit enable (active low)
);


    // State counter
  logic [2:0] state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= 0;
        else
            state <= state + 1;
    end

    always_comb begin
        //seg = 7'b0000000; // default
        //an  = 7'b0000000;    // all digits off
      if(en)
        if(cw)
          case(state) // iterate through each step/digit

                  3'd0: begin seg = 7'b0011100; an = 7'b0111111; end 
                  3'd1: begin seg = 7'b0011100; an = 7'b1011111; end 
                  3'd2: begin seg = 7'b0011100; an = 7'b1101111; end 
                  3'd3: begin seg = 7'b0011100; an = 7'b1110111; end 

                  3'd4: begin seg = 7'b1100010; an = 7'b1110111; end 
                  3'd5: begin seg = 7'b1100010; an = 7'b1101111; end 
                  3'd6: begin seg = 7'b1100010; an = 7'b1011111; end 
                  3'd7: begin seg = 7'b1100010; an = 7'b0111111; end 

          endcase
      
      if(~cw)
          case(state) // iterate through each step/digit

                  3'd0: begin seg = 7'b0011100; an = 7'b0111111; end 
                  3'd1: begin seg = 7'b1100010; an = 7'b0111111; end 
                  3'd2: begin seg = 7'b1100010; an = 7'b1011111; end 
                  3'd3: begin seg = 7'b1100010; an = 7'b1101111; end 

                  3'd4: begin seg = 7'b1100010; an = 7'b1110111; end 
                  3'd5: begin seg = 7'b1100011; an = 7'b1110111; end 
                  3'd6: begin seg = 7'b1100011; an = 7'b1101111; end 
                  3'd7: begin seg = 7'b1100011; an = 7'b1011111; end 

          endcase
          
    end

endmodule

