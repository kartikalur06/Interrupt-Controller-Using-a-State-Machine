module int_cntrl(pclk_i,prst_i,paddr_i,pwrite_i,pwdata_i,penable_i,prdata_o,pready_o,perror_o,int_serviced_i,int_valid_o,int_to_service_o,int_active_i,pattern_detector_o);
parameter NUM_PERIPHS=16;
parameter ADDR_WIDTH=$clog2(NUM_PERIPHS);
parameter DATA_WIDTH=$clog2(NUM_PERIPHS);
parameter PERIPHS_INDEX=$clog2(NUM_PERIPHS);
//parameters of state machine
parameter S_IDLE=3'b001;
parameter S_GOT_GIVEN=3'b010;
parameter S_WAITING_TO_SERVICE=3'b100;

input pclk_i,prst_i,pwrite_i,penable_i;
output reg pready_o,perror_o;	
input [ADDR_WIDTH-1:0]paddr_i;
input [DATA_WIDTH-1:0]pwdata_i;
output reg [DATA_WIDTH-1:0]prdata_o;
input int_serviced_i;
output reg int_valid_o;
output reg [PERIPHS_INDEX-1:0]int_to_service_o;
input [NUM_PERIPHS-1:0]int_active_i;
integer i;
output reg pattern_detector_o;
reg [PERIPHS_INDEX-1:0] priority_regA[NUM_PERIPHS-1:0];
reg [2:0]state,nxt_state;
reg first_match_f;
reg [PERIPHS_INDEX-1:0]int_with_highest_priority;
reg [PERIPHS_INDEX-1:0]current_highest_priority;


//rst applied
always @(posedge pclk_i) begin
if (prst_i==1) begin
	prdata_o=0;
	pready_o=0;
	perror_o=0;
	int_valid_o=0;
	int_to_service_o=0;
	first_match_f = 1;
	state=S_IDLE;
	nxt_state=S_IDLE;
	int_with_highest_priority = 0;
	current_highest_priority = -1;
	for(i=0;i<NUM_PERIPHS;i=i+1) begin
	priority_regA[i]=0;
	end
end
//write to the interrupt registers
else begin
	if(penable_i==1) begin
		pready_o=1;
		if(pwrite_i==1) begin
		//store the wdata port value into register at addr location 
		priority_regA[paddr_i]=pwdata_i;
		end
		else begin
		//get the data from register at addr location drive it to the rdata port
		prdata_o=priority_regA[paddr_i];
		end
	end
	else begin
	pready_o=0;
	end
end
end

//state machine {implement the logic interrrupts in the design using state machines}
//implement thee logic for handling the interrupts in the design
	//S_IDLE
	//S_GOT_GIVEN_INTR
	//WAITING_TO_SERVICE
always @ (posedge pclk_i) begin
	if(prst_i==1) begin
	pattern_detector_o=0;
//	state=S_IDLE;
//	nxt_state=S_IDLE;
	end
	else begin
	if (penable_i==1) begin
		case (state)
		S_IDLE : begin
			if(int_active_i != 0) begin
				nxt_state=S_GOT_GIVEN;
				first_match_f = 1;
				current_highest_priority = -1;
			end
		end
		S_GOT_GIVEN : begin
			//find the highest priority peripheral amoung all active interrpts
			//with first_match_flag
			for (i=0; i<NUM_PERIPHS; i=i+1) begin
				if(int_active_i[i] == 1) begin
					if(first_match_f == 1) begin
						first_match_f = 0;
						current_highest_priority = priority_regA[i];
						int_with_highest_priority = i;
					end
			//without first_match_f
					else begin
					if(current_highest_priority < priority_regA[i]) begin
					current_highest_priority = priority_regA[i];
					int_with_highest_priority = i;
					end
				end
			end
		end
			int_to_service_o = int_with_highest_priority;
			int_valid_o = 1;
			nxt_state=S_WAITING_TO_SERVICE;
		end
		S_WAITING_TO_SERVICE : begin
			if(int_serviced_i==1) begin
				current_highest_priority = -1;
				int_to_service_o =0;
				int_valid_o = 0;	
				if(int_active_i != 0) begin
					nxt_state=S_GOT_GIVEN;
					first_match_f= 1;
				end 
				else begin
				nxt_state=S_IDLE;
				end
			end
			else nxt_state = S_WAITING_TO_SERVICE;
		end
	endcase
	end
end
end
always @(nxt_state) state=nxt_state;
endmodule
