module lvds_rx (
	input	[0:0]  rx_in,
	input	  rx_inclock,
	output	[7:0]  rx_out,
	output	  rx_outclock
);
endmodule

module lvds_tx (
	input	[7:0]  tx_in,
	input	  tx_inclock,
	output	[0:0]  tx_out,
	output	  tx_outclock
);
endmodule


