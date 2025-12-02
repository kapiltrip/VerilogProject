`timescale 1ns/1ps

module tb_factorial;
    reg clock1, clock2;
    mips uut(.clock1(clock1), .clock2(clock2));

    integer k;

    initial begin
        clock1 = 0; clock2 = 0;
        repeat (200) begin
            #5 clock1 = 1; #5 clock1 = 0;
            #5 clock2 = 1; #5 clock2 = 0;
        end
    end

    initial begin
        for (k = 0; k < 32; k = k + 1) begin
            uut.Reg[k] = k;
        end

        // Program to compute factorial of the value stored at Mem[200]
        uut.Mem[0]  = 32'h280a00c8; // ADDI R10, R0, 200
        uut.Mem[1]  = 32'h28020001; // ADDI R2,  R0, 1 (accumulator)
        uut.Mem[2]  = 32'h35430000; // LW   R3, 0(R10) load N
        uut.Mem[3]  = 32'h14e73800; // OR   R7, R7, R7 (dummy)
        uut.Mem[4]  = 32'h10431000; // MUL  R2, R3, R2
        uut.Mem[5]  = 32'h14e73800; // OR   R7, R7, R7 (dummy)
        uut.Mem[6]  = 32'h2c630001; // SUBI R3, R3, 1
        uut.Mem[7]  = 32'h14e73800; // OR   R7, R7, R7 (dummy)
        uut.Mem[8]  = 32'h3c60fffb; // BNEQZ R3, loop (-5)
        uut.Mem[9]  = 32'h3942fffe; // SW   R2, -2(R10)
        uut.Mem[10] = 32'hfc000000; // HLT

        // Place input value N at Mem[200]
        uut.Mem[200] = 32'd7;

        // Reset PC and flags
        uut.PC = 0; uut.halted = 0; uut.taken_branch = 0;

        // Monitor accumulator as it changes
        $monitor("Time=%0t R2=%0d", $time, uut.Reg[2]);

        #3000;
        $display("Mem[200]: %0d", uut.Mem[200]);
        $display("Mem[198]: %0d", uut.Mem[198]);
        $finish;
    end

    initial begin
        $dumpfile("tb_factorial.vcd");
        $dumpvars(0, tb_factorial);
    end
endmodule
