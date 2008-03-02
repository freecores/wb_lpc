//////////////////////////////////////////////////////////////////////
////                                                              ////
////  $Id: wb_lpc_periph.v,v 1.1 2008-03-02 20:46:40 hharte Exp $
////  wb_lpc_periph.v - LPC Peripheral to Wishbone Master Bridge  ////
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

`timescale 1 ns / 1 ns

`include "../../rtl/verilog/wb_lpc_defines.v"

//					I/O Write		I/O Read			DMA Read			DMA Write
//															
//	States - 1. H Start			H Start			H Start			H Start
//				2. H CYCTYPE+DIR	H CYCTYPE+DIR	H CYCTYPE+DIR	H CYCTYPE+DIR
//				3. H Addr (4)		H Addr (4)		H CHAN+TC		H CHAN+TC
//															H SIZE			H SIZE
//				4. H Data (2)		H TAR  (2)	 +-H DATA (2)		H TAR  (2)
//				5. H TAR  (2)		P SYNC (1+)	 |	H TAR  (2)	 +-P SYNC (1+)
//				6. P SYNC (1+)		P DATA (2)	 | H SYNC (1+)	 +-P DATA (2)
//				7. P TAR  (2)		P TAR  (2)	 +-P TAR  (2)		P TAR
//															

module wb_lpc_periph(clk_i, nrst_i, wbm_adr_o, wbm_dat_o, wbm_dat_i, wbm_sel_o, wbm_tga_o, wbm_we_o,
						   wbm_stb_o, wbm_cyc_o, wbm_ack_i,
							dma_chan_o, dma_tc_o,
						   lframe_i, lad_i, lad_o, lad_oe
);

	// Wishbone Master Interface
	input			clk_i;
	input 		nrst_i;
	output reg 	[31:0] wbm_adr_o;
	output reg  [31:0] wbm_dat_o;
  	input 		[31:0] wbm_dat_i;
	output reg	[3:0] wbm_sel_o;
	output reg	[1:0] wbm_tga_o;
  	output reg	wbm_we_o;
	output reg	wbm_stb_o;
	output reg	wbm_cyc_o;
	input			wbm_ack_i;

	// LPC Slave Interface
	input			lframe_i;			// LPC Frame input (active high)
	output reg	lad_oe;				// LPC AD Output Enable
	input			[3:0]	lad_i;		// LPC AD Input Bus
	output reg	[3:0] lad_o;		// LPC AD Output Bus

	// DMA-Specific sideband signals
	output		[2:0]	dma_chan_o;	// DMA Channel
	output				dma_tc_o;	// DMA Terminal Count

	reg	[12:0] state;				// Current state
	reg	[2:0] adr_cnt;				// Address nibbe counter
	reg	[3:0] dat_cnt;				// Data nibble counter
	wire	[2:0] byte_cnt = dat_cnt[3:1];	// Byte counter
 	wire			nibble_cnt = dat_cnt[0];	// Nibble counter

	reg	[31:0] lpc_dat_i;			// Temporary storage for input data.
	reg 	[3:0] start_type;			// Type of LPC start cycle
	reg			mem_xfr;				// LPC Memory Transfer (not I/O)
	reg			dma_xfr;				// LPC DMA Transfer
	reg			fw_xfr;				// LPC Firmware memory read/write
	reg 	[2:0] xfr_len;				// Number of nibbls for transfer
	reg			dma_tc;				// DMA Terminal Count
	reg	[2:0]	dma_chan;			// DMA Channel

	assign dma_chan_o = dma_chan;
	assign dma_tc_o = dma_tc;
	
	always @(posedge clk_i or negedge nrst_i)
		if(~nrst_i)
		begin
			state <= `LPC_ST_IDLE;
			wbm_adr_o <= 16'h0000;
			wbm_dat_o <= 32'h00000000;
			wbm_sel_o <= 4'b0000;
			wbm_tga_o <= `WB_TGA_MEM;
			wbm_we_o <= 1'b0;
			wbm_stb_o <= 1'b0;
			wbm_cyc_o <= 1'b0;
			lad_oe <= 1'b0;
			lad_o <= 8'hFF;
			lpc_dat_i <= 32'h00;
			start_type <= 4'b0000;
			wbm_tga_o <= `WB_TGA_MEM;
			mem_xfr <= 1'b0;
			dma_xfr <= 1'b0;
			fw_xfr <= 1'b0;
			xfr_len <= 3'b000;
			dma_tc <= 1'b0;
			dma_chan <= 3'b000;
		end
		else begin
			case(state)
				`LPC_ST_IDLE:
					begin
						dat_cnt <= 4'h0;
						if(lframe_i)
							begin
								start_type <= lad_i;
								wbm_sel_o <= 4'b0000;
								wbm_stb_o <= 1'b0;
								wbm_cyc_o <= 1'b0;
								lad_oe <= 1'b0;
								xfr_len <= 3'b001;
								
								if(lad_i == `LPC_START) begin
									state <= `LPC_ST_CYCTYP;
									wbm_we_o <= 1'b0;
									fw_xfr <= 1'b0;									
								end
								else if (lad_i == `LPC_FW_READ) begin
									state <= `LPC_ST_ADDR;
									wbm_we_o <= 1'b0;
									adr_cnt <= 3'b000;
									fw_xfr <= 1'b1;
									wbm_tga_o <= `WB_TGA_FW;
								end
								else if (lad_i == `LPC_FW_WRITE) begin
									state <= `LPC_ST_ADDR;
									wbm_we_o <= 1'b1;
									adr_cnt <= 3'b000;
									fw_xfr <= 1'b1;
									wbm_tga_o <= `WB_TGA_FW;
								end
								else
									state <= `LPC_ST_IDLE;
							end
						else
							state <= `LPC_ST_IDLE;
					end
				`LPC_ST_CYCTYP:
					begin
						wbm_we_o <= (lad_i[3] ? ~lad_i[1] : lad_i[1]);	// Invert we_o if we are doing DMA.
						mem_xfr <= lad_i[2];
						dma_xfr <= lad_i[3];
						adr_cnt <= (lad_i[2] ? 3'b000 : 3'b100);
						if(lad_i[3]) // dma_xfr)
							wbm_tga_o <= `WB_TGA_DMA;
						else if(lad_i[2]) //mem_xfr)
							wbm_tga_o <= `WB_TGA_MEM;
						else
							wbm_tga_o <= `WB_TGA_IO;
						
						if(lad_i[3]) //dma_xfr)
							begin
								state <= `LPC_ST_CHAN;
							end
						else
							begin
								state <= `LPC_ST_ADDR;
							end
					end
				`LPC_ST_ADDR:
					begin
						case(adr_cnt)
							3'h0:
								wbm_adr_o[31:28] <= lad_i;
							3'h1:
								wbm_adr_o[27:24] <= lad_i;
							3'h2:
								wbm_adr_o[23:20] <= lad_i;
							3'h3:
								wbm_adr_o[19:16] <= lad_i;
							3'h4:
								wbm_adr_o[15:12] <= lad_i;
							3'h5:
								wbm_adr_o[11:8] <= lad_i;
							3'h6:
								wbm_adr_o[7:4] <= lad_i;
							3'h7:
								wbm_adr_o[3:0] <= lad_i;
						endcase
						
						adr_cnt <= adr_cnt + 1;
						
						if(adr_cnt == 3'h7) // Last address nibble.
							begin
								if(~fw_xfr)
									if(wbm_we_o)
										state <= `LPC_ST_H_DATA;
									else
										state <= `LPC_ST_H_TAR1;
								else	// For firmware read/write, we need to read the MSIZE nibble
									state <= `LPC_ST_SIZE;
							end
						else
							state <= `LPC_ST_ADDR;
					end
				`LPC_ST_CHAN:
					begin
						wbm_adr_o <= 32'h00000000;		// Address lines not used for DMA.
						dma_tc <= lad_i[3];
						dma_chan <= lad_i[2:0];
						state <= `LPC_ST_SIZE;
					end
				`LPC_ST_SIZE:
					begin
						case(lad_i)
							4'h0:
								begin
									xfr_len <= 3'b001;
									wbm_sel_o <= `WB_SEL_BYTE;
								end
							4'h1:
								begin
									xfr_len <= 3'b010;
									wbm_sel_o <= `WB_SEL_SHORT;
								end
							4'h2:			// Firmware transfer uses '2' for 4-byte transfer.
								begin
									xfr_len <= 3'b100;
									wbm_sel_o <= `WB_SEL_WORD;
								end
							4'h3:			// DMA uses '3' for 4-byte transfer.
								begin
									xfr_len <= 3'b100;
									wbm_sel_o <= `WB_SEL_WORD;
								end
							default:
								begin
									xfr_len <= 3'b001;
									wbm_sel_o <= 4'b0000;
								end
						endcase
						if(wbm_we_o)
							state <= `LPC_ST_H_DATA;
						else
							state <= `LPC_ST_H_TAR1;
					end
				`LPC_ST_H_DATA:
					begin
						case(dat_cnt)
							4'h0:
								wbm_dat_o[3:0] <= lad_i;
							4'h1:
								wbm_dat_o[7:4] <= lad_i;
							4'h2:
								wbm_dat_o[11:8] <= lad_i;
							4'h3:
								wbm_dat_o[15:12] <= lad_i;
							4'h4:
								wbm_dat_o[19:16] <= lad_i;
							4'h5:
								wbm_dat_o[23:20] <= lad_i;
							4'h6:
								wbm_dat_o[27:24] <= lad_i;
							4'h7:
								wbm_dat_o[31:28] <= lad_i;
						endcase
						
						dat_cnt <= dat_cnt + 1;
						
						if(nibble_cnt == 1'b1) // end of byte
							begin
								state <= `LPC_ST_H_TAR1;
							end
						else
							state <= `LPC_ST_H_DATA;
		
					end
		
				`LPC_ST_H_TAR1:
					begin
						if(((byte_cnt == xfr_len) & wbm_we_o) | ((byte_cnt == 0) & ~wbm_we_o))
						begin
							wbm_stb_o <= 1'b1;
							wbm_cyc_o <= 1'b1;
						end
						state <= `LPC_ST_H_TAR2;
					end
				`LPC_ST_H_TAR2:
					begin
						state <= `LPC_ST_SYNC;
						lad_oe <= 1'b1;		// start driving LAD
						lad_o <= `LPC_SYNC_SWAIT;
					end
				`LPC_ST_SYNC:
					begin
						lad_oe <= 1'b1;		// start driving LAD
						if(((byte_cnt == xfr_len) & wbm_we_o) | ((byte_cnt == 0) & ~wbm_we_o)) begin
							if(wbm_ack_i)
								begin
									lad_o <= `LPC_SYNC_READY;	// Ready
									wbm_stb_o <= 1'b0;	// End Wishbone cycle.
									wbm_cyc_o <= 1'b0;
									if(wbm_we_o)
										state <= `LPC_ST_P_TAR1;
									else
										begin
											lpc_dat_i <= wbm_dat_i[31:0];
											state <= `LPC_ST_P_DATA;
										end
								end
							else
								begin
									state <= `LPC_ST_SYNC;
									lad_o <= `LPC_SYNC_SWAIT;
								end
							end
						else begin	// Multi-byte transfer, just ack right away.
							lad_o <= `LPC_SYNC_READY;	// Ready
							if(wbm_we_o)
								state <= `LPC_ST_P_TAR1;
							else
								state <= `LPC_ST_P_DATA;
							end
						end
		
				`LPC_ST_P_DATA:
					begin
						case(dat_cnt)
							4'h0:
								lad_o <= lpc_dat_i[3:0];
							4'h1:
								lad_o <= lpc_dat_i[7:4];
							4'h2:
								lad_o <= lpc_dat_i[11:8];
							4'h3:
								lad_o <= lpc_dat_i[15:12];
							4'h4:
								lad_o <= lpc_dat_i[19:16];
							4'h5:
								lad_o <= lpc_dat_i[23:20];
							4'h6:
								lad_o <= lpc_dat_i[27:24];
							4'h7:
								lad_o <= lpc_dat_i[31:28];
						endcase
						
						dat_cnt <= dat_cnt + 1;
						
//						if(nibble_cnt == 1'b1)
//							state <= `LPC_ST_P_TAR1;
		
						if(nibble_cnt == 1'b1)	// Byte transfer complete
							if (byte_cnt == xfr_len-1) // Byte transfer complete
								state <= `LPC_ST_P_TAR1;
							else
								state <= `LPC_ST_SYNC;
						else
							state <= `LPC_ST_P_DATA;
		
						lad_oe <= 1'b1;
					end
				`LPC_ST_P_TAR1:
					begin
						lad_oe <= 1'b1;
						lad_o <= 4'hF;
						state <= `LPC_ST_P_TAR2;
					end
				`LPC_ST_P_TAR2:
					begin
						lad_oe <= 1'b0;		// float LAD
						if(byte_cnt == xfr_len) begin
							state <= `LPC_ST_IDLE;
						end
						else begin
							if(wbm_we_o) begin	// DMA READ (Host to Peripheral)
								state <= `LPC_ST_P_WAIT1;
							end
							else begin	// unhandled READ case
								state <= `LPC_ST_IDLE;
							end
						end

					end
					`LPC_ST_P_WAIT1:
							state <= `LPC_ST_H_DATA;
			endcase
		end

endmodule

							