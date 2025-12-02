# Calculation Reference

This folder captures the step-by-step arithmetic used to derive the 32-bit machine codes that are loaded into the testbenches.  Each walkthrough follows the same pattern:

1. **Start from the assembly mnemonic** (e.g., `ADDI R1, R0, 10`).
2. **Identify the opcode** (bits `[31:26]`) from `mips.v`.
3. **Assign register numbers** to the `rs`, `rt`, and `rd` fields.
4. **Convert immediates to binary** (sign-extended where needed) and calculate branch displacements.
5. **Assemble the 32-bit instruction** by concatenating opcode, registers, and immediate/funct bits.
6. **Group the 32 bits into four nibbles** and convert each nibble to hexadecimal to get the final word that is written into memory.

## Binary-to-hex conversion recipe

* Split the 32-bit instruction into eight 4-bit nibbles from MSB to LSB.
* Translate each nibble to hex using the mapping `0000→0, 0001→1, …, 1001→9, 1010→A, 1011→B, 1100→C, 1101→D, 1110→E, 1111→F`.
* Concatenate the eight hex digits (keeping leading zeros) to produce the 8-hex-digit machine code written as `32'hXXXXXXXX` in the testbenches.

## Sign-extension and negative offsets

* 16-bit immediates are sign-extended in the pipeline: copy bit 15 into the upper 16 bits when forming a 32-bit value.
* To encode a negative offset (e.g., `-2`), write its 16-bit two's-complement form. Example: `-2` in 16 bits is `1111_1111_1111_1110` (invert `0000...0010` and add 1). This binary pattern is inserted directly into bits `[15:0]` before the final hex conversion.

Each testbench file in this folder documents the exact arithmetic for its program and shows where dummy OR instructions are inserted to remove pipeline hazards.
