# Add-three-numbers testbench encoding notes

Program goal: load immediates 10, 20, and 25 into registers, sum them in two steps, and halt. Dummy ORs are inserted to avoid pipeline hazards between dependent operations.

## Instruction encodings

| # | Assembly | Fields (opcode / rs / rt / rd / imm/funct) | 32-bit binary assembly | Hex word |
|---|----------|-------------------------------------------|-------------------------|----------|
|0|`ADDI R1, R0, 10`|`001010` / `00000` / `00001` / — / `0000_0000_0000_1010`|`0010 1000 0000 0001 0000 0000 0000 1010`|`0x2801000a`|
|1|`ADDI R2, R0, 20`|`001010` / `00000` / `00010` / — / `0000_0000_0001_0100`|`0010 1000 0000 0010 0000 0000 0001 0100`|`0x28020014`|
|2|`ADDI R3, R0, 25`|`001010` / `00000` / `00011` / — / `0000_0000_0001_1001`|`0010 1000 0000 0011 0000 0000 0001 1001`|`0x28030019`|
|3|`OR R7, R7, R7` (dummy)|`000101` / `00111` / `00111` / `00111` / `00000000000`|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|4|`OR R7, R7, R7` (dummy)|same as above|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|5|`ADD R4, R1, R2`|`000000` / `00001` / `00010` / `00100` / `00000000000`|`0000 0000 0010 0010 0001 0000 0000 0000`|`0x00222000`|
|6|`OR R7, R7, R7` (dummy)|same as #3|`0001 0100 1110 0111 0011 1000 0000 0000`|`0x14e73800`|
|7|`ADD R5, R4, R3`|`000000` / `00100` / `00011` / `00101` / `00000000000`|`0000 0000 1000 0011 0101 0000 0000 0000`|`0x00832800`|
|8|`HLT`|`111111` / — / — / — / `0000000000000000`|`1111 1111 0000 0000 0000 0000 0000 0000`|`0xfc000000`|

## Building the 32-bit words

1. Start with opcode bits from `mips.v` (e.g., `ADDI = 001010`, `OR = 000101`, `ADD = 000000`, `HLT = 111111`).
2. Insert register numbers in binary: R0=`00000`, R1=`00001`, R2=`00010`, R3=`00011`, R4=`00100`, R5=`00101`, R7=`00111`.
3. For immediates, write the 16-bit value directly (e.g., decimal 10 → `0000_0000_0000_1010`).
4. Concatenate opcode + `rs` + `rt` + `rd`/immediate/funct to form a 32-bit binary string.
5. Group into nibbles (shown with spaces above) and translate each nibble to hex, yielding the `0x` words used in `tb_add_three_numbers.v`.

## Testbench structure recap

* **Clocking:** two-phase clocks toggled in a 50-cycle loop (`#5` edges).
* **Initialization:** every register preloaded with its index for visibility; `PC`, `halted`, and `taken_branch` cleared.
* **Program load:** words in the table are written to `uut.Mem[0..8]` in order.
* **Hazard padding:** OR self-ops at slots 3, 4, and 6 provide pipeline bubbles between dependent ADD/ADDI instructions.
* **Finish:** after 500 ns, the bench prints `R0–R5` to show `R5 = 55`.
