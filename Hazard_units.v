module fwdunit(rs1_ex,rs2_ex,rs3_ex,rd_mem,rd_wb,regw_mem,regw_wb,fwdA,fwdB,fwdC);
input [4:0]rs1_ex,rs2_ex,rs3_ex,rd_mem,rd_wb;input regw_mem,regw_wb;
output reg [1:0]fwdA,fwdB,fwdC;

always@(*) begin
fwdA=2'b00;fwdB=2'b00;fwdC=2'b00;
if(regw_mem&&rd_mem!=0&&rd_mem==rs1_ex) fwdA = 2'b10;
else if(regw_wb&&rd_wb!=0&&rd_wb==rs1_ex) fwdA = 2'b01;
if(regw_mem&&rd_mem!=0&&rd_mem==rs2_ex) fwdB = 2'b10;
else if(regw_wb&&rd_wb!=0&&rd_wb==rs2_ex) fwdB = 2'b01;
if(regw_mem&&rd_mem!=0&&rd_mem==rs3_ex) fwdC = 2'b10;
else if(regw_wb&&rd_wb!=0&&rd_wb==rs3_ex) fwdC = 2'b01;
end
endmodule

module stlunit(memr_ex,macop,rd_ex,rs1_id,rs2_id,rs3_id,stall);
input memr_ex,macop;input [4:0]rd_ex,rs1_id,rs2_id,rs3_id;
output reg stall;

always@(*) begin 
if(memr_ex&&(rd_ex!=0)&&((rd_ex==rs1_id)||(rd_ex==rs2_id)||(macop&&(rd_ex==rs3_id)))) stall=1;
else stall=0;
end
endmodule
