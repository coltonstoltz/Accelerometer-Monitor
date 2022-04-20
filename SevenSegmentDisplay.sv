`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2021 07:03:42 PM
// Design Name: 
// Module Name: SevenSegmentDisplay
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


module SevenSegmentDisplay(
    input logic clk,
    input logic [31:0] x,
    output logic dp,
    output logic [7:0] anodes,
    output logic [6:0] seg
);

    logic [19:0] clk_div = 0;
    logic [2:0] s;
    logic [3:0] digit;
    logic [7:0] aen;
    
    assign s = clk_div[19:17];
    assign dp = 1'b1;
    assign aen = 8'b11111111; // all turned off initially
    //assign anodes = 8'b11111111;

    always_ff @(posedge clk) begin
        case (s)
            0 : digit <= x[3:0];
            1 : digit <= x[7:4];
            2 : digit <= x[11:8];
            3 : digit <= x[15:12];
            4 : digit <= x[19:16];
            5 : digit <= x[23:20];
            6 : digit <= x[27:24];
            7 : digit <= x[31:28];
            
            default : digit <= x[3:0];
        endcase
    end
    
    always_comb begin
        case(digit)
            0   : seg = 7'b1000000;
            1   : seg = 7'b1111001;
            2   : seg = 7'b0100100;
            3   : seg = 7'b0110000;
            4   : seg = 7'b0011001;
            5   : seg = 7'b0010010;
            6   : seg = 7'b0000010;
            7   : seg = 7'b1111000;
            8   : seg = 7'b0000000;
            9   : seg = 7'b0010000;
            'hA : seg = 7'b0001000;
            'hB : seg = 7'b0000011;
            'hC : seg = 7'b1000110;
            'hD : seg = 7'b0100001;
            'hE : seg = 7'b0000110;
            'hF : seg = 7'b0001110;
            
            default : seg = 7'b0000000;
        endcase
    end
    always_comb begin
      anodes=8'b11111111;
      if(aen[s] == 1)
        anodes[s] = 0;
    end
    /*
    always @(*) begin
        anodes = 8'b1111111;
        anodes[s] = 1'b0;
    end
    */
    always_ff @(posedge clk) begin
        clk_div <= clk_div + 1'b1;
    end


endmodule
