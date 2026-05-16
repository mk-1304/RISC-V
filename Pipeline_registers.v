module if_id(clk,rst,stall,flush,pc_in,instr_in,pc_out,instr_out);
input clk,rst,stall,flush;input [31:0]pc_in,instr_in;
output reg [31:0]pc_out,instr_out;
always@(posedge clk or posedge rst) begin
if(rst||flush) begin pc_out<=32'b0;instr_out<=32'b0; end
else if(!stall) begin pc_out<=pc_in;instr_out<=instr_in; end
end
endmodule

module id_ex(
input clk,rst,stall,flush,alusrc_in,regw_in,memw_in,memr_in,memreg_in,branch_in,macop_in,
input [31:0]pc_in,R1_in,R2_in,R3_in,imm_in,input [4:0]rs1_in,rs2_in,rd_in,input [1:0]aluop_in,input [2:0]funct3_in,input [6:0]funct7_in,
output reg [31:0]pc_out,R1_out,R2_out,R3_out,imm_out,output reg [4:0]rs1_out,rs2_out,rd_out,output reg [1:0]aluop_out,
output reg alusrc_out,regw_out,memw_out,memr_out,memreg_out,branch_out,macop_out,output reg [2:0]funct3_out,output reg [6:0]funct7_out);

always@(posedge clk or posedge rst) begin
if(rst) begin pc_out<=0;R1_out<=0;R2_out<=0;R3_out<=0;imm_out<=0;rs1_out<=0;rs2_out<=0;rd_out<=0;aluop_out<=0;
alusrc_out<=0;macop_out<=0;regw_out<=0;memr_out<=0;memw_out<=0;memreg_out<=0;branch_out<=0;funct3_out<=0;funct7_out<=0; end 
else if(stall||flush) begin regw_out<=0;memr_out<=0;memw_out<=0;memreg_out<=0;branch_out<=0;macop_out<=0;alusrc_out<=0;aluop_out<=0; end
else begin pc_out<=pc_in;R1_out<=R1_in;R2_out<=R2_in;R3_out<=R3_in;imm_out<=imm_in;rs1_out<=rs1_in;rs2_out<=rs2_in;
rd_out<=rd_in;aluop_out<=aluop_in;alusrc_out<=alusrc_in;regw_out<=regw_in;memr_out<=memr_in;macop_out<=macop_in;
memw_out<=memw_in;memreg_out<=memreg_in;branch_out<=branch_in;funct3_out<=funct3_in;funct7_out<=funct7_in; end
end
endmodule

module ex_mem(clk,rst,alu_in,rd_in,sd_in,zero_in,btg_in,regw_in,memw_in,memr_in,memreg_in,
branch_in,alu_out,rd_out,sd_out,zero_out,btg_out,regw_out,memw_out,memr_out,memreg_out,branch_out);

input clk,rst,zero_in,regw_in,memw_in,memr_in,memreg_in,branch_in;
input [31:0]alu_in,btg_in,sd_in; input [4:0]rd_in;
output reg zero_out,regw_out,memw_out,memr_out,memreg_out,branch_out;
output reg [31:0]alu_out,btg_out,sd_out;output reg [4:0]rd_out;

always@(posedge clk or posedge rst) begin
if(rst) begin
alu_out<=0;btg_out<=0;rd_out<=0;sd_out<=0;zero_out<=0;regw_out<=0;memw_out<=0;memr_out<=0;memreg_out<=0;branch_out<=0;
end
else begin
alu_out<=alu_in;btg_out<=btg_in;rd_out<=rd_in;sd_out<=sd_in;zero_out<=zero_in;
regw_out<=regw_in;memw_out<=memw_in;memr_out<=memr_in;memreg_out<=memreg_in;branch_out<=branch_in;
end
end
endmodule

module mem_wb(clk,rst,mem_in,alu_in,rd_in,regw_in,memreg_in,memw_in,branch_in,mem_out,alu_out,rd_out,regw_out,memreg_out,memw_out,branch_out);
input clk,rst,regw_in,memreg_in,memw_in,branch_in;input [31:0]mem_in,alu_in;input [4:0]rd_in;
output reg [31:0]mem_out,alu_out;output reg [4:0]rd_out;output reg regw_out,memreg_out,memw_out,branch_out;

always@(posedge clk or posedge rst) begin
if(rst) begin 
mem_out<=0;alu_out<=0;rd_out<=0;regw_out<=0;memreg_out<=0;memw_out<=0;branch_out<=0;
end
else begin
mem_out<=mem_in;alu_out<=alu_in;rd_out<=rd_in;regw_out<=regw_in;memreg_out<=memreg_in;memw_out<=memw_in;branch_out<=branch_in;
end
end
endmodule
