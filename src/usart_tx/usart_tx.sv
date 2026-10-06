import usart_types_pkg::*;

module usart_tx #(
	parameter int 				BAUD_RATE 	= 9600,
	parameter parity_config_t 	PARITY 		= NONE,
	parameter logic [3:0]		DATA_BIT_COUNT 	= 8,
	parameter usart_clock_polarity_t 	CLOCK_POLARITY = CPOL_0,
	parameter usart_clock_phase_t		CLOCK_PHASE = CPHA_0,
	parameter usart_mode_t 		TRANSMITTER_MODE = ASYNCHRONOUS_UART,
	parameter int 				CLOCK_FREQ 	= 2080000,
	parameter int				CHIP_SELECT_COUNT = 0
) (
	input logic 				clock_i,
	input logic 				reset_n_i,
	input logic 				module_enable_i,
	input logic 				transmit_flag_i,
	input logic [7:0] 			data_byte_i,
	input logic [$clog2(CHIP_SELECT_COUNT):0]	chip_index,

	output logic				usart_tx_o,
	output logic				usart_tx_clock_o,
	output logic [$clog2(CHIP_SELECT_COUNT):0]	chip_select_registers_o,
	output logic 				ready_flag_o
);

logic [7:0] latched_data_byte;
logic [2:0] bit_index;
logic start_fast_trigger;

logic enable_sync_clock_driver;

logic previous_usart_tx_clock;

usart_state_t usart_state;
usart_state_t next_usart_state;

logic sync_clock_override;

logic sync_clock_rising_edge;

logic baud_tick;
logic sync_clock_tick;

`include "util/usart_tx_util_pkg.svh"
`include "async/usart_tx_async.svh"
`include "util/usart_tx_sync.svh"
//`include "legacy/usart_tx_legacy.svh"
//`include "spi/usart_tx_spi.svh"

timer #(
	.MAIN_CLOCK_FREQ(CLOCK_FREQ),
	.TARGET_FREQ(BAUD_RATE)
) baud_rate_ticker (
	.clock_i(clock_i),
	.reset_n_i(reset_n_i),
	.enable_i(~ready_flag_o),
	.tick_o(baud_tick)
);

timer #(
	.MAIN_CLOCK_FREQ(CLOCK_FREQ),
	.TARGET_FREQ(BAUD_RATE * 2)
) sync_clock_ticker (
	.clock_i(clock_i),
	.reset_n_i(reset_n_i),
	.enable_i(~ready_flag_o),
	.tick_o(sync_clock_tick),
	.previous_state_o(previous_usart_tx_clock)
);

always_comb begin
	sync_clock_rising_edge = is_rising_edge(
		.old_value(sync_clock_rising_edge), 
		.previous_state(previous_usart_tx_clock), 
		.current_state(usart_tx_clock_o)
		);

	next_usart_state = usart_state;

	case (TRANSMITTER_MODE)
		ASYNCHRONOUS_UART: begin
			next_usart_state = async_mode_state_machine(
				.bit_index(bit_index),
				.data_bit_count(DATA_BIT_COUNT),
				.parity(PARITY),
				.current_state(usart_state),
				.transmit_flag(transmit_flag_i),
				.ready_flag(ready_flag_o),
				.fast_trigger(start_fast_trigger)
			);
		end
		LEGACY_SYNCHRONOUS: begin
			//legacy_sync_mode_state_machine();
		end
		SPI_MASTER_SYNCHRONOUS: begin
		end
	endcase
end

always_ff @(posedge clock_i) begin
	// RESET CONDITION
	if (usart_state == FSM_IDLE) usart_tx_clock_o <= set_clock_polarity_during_state(usart_tx_clock_o, CLOCK_POLARITY);
	if (!reset_n_i) begin
		initialize_on_reset();
	end else begin
		if (module_enable_i) begin
			latched_data_byte <= latch_data_on_state(
				.old_data(latched_data_byte), 
				.new_data(data_byte_i), 
				.current_state(usart_state), 
				.target_state(FSM_START)
				);

			//synchronous_clock_driver();
			case (TRANSMITTER_MODE)
				LEGACY_SYNCHRONOUS: begin
					//legacy_sync_usart_branch();
				end
				SPI_MASTER_SYNCHRONOUS: begin
				end
			endcase

			if (!ready_flag_o) begin
				// async uart
				case (TRANSMITTER_MODE)
					ASYNCHRONOUS_UART: begin
						async_usart_branch();
					end
				endcase
			end
		end
	end
end

// ALWAYS_FF FUNCTIONS

function automatic void initialize_on_reset();
	usart_state <= FSM_IDLE;
	bit_index <= '0;
	latched_data_byte <= '0;
	usart_tx_o <= 1'd1;
	usart_tx_clock_o <= '0;
	chip_select_registers_o <= '{default:1'd1};
endfunction

function automatic void async_usart_branch();
	if (!baud_tick && start_fast_trigger != 1'd1) begin
		usart_tx_o <= async_tx(
			.latched_data(latched_data_byte),
			.bit_index(bit_index),
			.current_state(usart_state)
		);
	end	else begin
		usart_state <= state_transition(
			.new_state(next_usart_state)
		);
		bit_index <= bit_index_handler(
			.old_bit_index(bit_index), 
			.limit(DATA_BIT_COUNT), 
			.current_state(usart_state), 
			.target_state(FSM_DATA)
		);

	end
endfunction

function automatic void legacy_sync_usart_branch();
	if (!sync_clock_tick) begin
		//legacy_synchronous_tx();
	end else begin
		usart_state <= state_transition(next_usart_state);
		bit_index <= bit_index_handler(
			.old_bit_index(bit_index),
			.limit(DATA_BIT_COUNT), 
			.current_state(usart_state), 
			.target_state(FSM_DATA)
			);
	end
endfunction

function automatic void spi_master_usart_branch();
endfunction

endmodule
