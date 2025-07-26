`include "int_cntrl_1.v"
module tb;
parameter NUM_PERIPHS=16;
parameter ADDR_WIDTH=$clog2(NUM_PERIPHS);
parameter DATA_WIDTH=$clog2(NUM_PERIPHS);
parameter PERIPHS_INDEX=$clog2(NUM_PERIPHS);
reg pclk_i,prst_i,pwrite_i,penable_i;
wire pready_o,perror_o;
reg [ADDR_WIDTH-1:0]paddr_i;
reg [DATA_WIDTH-1:0]pwdata_i;
wire [DATA_WIDTH-1:0]prdata_o;
reg int_serviced_i;
wire int_valid_o;
parameter S_IDLE=3'b001;
parameter S_GOT_GIVEN=3'b010;
parameter S_WAITING_TO_SERVICE=3'b100;

wire [PERIPHS_INDEX-1:0]int_to_service_o;
reg [NUM_PERIPHS-1:0]int_active_i;
reg [2:0]state,nxt_state;

integer i;
//int_cntrl dut(pclk_i,prst_i,paddr_i,pwrite_i,pwdata_i,penable_i,prdata_o,pready_o,perror_o,int_serviced_i,int_valid_o,int_to_service_o,int_active_i);
//clk generation
int_cntrl dut(pclk_i,prst_i,paddr_i,pwrite_i,pwdata_i,penable_i,prdata_o,pready_o,perror_o,int_serviced_i,int_valid_o,int_to_service_o,int_active_i,pattern_detector_o);
initial begin
pclk_i=0;
forever #5 pclk_i= ~pclk_i;
end

initial begin
	reset_regA();
	write_regA();
	read_regA();
	//randomly generate interrupts 
	int_active_i = $random; //TB is behaving  like a peripheral controller and raising interrupts
	#100;
	$finish;
end

always @(posedge int_valid_o) begin
	//service the interrupts
	#30; //time taken to service the interrupt
	int_active_i[int_to_service_o] = 0;
	int_serviced_i = 1;
	@(posedge pclk_i);
	int_serviced_i  = 0;
end

//reset condition
task reset_regA();
begin
	prst_i=1;
	paddr_i=0;
	pwrite_i=0;
	pwdata_i=0;
	penable_i=0;
	int_serviced_i=0;
	int_active_i=0;
	@(posedge pclk_i);
	prst_i=0;
end
endtask

//write condition
task write_regA();
begin
	//write all the locations with a random state
	for(i=0;i<NUM_PERIPHS; i=i+1) begin
		@(posedge pclk_i);
		paddr_i=i;
		//pwdata_i=i;
		pwdata_i=NUM_PERIPHS-i;
		pwrite_i=1;
		penable_i=1;
		wait (pready_o==1);
	end
		@(posedge pclk_i);
		paddr_i=0;          
		pwdata_i=0;
		pwrite_i=0;
		penable_i=0;
end
endtask

//read logic
task read_regA();
begin
	for(i=0;i<NUM_PERIPHS;i=i+1) begin
	@(posedge pclk_i);
	paddr_i=i;
	pwrite_i=0;
	penable_i=1;
	wait(pready_o==1 );
	end
	@(posedge pclk_i);
	paddr_i=0;
	penable_i=0;
	pwrite_i=0;
end
endtask
endmodule
