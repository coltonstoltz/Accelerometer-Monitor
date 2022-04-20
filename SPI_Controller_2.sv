`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2022 11:21:20 AM
// Design Name: 
// Module Name: SPI_Controller_2
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
`define SYS_FREQ_HZ 32'd100000000
`define SPI_FREQ_HZ 32'd3125000
`define CLK_CYC_SPI_PERIOD (`SYS_FREQ_HZ / `SPI_FREQ_HZ)
`define INSTR_DELAY_CLK_CYCLES (`SYS_FREQ_HZ / 1000) 
`define SPI_INSTR_DELAY (`SYS_FREQ_HZ / 32)
`define WRT_BITS 5'd24
`define RD_BITS 5'd16
`define NUM_WRT_INSTR 5'd4
`define NUM_RD_INSTR 5'd3

module SPI_Controller_2(
    input logic i_clk_100MHZ,
    input logic i_rst,
    
    // SPI Signals
    output logic o_sclk,
    output logic o_mosi,
    input logic i_miso,
    output logic o_cs,
    
    //Direct output of MISO Register
    input logic [2:0] i_sel_mux_out,
    output logic [31:0] o_axis_data
    );
    
    //SPI Shift Registers
    logic [23:0] MOSI_Shift_Reg;
    logic [7:0] MISO_Shift_Reg;
    
    // Registers to store axis data
    logic [7:0] x_reg;
    logic [7:0] y_reg;
    logic [7:0] z_reg;
    logic [31:0] status_reg;
    
    // Memory to hold initialize sequence instructions
    logic [23:0] Init_Instructions [0:19];
    
    // To keep track of counters and indexes, read/write mode
    logic [4:0] ser_count;
    logic [4:0] instr_idx;
    logic [16:0] instr_delay_count;
    logic [26:0] idle_count;
    logic wr_rd_mode = 0; // 0 for write mode -- 1 for read mode
    
    // State Declarations
    typedef enum logic [5:0]{
        RST,
        UNSET_RST,
        SETTLE_RST,
        LOAD_SHIFT_REG,
        SELECT_CHIP,
        SCLK_LOW,
        SCLK_LOW_HOLD,
        SCLK_HIGH,
        SCLK_HIGH_HOLD,
        SCLK_LOW_SHIFT,
        SCLK_LOW_SHIFT_HOLD,
        INCREMENT_INSTR,
        DESELECT_CHIP,
        IDLE,
        LOOP_INSTR_IDX
    } states_t;
    
    states_t state, next_state;
    
    // Loading initialization intruction memory
    initial begin
        $readmemh("C:/Users/colto/Documents/Verilog_Projects/Accelerometer/Init_Seq.txt", Init_Instructions, 0, 6);
    end
    
    always_ff @(posedge i_clk_100MHZ or posedge i_rst) begin
        if (i_rst)
            state <= RST;
        else
            state <= next_state;
    end
    
    always_comb begin
        next_state = RST;
        case (state)
            RST: 
                next_state = SETTLE_RST;
            SETTLE_RST: begin
                if (instr_delay_count < `INSTR_DELAY_CLK_CYCLES)
                    next_state = SETTLE_RST;
                else
                    next_state = UNSET_RST;
            end
            UNSET_RST: 
                next_state = LOAD_SHIFT_REG;
            LOAD_SHIFT_REG: 
                next_state = SELECT_CHIP;
            SELECT_CHIP: 
                next_state = SCLK_LOW;
            SCLK_LOW: 
                next_state = SCLK_LOW_HOLD;
            SCLK_LOW_HOLD: begin
                if (instr_delay_count < (`CLK_CYC_SPI_PERIOD / 2) - 1) //
                    next_state = SCLK_LOW_HOLD;
                else 
                    next_state = SCLK_HIGH;
            end
            SCLK_HIGH: 
                next_state = SCLK_HIGH_HOLD;
            SCLK_HIGH_HOLD: begin
                if (instr_delay_count < (`CLK_CYC_SPI_PERIOD / 2) - 1)  //
                    next_state = SCLK_HIGH_HOLD;
                else 
                    next_state = SCLK_LOW_SHIFT;
            end
            SCLK_LOW_SHIFT: 
                next_state = SCLK_LOW_SHIFT_HOLD;
            SCLK_LOW_SHIFT_HOLD: begin
                if (instr_delay_count < (`CLK_CYC_SPI_PERIOD / 2) - 1) //
                    next_state = SCLK_LOW_SHIFT_HOLD;
                else begin
                    if (!wr_rd_mode) begin // In write mode
                        if (ser_count < `WRT_BITS)
                            next_state = SCLK_HIGH;
                        else
                            next_state = INCREMENT_INSTR;
                    end
                end
            end
            INCREMENT_INSTR:
                next_state = DESELECT_CHIP;
            DESELECT_CHIP: begin
                if (instr_idx < `NUM_WRT_INSTR)
                    next_state = SETTLE_RST;
                else
                    if (instr_idx < (`NUM_RD_INSTR + `NUM_WRT_INSTR))
                        next_state = IDLE;
                    else 
                        next_state = LOOP_INSTR_IDX;
            end
            IDLE: begin
                if (idle_count < 27'd3_333_333)
                    next_state = IDLE;
                else
                    next_state = LOAD_SHIFT_REG;
            end
            LOOP_INSTR_IDX:
                next_state = IDLE;
        endcase
    end
    
    always_ff @(posedge i_clk_100MHZ) begin
        case (state)
            RST: begin
                instr_delay_count <= 0;
                o_sclk <= 1'b0;
                o_cs <= 1'b1;
                ser_count <= 5'b0;
                instr_idx <= 5'b0;
                MOSI_Shift_Reg <= 23'b0;
                MISO_Shift_Reg <= 8'b0;
            end
            SETTLE_RST: begin
                instr_delay_count <= instr_delay_count + 1;
            end
            UNSET_RST: begin
                instr_delay_count <= 0;
            end
            LOAD_SHIFT_REG: begin
                MOSI_Shift_Reg <= Init_Instructions[instr_idx];
                idle_count <= 0;
            end
            SELECT_CHIP: begin
                o_cs <= 1'b0;
            end
            SCLK_LOW: begin
                o_sclk <= 1'b0;
                instr_delay_count <= 0;
            end
            SCLK_LOW_HOLD: begin
                instr_delay_count <= instr_delay_count + 1;
            end
            SCLK_HIGH: begin
                o_sclk <= 1'b1;
                instr_delay_count <= 0;
            end
            SCLK_HIGH_HOLD: begin
                instr_delay_count <= instr_delay_count + 1;
            end
            SCLK_LOW_SHIFT: begin
                o_sclk <= 1'b0;
                ser_count <= ser_count + 1;
                MOSI_Shift_Reg <= {MOSI_Shift_Reg[22:0], 1'b0};
                MISO_Shift_Reg <= {MISO_Shift_Reg[7:0], i_miso};
                instr_delay_count <= 0;          
            end
            SCLK_LOW_SHIFT_HOLD: begin
                instr_delay_count <= instr_delay_count + 1;
                unique case (instr_idx)
                      //5'd16: status_reg <= MISO_Shift_Reg;
                      5'd4: x_reg <= MISO_Shift_Reg;
                      5'd5: y_reg <= MISO_Shift_Reg;
                      5'd6: z_reg <= MISO_Shift_Reg;
                endcase
            end
            INCREMENT_INSTR: begin
                instr_idx <= instr_idx + 1;
                ser_count <= 0;
            end
            DESELECT_CHIP: begin
                o_cs <= 1'b1;
                instr_delay_count <= 0;
            end
            IDLE: begin
                idle_count <= idle_count + 1;
            end
            LOOP_INSTR_IDX: begin
                instr_idx <= `NUM_WRT_INSTR;
            end
        endcase
    end
    
    assign o_mosi = MOSI_Shift_Reg[23];
    assign o_axis_data = (i_sel_mux_out == 3'b000) ? {x_reg, 4'b0, y_reg, 4'b0, z_reg} : 
                         (i_sel_mux_out == 3'b001) ? {x_reg, 24'b0} :
                         (i_sel_mux_out == 3'b010) ? {12'b0, y_reg, 12'b0} : 
                         (i_sel_mux_out == 3'b100) ? {24'b0, z_reg} : 32'b0;
//    assign o_axis_data = (i_sel_mux_out == 3'b000) ? status_reg[31:24] : 
//                         (i_sel_mux_out == 3'b001) ? status_reg[23:16] :
//                         (i_sel_mux_out == 3'b010) ? status_reg[15:8] : 
//                         (i_sel_mux_out == 3'b100) ? status_reg[7:0] : 32'b0;
endmodule
