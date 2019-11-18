//
// Minimal 8 Bit CPU
//
// 01-02/2001 Tim B"oscke
// 10   /2001 changed to synch. reset
// 10   /2004 Verilog version, unverified!
//
// t.boescke@tuhh.d
// 
// Modified by Ben Hencke 2019-11-18  to avoid inout types, dedicated rdata, wdata
// (probably uses more cells, but works on the OSS FPGA tools)


module mcpu(rdata,wdata,adress,oe,we,rst,clk);

inout [7:0] rdata;
output [7:0] wdata;

output [5:0] adress;
output oe;
output we;
input rst;
input clk;

reg [8:0] accumulator; // accumulator(8) is carry !
reg [5:0] adreg;
reg [5:0] pc;
reg [2:0] states;

initial begin
	$display("time, state, adreg, pc, rst, clk, wdata, adress, oe");
	$monitor($stime,",states=",states, ", adreg=", adreg, ",pc=", pc, ",rst=", rst,",clk=",clk,",data=",wdata,",address=",adress,",oe =",oe); 
end

	always @(posedge clk)
		if (~rst) begin
			adreg 	  <= 0;
			states	  <= 0;
			accumulator <= 0;	
			pc <= 0;
		end
		else begin
			// PC / Address path
			if (~|states) begin
				pc	 <= adreg + 1'b1;
				adreg <= rdata[5:0];  // was adreg <=pc, aw fix.
			end
			else adreg <= pc;
		
			// ALU / Data Path
			case(states)
				3'b010 : accumulator 	 <= {1'b0, accumulator[7:0]} + {1'b0, rdata}; // add
				3'b011 : accumulator[7:0] <= ~(accumulator[7:0]|rdata); // nor
				3'b101 : accumulator[8]   <= 1'b0; // branch not taken, clear carry					   
			endcase							// default:  instruction fetch, jcc taken

			// State machine
			if (|states) states <= 0;
			else begin 
				if ( &rdata[7:6] && accumulator[8] ) states <= 3'b101;
				else states <= {1'b0, ~rdata[7:6]};
			end
		end
// output
assign adress = adreg;
assign wdata   = accumulator[7:0]; 
assign oe     = clk | ~rst | states==3'b001 | states==3'b101 ; 
assign we     = clk | ~rst | (states!=3'b001) ; 

endmodule
