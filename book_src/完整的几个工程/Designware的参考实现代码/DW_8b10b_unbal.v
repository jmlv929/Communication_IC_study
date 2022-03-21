
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: 8b/10b Unbalance Prediction module
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////
//
// Verilog module: DW_8b10b_unbal
//
// Created by version 1.16 of pla2ver
// From the source files:
//    DW_8b10b_unbal.tbl (defines module name & I/Os)
//    unbal3b4b.pla (submodule: unbal3b4b)
//    unbal5b6b.pla (submodule: unbal5b6b)
//    unbalfinal.pla (submodule: unbalfinal)
//
//  On Fri Aug 27 14:02:48 1999
//
////////////////////////////////////////


module DW_8b10b_unbal
	(
	// inputs
	    k_char,	    // Special Character control input
	    data_in,	    // Input data bus (eight bits)

	// output
	    unbal	    // Predicted unbalance status output

	// Embedded script
	    // set_max_area 0
	    );

parameter k28_5_only = 0;


input k_char;
input [7:0] data_in;
output unbal;


wire unbal4, unbal6;


// Begin submodule 'unbal3b4b'

    // begin product term assignments

    `define pt_1 ( ~data_in[7] & data_in[5])
    `define pt_2 ( data_in[6] & ~data_in[5])
    `define pt_3 ( ~data_in[6] & data_in[5])

    // begin summing assignments

    assign unbal4 = `pt_1 | `pt_2 | `pt_3;

// End submodule 'unbal3b4b'


// Begin submodule 'unbal5b6b'

    // begin product term assignments

    `define pt_4 ( ~k_char & data_in[3] & data_in[2] & ~data_in[1] & ~data_in[0])
    `define pt_5 ( data_in[4] & ~data_in[2] & data_in[1] & ~data_in[0])
    `define pt_6 ( data_in[4] & ~data_in[2] & ~data_in[1] & data_in[0])
    `define pt_7 ( ~data_in[4] & data_in[3] & ~data_in[1] & data_in[0])
    `define pt_8 ( ~data_in[3] & ~data_in[2] & data_in[1] & data_in[0])
    `define pt_9 ( ~data_in[4] & data_in[3] & ~data_in[2] & data_in[1])
    `define pt_10 ( data_in[4] & ~data_in[3] & data_in[2] & ~data_in[0])
    `define pt_11 ( ~data_in[4] & data_in[3] & data_in[2] & ~data_in[0])
    `define pt_12 ( ~data_in[3] & data_in[2] & ~data_in[1] & data_in[0])
    `define pt_13 ( ~data_in[4] & ~data_in[3] & data_in[2] & data_in[1])

    // begin summing assignments

    assign unbal6 = `pt_4 | `pt_5 | `pt_6 | `pt_7 |
			`pt_8 | `pt_9 | `pt_10 | `pt_11 |
			`pt_12 | `pt_13;

// End submodule 'unbal5b6b'


// Begin submodule 'unbalfinal'

    assign unbal = (unbal4 ^ unbal6) | ((k28_5_only==1)? k_char : 1'b0);

// End submodule 'unbalfinal'


endmodule
