`timescale 1ns/1ps

module tb_add_three_numbers;
    reg clock1, clock2;

    mips uut(.clock1(clock1), .clock2(clock2));

    integer k;

    initial begin
        clock1 = 0; clock2 = 0;
        repeat (50) begin
            #5 clock1 = 1; #5 clock1 = 0;
            #5 clock2 = 1; #5 clock2 = 0;
        end
    end

    initial begin
        // Initialize register file for visibility
        for (k = 0; k < 32; k = k + 1) begin
            uut.Reg[k] = k;
        end

        // Program: add 10, 20, 25 and store final sum in R5
        uut.Mem[0] = 32'h2801000a; // ADDI R1, R0, 10
        uut.Mem[1] = 32'h28020014; // ADDI R2, R0, 20
        uut.Mem[2] = 32'h28030019; // ADDI R3, R0, 25
        uut.Mem[3] = 32'h14e73800; // OR R7, R7, R7 (dummy)
        uut.Mem[4] = 32'h14e73800; // OR R7, R7, R7 (dummy)
        uut.Mem[5] = 32'h00222000; // ADD R4, R1, R2
        uut.Mem[6] = 32'h14e73800; // OR R7, R7, R7 (dummy)
        uut.Mem[7] = 32'h00832800; // ADD R5, R4, R3
        uut.Mem[8] = 32'hfc000000; // HLT

        // Reset control flags and PC
        uut.PC = 0; uut.halted = 0; uut.taken_branch = 0;

        // Finish after enough time for program
        #500;
        for (k = 0; k <= 5; k = k + 1) begin
            $display("R%0d: %0d", k, uut.Reg[k]);
        end
        $finish;
    end

    initial begin
        $dumpfile("tb_add_three_numbers.vcd");
        $dumpvars(0, tb_add_three_numbers);
    end
endmodule
