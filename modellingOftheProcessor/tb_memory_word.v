`timescale 1ns/1ps

module tb_memory_word;
    reg clock1, clock2;
    mips uut(.clock1(clock1), .clock2(clock2));

    integer k;

    initial begin
        clock1 = 0; clock2 = 0;
        repeat (60) begin
            #5 clock1 = 1; #5 clock1 = 0;
            #5 clock2 = 1; #5 clock2 = 0;
        end
    end

    initial begin
        // Initialize registers
        for (k = 0; k < 32; k = k + 1) begin
            uut.Reg[k] = k;
        end

        // Sample program demonstrating load/add/store
        uut.Mem[0] = 32'h28010078; // ADDI R1, R0, 120
        uut.Mem[1] = 32'h14631800; // OR R3, R3, R3 (dummy)
        uut.Mem[2] = 32'h34220000; // LW  R2, 0(R1)
        uut.Mem[3] = 32'h14631800; // OR R3, R3, R3 (dummy)
        uut.Mem[4] = 32'h2842002d; // ADDI R2, R2, 45
        uut.Mem[5] = 32'h14631800; // OR R3, R3, R3 (dummy)
        uut.Mem[6] = 32'h38220001; // SW R2, 1(R1)
        uut.Mem[7] = 32'hfc000000; // HLT

        // Preload memory[120] with a value
        uut.Mem[120] = 32'd85;

        // Reset control flags and PC
        uut.PC = 0; uut.halted = 0; uut.taken_branch = 0;

        #600;
        $display("Mem[120]: %0d", uut.Mem[120]);
        $display("Mem[121]: %0d", uut.Mem[121]);
        $finish;
    end

    initial begin
        $dumpfile("tb_memory_word.vcd");
        $dumpvars(0, tb_memory_word);
    end
endmodule
