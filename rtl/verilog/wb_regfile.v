//////////////////////////////////////////////////////////////////////
////                                                              ////
////  $Id: wb_regfile.v,v 1.2 2008-03-05 05:50:59 hharte Exp $    ////
////  wb_regfile.v - Small Wishbone register file for testing     ////
////                                                              ////
////  This file is part of the Wishbone LPC Bridge project        ////
////  http://www.opencores.org/projects/wb_lpc/                   ////
////                                                              ////
////  Author:                                                     ////
////      - Howard M. Harte (hharte@opencores.org)                ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Howard M. Harte                           ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

module wb_regfile (clk_i, nrst_i, wb_adr_i, wb_dat_o, wb_dat_i, wb_sel_i, wb_we_i,
                   wb_stb_i, wb_cyc_i, wb_ack_o, datareg0, datareg1);

    input          clk_i;
    input          nrst_i;
    input    [2:0] wb_adr_i;
    output reg [31:0] wb_dat_o;
    input   [31:0] wb_dat_i;
    input    [3:0] wb_sel_i;
    input          wb_we_i;
    input          wb_stb_i;
    input          wb_cyc_i;
    output reg     wb_ack_o;
    output  [31:0] datareg0;
    output  [31:0] datareg1;

    //
    // generate wishbone register bank writes
    wire wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access

    reg [7:0]   datareg0_0;
    reg [7:0]   datareg0_1;
    reg [7:0]   datareg0_2;
    reg [7:0]   datareg0_3;

    reg [7:0]   datareg1_0;
    reg [7:0]   datareg1_1;
    reg [7:0]   datareg1_2;
    reg [7:0]   datareg1_3;

    always @(posedge clk_i or negedge nrst_i)
        if (~nrst_i)                // reset registers
            begin
                datareg0_0 <= 8'h00;
                datareg0_1 <= 8'h01;
                datareg0_2 <= 8'h02;
                datareg0_3 <= 8'h03;
                datareg1_0 <= 8'h10;
                datareg1_1 <= 8'h11;
                datareg1_2 <= 8'h12;
                datareg1_3 <= 8'h13;
            end
        else if(wb_wr)          // wishbone write cycle
            case (wb_sel_i)
                4'b0000:
                    case (wb_adr_i)         // synopsys full_case parallel_case
                        3'b000: datareg0_0 <= wb_dat_i[7:0];
                        3'b001: datareg0_1 <= wb_dat_i[7:0];
                        3'b010: datareg0_2 <= wb_dat_i[7:0];
                        3'b011: datareg0_3 <= wb_dat_i[7:0];
                        3'b100: datareg1_0 <= wb_dat_i[7:0];
                        3'b101: datareg1_1 <= wb_dat_i[7:0];
                        3'b110: datareg1_2 <= wb_dat_i[7:0];
                        3'b111: datareg1_3 <= wb_dat_i[7:0];
                    endcase
                4'b0001:
                    case (wb_adr_i)         // synopsys full_case parallel_case
                        3'b000: datareg0_0 <= wb_dat_i[7:0];
                        3'b001: datareg0_1 <= wb_dat_i[7:0];
                        3'b010: datareg0_2 <= wb_dat_i[7:0];
                        3'b011: datareg0_3 <= wb_dat_i[7:0];
                        3'b100: datareg1_0 <= wb_dat_i[7:0];
                        3'b101: datareg1_1 <= wb_dat_i[7:0];
                        3'b110: datareg1_2 <= wb_dat_i[7:0];
                        3'b111: datareg1_3 <= wb_dat_i[7:0];
                    endcase
                4'b0011:
                    {datareg0_1, datareg0_0} <= wb_dat_i[15:0];
//                  case (wb_adr_i)         // synopsys full_case parallel_case
//                      3'b000: {datareg0_1, datareg0_0} <= wb_dat_i[15:0];
//                  endcase
                4'b1111:
                    {datareg0_3, datareg0_2, datareg0_1, datareg0_0} <= wb_dat_i[31:0];
//                  case (wb_adr_i)         // synopsys full_case parallel_case
//                      3'b000: {datareg0_3, datareg0_2, datareg0_1, datareg0_0} <= wb_dat_i[31:0];
//                  endcase

            endcase
    // generate dat_o
    always @(posedge clk_i)
        case (wb_sel_i)
            4'b0000:
                case (wb_adr_i)     // synopsys full_case parallel_case
                    3'b000: wb_dat_o[7:0] <= datareg0_0;
                    3'b001: wb_dat_o[7:0] <= datareg0_1;
                    3'b010: wb_dat_o[7:0] <= datareg0_2;
                    3'b011: wb_dat_o[7:0] <= datareg0_3;
                    3'b100: wb_dat_o[7:0] <= datareg1_0;
                    3'b101: wb_dat_o[7:0] <= datareg1_1;
                    3'b110: wb_dat_o[7:0] <= datareg1_2;
                    3'b111: wb_dat_o[7:0] <= datareg1_3;
                endcase
            4'b0001:
                case (wb_adr_i)     // synopsys full_case parallel_case
                    3'b000: wb_dat_o[7:0] <= datareg0_0;
                    3'b001: wb_dat_o[7:0] <= datareg0_1;
                    3'b010: wb_dat_o[7:0] <= datareg0_2;
                    3'b011: wb_dat_o[7:0] <= datareg0_3;
                    3'b100: wb_dat_o[7:0] <= datareg1_0;
                    3'b101: wb_dat_o[7:0] <= datareg1_1;
                    3'b110: wb_dat_o[7:0] <= datareg1_2;
                    3'b111: wb_dat_o[7:0] <= datareg1_3;
                endcase
            4'b0011:
                    wb_dat_o[15:0] <= {datareg0_1, datareg0_0};
            4'b1111:
                    wb_dat_o[31:0] <= {datareg0_3, datareg0_2, datareg0_1, datareg0_0};
        endcase
        
   // generate ack_o
    always @(posedge clk_i)
        wb_ack_o <= #1 wb_acc & !wb_ack_o;

    assign datareg0 = { datareg0_3, datareg0_2, datareg0_1, datareg0_0 };
    assign datareg1 = { datareg1_3, datareg1_2, datareg1_1, datareg1_0 };

endmodule
