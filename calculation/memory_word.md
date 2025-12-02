# Memory load/add/store testbench encoding notes

Program goal: load the word at address 120, add 45 to it, store the result at address 121, then halt. A dummy OR is inserted between every dependent pair of instructions.

## Instruction encodings

| # | Assembly | Fields (opcode / rs / rt / rd / imm) | 32-bit binary assembly | Hex word |
|---|----------|--------------------------------------|-------------------------|----------|
|0|`ADDI R1, R0, 120`|`001010` / `00000` / `00001` / — / `0000_0000_0111_1000`|`0010 1000 0000 0001 0000 0000 0111 1000`|`0x28010078`|
|1|`OR R3, R3, R3` (dummy)|`000101` / `00011` / `00011` / `00011` / `00000000000`|`0001 0100 0110 0011 0001 1000 0000 0000`|`0x14631800`|
|2|`LW R2, 0(R1)`|`001101` / `00001` / `00010` / — / `0000_0000_0000_0000`|`0011 0100 0000 0010 0000 0000 0000 0000`|`0x34220000`|
|3|`OR R3, R3, R3` (dummy)|same as #1|`0001 0100 0110 0011 0001 1000 0000 0000`|`0x14631800`|
|4|`ADDI R2, R2, 45`|`001010` / `00010` / `00010` / — / `0000_0000_0010_1101`|`0010 1000 0100 0010 0000 0000 0010 1101`|`0x2842002d`|
|5|`OR R3, R3, R3` (dummy)|same as #1|`0001 0100 0110 0011 0001 1000 0000 0000`|`0x14631800`|
|6|`SW R2, 1(R1)`|`001110` / `00001` / `00010` / — / `0000_0000_0000_0001`|`0011 1000 0010 0010 0000 0000 0000 0001`|`0x38220001`|
|7|`HLT`|`111111` / — / — / — / `0000_0000_0000_0000`|`1111 1111 0000 0000 0000 0000 0000 0000`|`0xfc000000`|

Notes on field ordering (matches `mips.v`): `opcode[31:26] | rs[25:21] | rt[20:16] | rd[15:11] | shamt/funct or immediate[15:0]`.

## Building the 32-bit words

1. Use opcodes from `mips.v`: `ADDI=001010`, `OR=000101`, `LW=001101`, `SW=001110`, `HLT=111111`.
2. Register binaries: R0=`00000`, R1=`00001`, R2=`00010`, R3=`00011`.
3. Immediate values:
   * `120` → `0000_0000_0111_1000`.
   * `45`  → `0000_0000_0010_1101`.
   * Store offset `1` → `0000_0000_0000_0001`.
4. Concatenate opcode + `rs` + `rt` + immediate (or `rd` + zeros for the OR dummy) to form a 32-bit pattern.
5. Group into 4-bit nibbles and convert each nibble to hex to get the machine words listed above.

## Testbench structure recap

* **Clocking:** two-phase clocks toggled for 60 iterations.
* **Initialization:** registers prefilled with their indices; memory location 120 seeded with `85` (`uut.Mem[120] = 32'd85`).
* **Program load:** words from the table are written to `uut.Mem[0..7]`.
* **Hazard padding:** OR self-ops at slots 1, 3, and 5 separate back-to-back dependent instructions (ADDI→LW, LW→ADDI, ADDI→SW).
* **Finish:** after 600 ns the bench reports `Mem[120]` and `Mem[121]`, expecting `Mem[121] = 85 + 45 = 130`.
