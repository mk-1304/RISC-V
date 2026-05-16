module riscv1(clk,rst);
input clk,rst;

wire [31:0]pc,pcp4,pc_next;wire pcsrc;
wire [4:0]rs1,rs2,rd;
wire [31:0]R1,R2,R3;wire wr_en;wire [31:0]wdata;
wire [31:0]imm;
wire [31:0]alu_in2;
wire [2:0]alu_sel;wire [31:0]alu_out,mac_out,res_ex;wire zero;wire [63:0]mac_mul;
wire regw,memr,memw,alusrc,memreg,branch,macop; wire [1:0]aluop;
wire [31:0]mem_out,branch_tg;

wire [31:0]pc_if,instr_if,pc_id,instr_id;
wire [31:0]pc_ex,R1_ex,R2_ex,R3_ex,imm_ex;
wire [4:0]rs1_ex,rs2_ex,rd_ex; wire [1:0]aluop_ex;wire [2:0]funct3_ex;wire [6:0]funct7_ex;
wire alusrc_ex,regw_ex,memw_ex,memr_ex,regmem_ex,branch_ex,macop_ex;

wire [31:0]res_mem,sd_mem,branch_tg_mem;wire [4:0]rd_mem;
wire regw_mem,memw_mem,memr_mem,memreg_mem,zero_mem,branch_mem;

wire [31:0]wdata_wb,res_wb;wire [4:0]rd_wb;
wire regw_wb,memreg_wb,memw_wb,branch_wb;

reg [31:0]alu_src1,alu_src2_temp,alu_src3;
wire [1:0]fwdA,fwdB,fwdC;wire stall;wire [31:0]pc_inp;

//CPI:
reg [31:0]cycle_count,instr_count,stall_count;
always@(posedge clk or posedge rst) begin 
if(rst) begin cycle_count<=0;instr_count<=0;stall_count<=0; end
else begin 
cycle_count<=cycle_count+1; 
if((regw_wb&&rd_wb!=0)||memw_wb||branch_wb) instr_count<=instr_count+1;
if(stall) stall_count<=stall_count+1;
end
end

//RISCV:
stlunit stl1(memr_ex,macop,rd_ex,rs1,rs2,rd,stall);
fwdunit fwd1(rs1_ex,rs2_ex,rd_ex,rd_mem,rd_wb,regw_mem,regw_wb,fwdA,fwdB,fwdC);
always@(*) begin 
case(fwdA)
2'b00: alu_src1=R1_ex;2'b10:alu_src1=res_mem;2'b01:alu_src1=wdata;default: alu_src1=R1_ex;
endcase
end

always@(*) begin 
case(fwdB)
2'b00: alu_src2_temp=R2_ex;2'b10:alu_src2_temp=res_mem;2'b01:alu_src2_temp=wdata;default: alu_src2_temp=R2_ex;
endcase
end

always@(*) begin
case(fwdC)
2'b00: alu_src3=R3_ex;2'b10:alu_src3=res_mem;2'b01:alu_src3=wdata;default: alu_src3=R3_ex;
endcase
end 

assign pc_inp=stall?pc:pc_next;
assign pc_if=pc;
pc p1(clk,rst,pc_inp,pc);
instr_mem im1(pc_if,instr_if);
if_id ifd1(clk,rst,stall,pcsrc,pc_if,instr_if,pc_id,instr_id);
cntrl c1(instr_id[6:0],regw,memr,memw,alusrc,memreg,branch,aluop,macop);
assign pcp4=pc+4;assign branch_tg=pc_ex+imm_ex;assign pcsrc=branch_ex&zero;
assign pc_next=pcsrc?branch_tg:pcp4;
assign rs1=instr_id[19:15]; assign rs2=instr_id[24:20]; assign rd=instr_id[11:7];assign wr_en=regw_wb;
reg_file r1(clk,rst,wr_en,rs1,rs2,rd,rd_wb,wdata,R1,R2,R3);
imm_gen ig1(instr_id,imm);
id_ex idex1(clk,rst,stall,pcsrc,alusrc,regw,memw,memr,memreg,branch,macop,pc_id,R1,R2,R3,imm,rs1,rs2,rd,aluop,instr_id[14:12],instr_id[31:25],
pc_ex,R1_ex,R2_ex,R3_ex,imm_ex,rs1_ex,rs2_ex,rd_ex,aluop_ex,alusrc_ex,regw_ex,memw_ex,memr_ex,memreg_ex,branch_ex,macop_ex,funct3_ex,funct7_ex);
alu_cntrl ac1(aluop_ex,funct3_ex,funct7_ex,alu_sel);
assign alu_in2=alusrc_ex?imm_ex:alu_src2_temp;
alu a1(alu_src1,alu_in2,alu_sel,alu_out,zero);
assign mac_mul=alu_src1*alu_in2;
assign mac_out=mac_mul[31:0]+alu_src3;
assign res_ex=macop_ex?mac_out:alu_out;
ex_mem exmem1(clk,rst,res_ex,rd_ex,alu_src2_temp,zero,branch_tg,regw_ex,memw_ex,memr_ex,memreg_ex,branch_ex,
res_mem,rd_mem,sd_mem,zero_mem,branch_tg_mem,regw_mem,memw_mem,memr_mem,memreg_mem,branch_mem);
data_mem dm1(clk,rst,memr_mem,memw_mem,res_mem,sd_mem,mem_out);
mem_wb memwb1(clk,rst,mem_out,res_mem,rd_mem,regw_mem,memreg_mem,memw_mem,branch_mem,wdata_wb,res_wb,rd_wb,regw_wb,memreg_wb,memw_wb,branch_wb);
assign wdata=memreg_wb?wdata_wb:res_wb;
endmodule
