function automatic logic [7:0] bit_index_handler(
	input logic [7:0] old_bit_index, 
	input logic [7:0] limit, 
	input usart_state_t current_state, 
	input usart_state_t target_state
);
	case (current_state)
		target_state: begin
			if (old_bit_index < limit) return old_bit_index + 1'd1;
		end
		default: begin
			if (old_bit_index == limit) return '0;
		end
	endcase
	return old_bit_index;
endfunction

function automatic logic [7:0] latch_data_on_state(
	input logic [7:0] old_data, 
	input logic [7:0] new_data, 
	input usart_state_t current_state, 
	input usart_state_t target_state
);
	if (current_state == target_state) begin
		return new_data;
	end
	return old_data;
endfunction

function automatic usart_state_t state_transition(
	input usart_state_t new_state
);
	return new_state;
endfunction