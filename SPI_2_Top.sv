`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2022 02:26:57 PM
// Design Name: 
// Module Name: SPI_2_Top
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


module SPI_2_Top(
    input logic i_clk_100MHZ,
    input logic i_rst,
    output logic o_sclk,
    output logic o_mosi,
    input logic i_miso,
    output logic o_cs,
    
    input logic [2:0] sel_mux_out,
    output logic [2:0] led_sel_mux_out,
    
    output logic dp,
    output logic [7:0] anodes,
    output logic [6:0] seg
    );
    
    logic [31:0] miso_data;

    SPI_Controller_2 SPI(.i_clk_100MHZ(i_clk_100MHZ), .i_rst(i_rst), .o_sclk(o_sclk), .o_mosi(o_mosi), .i_miso(i_miso), .o_cs(o_cs), .i_sel_mux_out(sel_mux_out), .o_axis_data(miso_data));
    SevenSegmentDisplay(.clk(i_clk_100MHZ), .x(miso_data), .dp(dp), .anodes(anodes), .seg(seg));
    
    assign led_sel_mux_out = sel_mux_out;
endmodule
