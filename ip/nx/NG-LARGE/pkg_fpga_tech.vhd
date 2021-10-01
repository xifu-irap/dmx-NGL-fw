-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-ngl-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   slaurent@nanoxplore.com
--!   @file                   pkg_fpga_tech.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Parameters linked to fpga technology
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

package pkg_fpga_tech is

   -- ------------------------------------------------------------------------------------------------------
   --!   Global parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_IO_DEL_STEP        : integer   := 160                                                            ; --! FPGA I/O delay by step value (ps)
constant c_PLS_CK_SW_NB       : integer   := 2                                                              ; --! Clock pulse number between clock switch command and output clock

   -- ------------------------------------------------------------------------------------------------------
   --!   Wave Form Generator parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_WFG_PAT_S          : integer   := 16                                                             ; --! WFG pattern bus size
type     t_wfg_pat              is array (0 to c_WFG_PAT_S-1) of bit_vector(0 to c_WFG_PAT_S-1)             ; --! WFG sampling pattern type

constant c_WFG_PAT_ONE_SEQ    : t_wfg_pat := ("1000000000000000",
                                              "1000000000000000",
                                              "1000000000000000",
                                              "1100000000000000",
                                              "1100000000000000",
                                              "1110000000000000",
                                              "1110000000000000",
                                              "1111000000000000",
                                              "1111000000000000",
                                              "1111100000000000",
                                              "1111100000000000",
                                              "1111110000000000",
                                              "1111110000000000",
                                              "1111111000000000",
                                              "1111111000000000",
                                              "1111111100000000")                                           ; --! WFG sampling pattern with only one pattern sequence

   -- ------------------------------------------------------------------------------------------------------
   --!   Multiplier and ALU Ipcore parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_MULT_ALU_PORTA_S   : integer   := 24                                                             ; --! Multiplier and ALU: Port A bus size
constant c_MULT_ALU_PORTB_S   : integer   := 18                                                             ; --! Multiplier and ALU: Port B bus size
constant c_MULT_ALU_PORTC_S   : integer   := 36                                                             ; --! Multiplier and ALU: Port C bus size
constant c_MULT_ALU_PORTD_S   : integer   := 18                                                             ; --! Multiplier and ALU: Port D bus size
constant c_MULT_ALU_RESULT_S  : integer   := 56                                                             ; --! Multiplier and ALU: Result bus size
constant c_MULT_ALU_CPORTA_S  : integer   := 24                                                             ; --! Multiplier and ALU: Cascaded Port A bus size
constant c_MULT_ALU_OP_S      : integer   :=  6                                                             ; --! Multiplier and ALU: Operand bus size
constant c_MULT_ALU_SAT_RNK_S : integer   :=  6                                                             ; --! Multiplier and ALU: Saturation rank bus size

constant c_MULT_ALU_PRM_NU    : bit       := '0'                                                            ; --! Multiplier and ALU: parameter Not used
constant c_MULT_ALU_PRM_DIS   : bit       := '0'                                                            ; --! Multiplier and ALU: parameter configured in Disable
constant c_MULT_ALU_PRM_ENA   : bit       := '1'                                                            ; --! Multiplier and ALU: parameter configured in Enable

constant c_MULT_ALU_UNSIGNED  : bit       := '0'                                                            ; --! Multiplier and ALU: Data type unsigned
constant c_MULT_ALU_SIGNED    : bit       := '1'                                                            ; --! Multiplier and ALU: Data type signed

   -- ------------------------------------------------------------------------------------------------------
   --!   ALU operation commands:
   --!    + MUX_ALU_OP -> A
   --!    + MUX_MULT   -> B
   --!    + MUX_CARRY  -> CI
   -- ------------------------------------------------------------------------------------------------------
constant c_MULT_ALU_OP_ADD    : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "000000"                          ; --! Multiplier and ALU Operation: A + B
constant c_MULT_ALU_OP_ADDC   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "000001"                          ; --! Multiplier and ALU Operation: A + B + CI
constant c_MULT_ALU_OP_SUB    : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "001010"                          ; --! Multiplier and ALU Operation: A - B
constant c_MULT_ALU_OP_SUBC   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "001011"                          ; --! Multiplier and ALU Operation: A - B - CI
constant c_MULT_ALU_OP_INCC   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "000101"                          ; --! Multiplier and ALU Operation: A + CI
constant c_MULT_ALU_OP_DECC   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "000111"                          ; --! Multiplier and ALU Operation: A - CI
constant c_MULT_ALU_OP_A      : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "100000"                          ; --! Multiplier and ALU Operation: A
constant c_MULT_ALU_OP_NOTA   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "110000"                          ; --! Multiplier and ALU Operation: ~A
constant c_MULT_ALU_OP_AND    : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "100001"                          ; --! Multiplier and ALU Operation: A and B
constant c_MULT_ALU_OP_ANDNB  : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "101001"                          ; --! Multiplier and ALU Operation: A and ~B
constant c_MULT_ALU_OP_NAND   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "110001"                          ; --! Multiplier and ALU Operation: ~(A and B)
constant c_MULT_ALU_OP_OR     : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "100010"                          ; --! Multiplier and ALU Operation: A or B
constant c_MULT_ALU_OP_ORNOTB : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "101010"                          ; --! Multiplier and ALU Operation: A or ~B
constant c_MULT_ALU_OP_NOR    : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "110010"                          ; --! Multiplier and ALU Operation: ~(A or B)
constant c_MULT_ALU_OP_XOR    : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "100011"                          ; --! Multiplier and ALU Operation: A xor B
constant c_MULT_ALU_OP_XNOR   : bit_vector(c_MULT_ALU_OP_S-1 downto 0) := "110011"                          ; --! Multiplier and ALU Operation: ~(A xor B)

end pkg_fpga_tech;
