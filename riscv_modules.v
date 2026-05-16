module alu(a,b,opc,out,zero);
input [31:0]a,b;input [2:0]opc;
output reg [31:0]out;output reg zero;

always@(*) begin
case(opc) 
3'b000: out=a+b;
3'b001: out=a-b;
3'b010: out=a&b;
3'b011: out=a|b;
default:out=32'b0;
endcase
zero=(out==32'b0 && opc==3'd1)?1'b1:1'b0;
end
endmodule

module reg_file(clk,rst,wr_en,rs1,rs2,rs3,rd,wd,R1,R2,R3);
input clk,rst,wr_en;input [4:0]rs1,rs2,rs3,rd;input [31:0]wd;
output [31:0]R1,R2,R3;
reg [31:0] regs[31:0];integer i;

always@(posedge clk or posedge rst) begin
if(rst) begin 
for(i=0;i<32;i=i+1) regs[i]<=0; 
end
else if(wr_en && rd!=0) regs[rd]<=wd;
end

assign R1=(rs1!=0)?((wr_en&&rd==rs1)?wd:regs[rs1]):32'b0;
assign R2=(rs2!=0)?((wr_en&&rd==rs2)?wd:regs[rs2]):32'b0;
assign R3=(rs3!=0)?((wr_en&&rd==rs3)?wd:regs[rs3]):32'b0;
endmodule

module imm_gen(in,out);
input [31:0]in;
output reg [31:0]out;

always@(*) begin
case(in[6:0])
7'b0010011,7'b0000011: out={{20{in[31]}},in[31:20]};
7'b0100011: out={{20{in[31]}},in[31:25],in[11:7]};
7'b1100011: out={{19{in[31]}},in[31],in[7],in[30:25],in[11:8],1'b0};
default: out=32'b0;
endcase
end
endmodule

module cntrl(opc,regw,memr,memw,alusrc,memreg,branch,aluop,macop);

input [6:0]opc;
output reg regw,memr,memw,alusrc,memreg,branch,macop; output reg [1:0]aluop;

always@(*) begin
regw=0;memr=0;memw=0;alusrc=0;memreg=0;branch=0;macop=0;aluop=2'b00;
case(opc)
7'b0110011: begin regw=1;aluop=2'b10; end
7'b0010011: begin regw=1;alusrc=1; end
7'b0000011: begin regw=1;memr=1;alusrc=1;memreg=1; end
7'b0100011: begin memw=1;alusrc=1; end
7'b1100011: begin branch=1;aluop=2'b01; end
7'b0001011: begin regw=1;macop=1; end
endcase 
end 
endmodule

module alu_cntrl(opc,f3,f7,alu_sel);
input [1:0]opc; input [2:0]f3; input [6:0]f7;
output reg [2:0]alu_sel;

always@(*) begin
case(opc) 
2'b00: alu_sel=0;
2'b01: alu_sel=3'd1;
2'b10: begin
if(f3==0 && f7==0) alu_sel=3'b000;
else if(f3==3'b000 && f7==7'b0100000) alu_sel=3'd1;
else if(f3==3'd7 && f7==7'b0) alu_sel=3'd2;
else if(f3==3'd6 && f7==7'b0) alu_sel=3'd3;
else alu_sel=3'b000;
end
default: alu_sel=3'b000;
endcase
end
endmodule

module pc(clk,rst,pc_in,pc_out);
input clk,rst;input [31:0]pc_in; 
output reg [31:0]pc_out;

always@(posedge clk or posedge rst) begin
if(rst) pc_out<=32'b0;
else pc_out<=pc_in;
end
endmodule

module instr_mem(pc,instr);
input [31:0]pc;
output [31:0]instr;

reg [31:0] mem[255:0];

initial begin
mem[0]  = 32'h00300093; // addi x1, x0, 3
mem[1]  = 32'h00400113; // addi x2, x0, 4
mem[2]  = 32'h00500193; // addi x3, x0, 5

// store & load
mem[3]  = 32'h00302023; // sw x3, 0(x0)
mem[4]  = 32'h00002183; // lw x3, 0(x0)

// dependency chain (hazards)
mem[5]  = 32'h00218233; // add x4, x3, x2
mem[6]  = 32'h401202b3; // sub x5, x4, x1
mem[7]  = 32'h0052f333; // and x6, x5, x5
mem[8]  = 32'h0062e3b3; // or  x7, x5, x6

// MAC (custom)
mem[9]  = 32'h0020818B; // mac x3, x1, x2

// more hazards
mem[10] = 32'h00218233; // add x4, x3, x2
mem[11] = 32'h002202b3; // add x5, x4, x2
mem[12] = 32'h00228333; // add x6, x5, x2

// load-use hazard
mem[13] = 32'h00002183; // lw x3, 0(x0)
mem[14] = 32'h00218233; // add x4, x3, x2

// branch (taken/not taken mix)
mem[15] = 32'h00208463; // beq x1, x2, +8 (not taken)
mem[16] = 32'h0020c463; // beq x1, x2, +8 (not taken)

// more ALU
mem[17] = 32'h00218233; // add x4, x3, x2
mem[18] = 32'h402202b3; // sub x5, x4, x2
mem[19] = 32'h0052f333; // and x6, x5, x5
mem[20] = 32'h0062e3b3; // or  x7, x5, x6

// more MAC + dependency
mem[21] = 32'h0020818B; // mac x3, x1, x2
mem[22] = 32'h00218233; // add x4, x3, x2

// more load-store mix
mem[23] = 32'h00402023; // sw x4, 0(x0)
mem[24] = 32'h00002283; // lw x5, 0(x0)

// chain again
mem[25] = 32'h00228333; // add x6, x5, x2
mem[26] = 32'h402303b3; // sub x7, x6, x2
mem[27] = 32'h0073f433; // and x8, x7, x7
mem[28] = 32'h0083e4b3; // or  x9, x7, x8

// final mix
mem[29] = 32'h0020818B; // mac x3, x1, x2
mem[30] = 32'h00218233; // add x4, x3, x2
mem[31] = 32'h002202b3; // add x5, x4, x2

// stop-like NOPs
mem[32] = 32'h00000013; // nop
mem[33] = 32'h00000013;
mem[34] = 32'h00000013;
end

assign instr=mem[pc[31:2]];
endmodule

module data_mem(clk,rst,memr,memw,addr,wdata,rdata);
input clk,rst,memr,memw; input [31:0]addr,wdata;
output reg [31:0]rdata;

reg [31:0] mem[255:0];
integer i;

always@(posedge clk or posedge rst) begin
if(rst) begin
mem[0]<=5;
for(i=1;i<256;i=i+1) mem[i]<=0;
end
else if(memw) mem[addr[31:2]]<=wdata;
end

always@(*) begin
if(memr) rdata=mem[addr[31:2]];
else rdata=32'b0;
end
endmodule
