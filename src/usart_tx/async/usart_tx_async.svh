function automatic logic async_tx(
	input logic [7:0] latched_data, 
	input logic [2:0] bit_index, 
	input usart_state_t current_state
);
	case (current_state)
		FSM_IDLE: begin
			return STOP_BIT;
		end
		FSM_START: begin
			return START_BIT;
		end
		FSM_DATA: begin
			return latched_data[bit_index];
		end
		FSM_PARITY: begin
			case (PARITY)
				EVEN: begin
					return ^latched_data;
				end
				ODD: begin
					return ~^latched_data;
				end
			endcase
		end
		FSM_STOP: begin
			return STOP_BIT;
		end
	endcase
endfunction

function automatic usart_state_t async_mode_state_machine(
	input logic [2:0] bit_index, 
	input [7:0] data_bit_count, 
	input parity_config_t parity,
	input usart_state_t current_state, 
	input logic transmit_flag, 
	output logic ready_flag, 
	output logic fast_trigger
);

	ready_flag = '0;
	fast_trigger = '0;

	case (current_state)
			FSM_IDLE: begin
				ready_flag = 1'b1;
				if (transmit_flag == 1'b1) begin
					fast_trigger = 1'b1;
					ready_flag = '0;
					return FSM_START;
				end else begin
					return FSM_IDLE;
				end
			end
			FSM_START: begin
				return FSM_DATA;
			end
			FSM_DATA: begin
				if (bit_index == data_bit_count - 1) begin
					case (parity)
						NONE: begin
							return FSM_STOP;
						end
						default: begin
							return FSM_PARITY;
						end
					endcase
				end
				return FSM_DATA;
			end
			FSM_PARITY: begin
				return FSM_STOP;
			end
			FSM_STOP: begin
				return FSM_IDLE;
			end
		endcase
endfunction