# Factorial testbench encoding notes

Program goal: compute `factorial(n)` for the value stored at memory address 200, place the result at address 198, and halt. The loop decrements a counter in `R3`, multiplies an accumulator in `R2`, and branches back until `R3` hits zero. Dummy ORs insert pipeline bubbles between dependent instructions.

## Instruction encodings

| # | Assembly | Fields (opcode / rs / rt / rd / imm/funct) | 32-bit binary assembly | Hex word |
|---|----------|-------------------------------------------|-------------------------|----------|
|0|`ADDI R10, R0, 200`|`001010` / `00000` / `01010` / — / `0000_0000_1100_1000`|`0010 1000 0000 1010 0000 0000 1100 1000`|`0x280a00c8`|
|1|`ADDI R2, R0, 1`|`001010` / `00000` / `00010` / — / `0000_0000_0000_0001`|`0010 1000 0000 0010 0000 0000 0000 0001`|`0x28020001`|
|2|`LW R3, 0(R10)`|`001101` / `01010` / `00011` / — / `0000_0000_0000_0000`|`0011 0101 0100 0011 0000 0000 0000 0000`|`0x35430000`|
|3|`OR R7, R7, R7` (dummy)|`000101` / `00111` / `00111` / `00111` / `00000000000`|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|4|`MUL R2, R3, R2`|`000100` / `00010` / `00011` / `00010` / `00000000000`|`0001 0000 0100 0011 0010 0000 0000 0000`|`0x10431000`|
|5|`OR R7, R7, R7` (dummy)|same as #3|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|6|`SUBI R3, R3, 1`|`001011` / `00011` / `00011` / — / `0000_0000_0000_0001`|`0010 1100 0110 0011 0000 0000 0000 0001`|`0x2c630001`|
|7|`OR R7, R7, R7` (dummy)|same as #3|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|8|`BNEQZ R3, loop` (offset = -5)|`001111` / `00011` / — / — / `1111_1111_1111_1011`|`0011 1100 0110 0000 1111 1111 1111 1011`|`0x3c60fffb`|
|9|`SW R2, -2(R10)`|`001110` / `01010` / `00010` / — / `1111_1111_1111_1110`|`0011 1001 0100 0010 1111 1111 1111 1110`|`0x3942fffe`|
|10|`HLT`|`111111` / — / — / — / `0000000000000000`|`1111 1111 0000 0000 0000 0000 0000 0000`|`0xfc000000`|

Notes:
* The branch offset `-5` jumps from NPC `9` (after fetching instruction #8) back to address `4`, re-entering the multiply step after the dummy at #3.
* The store offset `-2` writes to `R10 - 2`, placing the factorial result in memory address 198 when `R10 = 200`.

## Building the 32-bit words

1. Opcodes: `ADDI=001010`, `LW=001101`, `OR=000101`, `MUL=000100`, `SUBI=001011`, `BNEQZ=001111`, `SW=001110`, `HLT=111111`.
2. Register binaries: R0=`00000`, R2=`00010`, R3=`00011`, R7=`00111`, R10=`01010`.
3. Immediate values and offsets:
   * `200` → `0000_0000_1100_1000`.
   * `1` → `0000_0000_0000_0001`.
   * Branch `-5` → two's-complement `1111_1111_1111_1011`.
   * Store offset `-2` → two's-complement `1111_1111_1111_1110`.
4. Concatenate opcode + `rs` + `rt` + `rd`/immediate, split into nibbles, and convert each nibble to hex (table above).

## Testbench structure recap

* **Clocking:** two-phase clocks run for 200 iterations to cover the longer loop.
* **Initialization:** registers filled with their indices; memory location 200 is seeded with the operand `n` (e.g., 7), and location 198 will hold the result.
* **Program load:** words above are written to `uut.Mem[0..10]`.
* **Hazard padding:** dummy ORs at indices 3, 5, and 7 separate dependent instructions (`LW→MUL`, `MUL→SUBI`, `SUBI→BNEQZ`).
* **Loop mechanics:** `R2` accumulates the product, `R3` counts down, `BNEQZ` branches back with offset `-5` until `R3` becomes zero.
* **Finish:** after execution, the testbench prints `Mem[200]` (original input) and `Mem[198]` (factorial result), then halts on `HLT`.
