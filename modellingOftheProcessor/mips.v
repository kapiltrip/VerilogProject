// Simple pipelined MIPS-like processor based on lecture transcript
module mips(input clock1, input clock2);
    // Program counter
    reg [31:0] PC;

    // IF/ID pipeline registers
    reg [31:0] IF_ID_IR, IF_ID_NPC;

    // ID/EX pipeline registers
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM;
    reg [2:0]  ID_EX_type;

    // EX/MEM pipeline registers
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
    reg        EX_MEM_cond;
    reg [2:0]  EX_MEM_type;

    // MEM/WB pipeline registers
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    reg [2:0]  MEM_WB_type;

    // Register file and memory
    reg [31:0] Reg[0:31];
    reg [31:0] Mem[0:1023];

    // Opcodes
    parameter ADD   = 6'b000000,
              SUB   = 6'b000001,
              AND   = 6'b000010,
              SLT   = 6'b000011,
              MUL   = 6'b000100,
              OR    = 6'b000101,
              ADDI  = 6'b001010,
              SUBI  = 6'b001011,
              SLTI  = 6'b001100,
              LW    = 6'b001101,
              SW    = 6'b001110,
              BNEQZ = 6'b001111,
              BEQZ  = 6'b010000,
              HLT   = 6'b111111;

    // Instruction type tags
    parameter RR_ALU = 3'b000,
              RM_ALU = 3'b001,
              LOAD   = 3'b010,
              STORE  = 3'b011,
              BRANCH = 3'b100,
              HALT   = 3'b101;

    // Control flags
    reg halted, taken_branch;

    integer i;

    initial begin
        PC = 0;
        halted = 0;
        taken_branch = 0;
        // Initialize registers to zero
        for (i = 0; i < 32; i = i + 1) begin
            Reg[i] = 0;
        end
        // Initialize memory to zero
        for (i = 0; i < 1024; i = i + 1) begin
            Mem[i] = 0;
        end
    end

    // Instruction Fetch
    always @(posedge clock1) begin
        if (!halted) begin
            if ((EX_MEM_IR[31:26] == BEQZ && EX_MEM_cond == 1'b1) ||
                (EX_MEM_IR[31:26] == BNEQZ && EX_MEM_cond == 1'b0)) begin
                IF_ID_IR  <= Mem[EX_MEM_ALUOut];
                IF_ID_NPC <= EX_MEM_ALUOut + 1;
                PC        <= EX_MEM_ALUOut + 1;
                taken_branch <= 1'b1;
            end else begin
                IF_ID_IR  <= Mem[PC];
                IF_ID_NPC <= PC + 1;
                PC        <= PC + 1;
                taken_branch <= 1'b0;
            end
        end
    end

    // Instruction Decode
    always @(posedge clock2) begin
        if (!halted) begin
            ID_EX_NPC <= IF_ID_NPC;
            ID_EX_IR  <= IF_ID_IR;

            // Register operand fetch with R0 hardwired to zero
            ID_EX_A <= (IF_ID_IR[25:21] == 5'd0) ? 32'd0 : Reg[IF_ID_IR[25:21]];
            ID_EX_B <= (IF_ID_IR[20:16] == 5'd0) ? 32'd0 : Reg[IF_ID_IR[20:16]];

            // Sign-extended immediate
            ID_EX_IMM <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            // Determine instruction type
            case (IF_ID_IR[31:26])
                ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= RR_ALU;
                ADDI, SUBI, SLTI:            ID_EX_type <= RM_ALU;
                LW:                           ID_EX_type <= LOAD;
                SW:                           ID_EX_type <= STORE;
                BNEQZ, BEQZ:                  ID_EX_type <= BRANCH;
                HLT:                          ID_EX_type <= HALT;
                default:                      ID_EX_type <= HALT;
            endcase
        end
    end

    // Execute
    always @(posedge clock1) begin
        if (!halted) begin
            EX_MEM_type <= ID_EX_type;
            EX_MEM_IR   <= ID_EX_IR;
            taken_branch <= 1'b0;

            case (ID_EX_type)
                RR_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADD: EX_MEM_ALUOut <= ID_EX_A + ID_EX_B;
                        SUB: EX_MEM_ALUOut <= ID_EX_A - ID_EX_B;
                        AND: EX_MEM_ALUOut <= ID_EX_A & ID_EX_B;
                        OR:  EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;
                        SLT: EX_MEM_ALUOut <= (ID_EX_A < ID_EX_B) ? 32'd1 : 32'd0;
                        MUL: EX_MEM_ALUOut <= ID_EX_A * ID_EX_B;
                        default: EX_MEM_ALUOut <= 32'hxxxxxxxx;
                    endcase
                end
                RM_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADDI: EX_MEM_ALUOut <= ID_EX_A + ID_EX_IMM;
                        SUBI: EX_MEM_ALUOut <= ID_EX_A - ID_EX_IMM;
                        SLTI: EX_MEM_ALUOut <= (ID_EX_A < ID_EX_IMM) ? 32'd1 : 32'd0;
                        default: EX_MEM_ALUOut <= 32'hxxxxxxxx;
                    endcase
                end
                LOAD, STORE: begin
                    EX_MEM_ALUOut <= ID_EX_A + ID_EX_IMM;
                    EX_MEM_B      <= ID_EX_B;
                end
                BRANCH: begin
                    EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_IMM;
                    EX_MEM_cond   <= (ID_EX_A == 0);
                end
                HALT: begin
                    EX_MEM_ALUOut <= 32'd0;
                end
                default: begin
                    EX_MEM_ALUOut <= 32'd0;
                end
            endcase
        end
    end

    // Memory access
    always @(posedge clock2) begin
        if (!halted) begin
            MEM_WB_type   <= EX_MEM_type;
            MEM_WB_IR     <= EX_MEM_IR;
            MEM_WB_ALUOut <= EX_MEM_ALUOut;

            case (EX_MEM_type)
                LOAD: begin
                    MEM_WB_LMD <= Mem[EX_MEM_ALUOut];
                end
                STORE: begin
                    if (!taken_branch) begin
                        Mem[EX_MEM_ALUOut] <= EX_MEM_B;
                    end
                end
                default: ;
            endcase
        end
    end

    // Write back
    always @(posedge clock1) begin
        if (!taken_branch) begin
            case (MEM_WB_type)
                RR_ALU: begin
                    if (MEM_WB_IR[15:11] != 0)
                        Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;
                end
                RM_ALU: begin
                    if (MEM_WB_IR[20:16] != 0)
                        Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut;
                end
                LOAD: begin
                    if (MEM_WB_IR[20:16] != 0)
                        Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
                end
                HALT: halted <= 1'b1;
                default: ;
            endcase
        end
    end
endmodule
