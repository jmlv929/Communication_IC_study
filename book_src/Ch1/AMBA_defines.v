`define HTRANS_IDLE         2'b00
`define HTRANS_BUSY         2'b01
`define HTRANS_NONSEQ       2'b10
`define HTRANS_SEQ          2'b11

`define HRESP_OK            1'b0
`define HRESP_ERROR         1'b1

`define HBURST_SINGLE       3'b000
`define HBURST_INCR         3'b001
`define HBURST_WRAP4        3'b010
`define HBURST_INCR4        3'b011
`define HBURST_WRAP8        3'b100
`define HBURST_INCR8        3'b101
`define HBURST_WRAP16       3'b110
`define HBURST_INCR16       3'b111

`define HSIZE_BYTE          3'b000
`define HSIZE_HALFWORD      3'b001
`define HSIZE_WORD          3'b010

`define HPROT_DEFAULT       4'b0011
