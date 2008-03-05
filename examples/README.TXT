//////////////////////////////////////////////////////////////////////
////                                                              ////
////  $Id: README.TXT,v 1.1 2008-03-05 05:58:38 hharte Exp $ 
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

Wishbone LPC Bridge Samples:

1. pci_lpc/ 	PCI to LPC Host Controller using the Enterpoint Raggedstone1 FPGA card.
2. lpc_7seg/	LPC 7-Segment Display Peripheral using the Raggedston1 FPGA card.

To use these example, you will need two Raggedstone1 boards.  The first board is the PCI to LPC host, and the second board is the LPC device.  The two Raggedstone1 cards are connected together by making a short ribbon cable using 16-pin DIP IDC connectors.  The topmost pins of JR1/JR2 is where this cable plugs in.

The LPC bus is pinned out as follows, on JR2:

W1 LPC_CLK
W2 LFRAME#
V5 LAD<0>
U5 LAD<1>
V2 LAD<2>
V1 LAD<3>
U4
T4 LPC_INT (active low, not used by 7-segment peripheral, pulled up in host)

If you only have one Raggedstone1 PCI card, these designs could be combined and run on a single card.
