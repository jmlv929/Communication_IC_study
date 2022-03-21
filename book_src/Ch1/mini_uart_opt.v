// pci 1553b core verilog
// Author: Mr Li Qinghua
// uart Rev.0.1 2011-11-08

// 
module mini_uart_opt(
    input clk, // The master clock for this module
    input rst, // Synchronous reset.
    input rx, // Incoming serial line
    output tx, // Outgoing serial line
    input transmit, // Signal to transmit
    input [7:0] tx_byte, // Byte to transmit
    output received, // Indicated that a byte has been received.
    output [7:0] rx_byte, // Byte received
    output is_receiving, // Low when receive line is idle.
    output is_transmitting, // Low when transmit line is idle.
    output recv_error // Indicates error in receiving packet.
    );
parameter CLOCK_DIVIDE = 1302; // clock rate (50Mhz) / (baud rate (9600) * 4)
parameter SAMPLE_N=4;

localparam RX_IDLE = 0;
localparam RX_CHECK_START = 1;
localparam RX_READ_BITS = 2;
localparam RX_CHECK_STOP = 3;
localparam RX_DELAY_RESTART = 4;
localparam RX_ERROR = 5;
localparam RX_RECEIVED = 6;
localparam TX_IDLE = 0;
localparam TX_SENDING = 1;
localparam TX_DELAY_RESTART = 2;

reg [10:0] rx_clk_divider = CLOCK_DIVIDE;
reg [10:0] tx_clk_divider = CLOCK_DIVIDE;

reg [2:0] recv_state = RX_IDLE;
reg [5:0] rx_countdown;
reg [3:0] rx_bits_remaining;
reg [7:0] rx_data;

reg tx_out = 1'b1;
reg [1:0] tx_state = TX_IDLE;
reg [5:0] tx_countdown;
reg [3:0] tx_bits_remaining;
reg [7:0] tx_data;

assign received = recv_state == RX_RECEIVED;
assign recv_error = recv_state == RX_ERROR;
assign is_receiving = recv_state != RX_IDLE;
assign rx_byte = rx_data;

assign tx = tx_out;
assign is_transmitting = tx_state != TX_IDLE;

always @(posedge clk) begin
	if (rst)begin
		recv_state <= RX_IDLE;
		rx_clk_divider<=CLOCK_DIVIDE;
		rx_countdown <= SAMPLE_N;
		rx_bits_remaining <= 8;
	end
	else begin
		if (!rx_clk_divider) begin
			rx_clk_divider <= CLOCK_DIVIDE;
			rx_countdown <= rx_countdown - 1;
		end
		else
			rx_clk_divider <= rx_clk_divider - 1;

		case (recv_state)
			RX_IDLE: begin
				// A low pulse on the receive line indicates the start of data.
				if (!rx) begin
					// Wait half the period - should resume in the middle of this first pulse.
					rx_clk_divider <= CLOCK_DIVIDE;
					rx_countdown <= SAMPLE_N/2;
					recv_state <= RX_CHECK_START;
				end
			end
			RX_CHECK_START: begin
				if (!rx_countdown) begin
					// Check the pulse is still there
					if (!rx) begin
						// Pulse still there - good
						// Wait the bit period to resume half-way
						// through the first bit.
						rx_countdown <= SAMPLE_N;
						rx_bits_remaining <= 8;
						recv_state <= RX_READ_BITS;
					end else begin
						// Pulse lasted less than half the period -
						// not a valid transmission.
						recv_state <= RX_ERROR;
					end
				end
			end
			RX_READ_BITS: begin
				if (!rx_countdown) begin
					// Should be half-way through a bit pulse here.
					// Read this bit in, wait for the next if we
					// have more to get.
					rx_data <= {rx, rx_data[7:1]};
					rx_countdown <= SAMPLE_N;
					rx_bits_remaining <= rx_bits_remaining - 1;
					recv_state <= rx_bits_remaining ? RX_READ_BITS : RX_CHECK_STOP;
				end
			end
			RX_CHECK_STOP: begin
				if (!rx_countdown) begin
					// Should resume half-way through the stop bit
					// This should be high - if not, reject the
					// transmission and signal an error.
					recv_state <= rx ? RX_RECEIVED : RX_ERROR;
				end
			end
			RX_DELAY_RESTART: begin
				// Waits a set number of cycles before accepting
				// another transmission.
				recv_state <= rx_countdown ? RX_DELAY_RESTART : RX_IDLE;
			end
			RX_ERROR: begin
				// There was an error receiving.
				// Raises the recv_error flag for one clock
				// cycle while in this state and then waits
				// 2 bit periods before accepting another
				// transmission.
				rx_countdown <= 2*SAMPLE_N;
				recv_state <= RX_DELAY_RESTART;
			end
			RX_RECEIVED: begin
				// Successfully received a byte.
				// Raises the received flag for one clock
				// cycle while in this state.
				recv_state <= RX_IDLE;
			end
		endcase
	end	
end

always @(posedge clk) begin
	if (rst) begin
		tx_state <= TX_IDLE;
    tx_out <= 1;
    tx_bits_remaining <= 8;
	end

	// Transmit state machine
	case (tx_state)
		TX_IDLE: begin
			if (transmit) begin
				tx_data <= tx_byte;
				tx_out <= 0;
				tx_bits_remaining <= 8;
				tx_state <= TX_SENDING;
			end
		end
		TX_SENDING: begin
			if (!tx_countdown) begin
				if (tx_bits_remaining) begin
					tx_bits_remaining <= tx_bits_remaining - 1;
					tx_data <= {1'b0, tx_data[7:1]};
					tx_out <= tx_data[0];
					tx_state <= TX_SENDING;
				end else begin
					// Set delay to send out 2 stop bits.
					tx_out <= 1;
					tx_state <= TX_DELAY_RESTART;
				end
			end
		end
		TX_DELAY_RESTART: begin
			// Wait until tx_countdown reaches the end before
			// we send another transmission. This covers the
			// "stop bit" delay.
			tx_state <= tx_countdown ? TX_DELAY_RESTART : TX_IDLE;
		end
	endcase
end

always @(posedge clk)
	if (rst) begin
		tx_clk_divider = CLOCK_DIVIDE;
    tx_countdown <= SAMPLE_N;
	end
	else begin	
		if(tx_state==	TX_IDLE&& transmit) begin
 			tx_countdown <= SAMPLE_N;
		end
		if(tx_state==TX_SENDING && !tx_countdown) begin
		  if (tx_bits_remaining)
		  	tx_countdown <= SAMPLE_N;
		  else
		  	tx_countdown <= 2*SAMPLE_N;
		end
		
		if(tx_state==	TX_IDLE&& transmit||!tx_clk_divider) begin
 			tx_clk_divider <= CLOCK_DIVIDE;
 			
			if(!tx_countdown)
			  tx_countdown <= SAMPLE_N;
			else
			  tx_countdown <= tx_countdown - 1;
		end else 
		  tx_clk_divider = tx_clk_divider - 1;
		
	end

endmodule