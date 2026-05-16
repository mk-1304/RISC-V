module risc_tb;

reg clk,rst;

always #50 clk=~clk;

riscv1 r1(.clk(clk),.rst(rst));

initial begin
clk=1;rst=1;
#100 rst=0;
wait(r1.pc>=136);
#600;
$display("x0 = %d", r1.r1.regs[0]);$display("x1 = %d", r1.r1.regs[1]);$display("x2 = %d", r1.r1.regs[2]);$display("x3 = %d", r1.r1.regs[3]);
$display("x4 = %d", r1.r1.regs[4]);$display("x5 = %d", r1.r1.regs[5]);$display("x6 = %d", r1.r1.regs[6]);$display("x7 = %d", r1.r1.regs[7]);
$display("Cycles = %d", r1.cycle_count);
$display("Instructions = %d", r1.instr_count);
$display("Stalls = %d", r1.stall_count);
$display("CPI = %f", r1.cycle_count * 1.0 / r1.instr_count);
end
endmodule
