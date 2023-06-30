-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
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
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;

library std;
use std.textio.all;

package pkg_fpga_tech is

   -- ------------------------------------------------------------------------------------------------------
   --!   Global parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_IO_DEL_STEP        : integer   := 160                                                            ; --! FPGA I/O delay by step value (ps)
constant c_PLS_CK_SW_NB       : integer   := 2                                                              ; --! Clock pulse number between clock switch command and output clock
constant c_PAD_REG_SET_AUTH   : std_logic := '0'                                                            ; --! Initialization set to one for register located in PAD allowed ('0': No, '1': Yes)

constant c_FPGA_POS_ADC       : integer_vector(0 to 3) := ( 2, 3, 0, 1)                                     ; --! FPGA position ADC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)
constant c_FPGA_POS_SQM_DAC   : integer_vector(0 to 3) := ( 2, 3, 0, 1)                                     ; --! FPGA position MUX DAC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)
constant c_FPGA_POS_SQA_DAC   : integer_vector(0 to 3) := ( 3, 3, 0, 0)                                     ; --! FPGA position AMP DAC (0:Left Up, 1:Left Down, 2:Right Down, 3:Right up)

   -- ------------------------------------------------------------------------------------------------------
   --!   Pll/Wave Form Generator parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_PLL_WFG_DEL_OFF    : bit     := '0'                                                              ; --! Pll/WFG Delay off
constant c_PLL_WFG_DEL_ON     : bit     := '1'                                                              ; --! Pll/WFG Delay on

constant c_PLL_SEL_REF        : bit     := '0'                                                              ; --! Pll select reference clock input: ref input
constant c_PLL_SEL_OSC        : bit     := '1'                                                              ; --! Pll select reference clock input: osc input

constant c_PLL_FBK_INT        : bit     := '0'                                                              ; --! Pll feedback select: Internal feedback
constant c_PLL_FBK_EXT        : bit     := '1'                                                              ; --! Pll feedback select: External feedback

constant c_WFG_EDGE_INV_N     : bit     := '0'                                                              ; --! WFG Input clock not inverted
constant c_WFG_PATTERN_ON     : bit     := '1'                                                              ; --! WFG pattern used

constant c_WFG_PAT_S          : integer   := 16                                                             ; --! WFG pattern bus size
type     t_wfg_pat              is array (0 to c_WFG_PAT_S-1) of bit_vector(0 to c_WFG_PAT_S-1)             ; --! WFG sampling pattern type

constant c_WFG_PAT_ONE_SEQ    : t_wfg_pat := ("0000000000000000",
                                              "0100000000000000",
                                              "1100000000000000",
                                              "1001000000000000",
                                              "0001100000000000",
                                              "0001110000000000",

                                              "0001111000000000",
                                              "0001111000000000",
                                              "0001111000000000",
                                              "0001111100000000",

                                              "0001111110000000",
                                              "0001111110000000",
                                              "0001111110000000",
                                              "0001111111000000",

                                              "0001111111100000",
                                              "0001111111100000")                                           ; --! WFG sampling pattern with only one pattern sequence

constant c_WFG_PAT_ONE_SEQ_90 : t_wfg_pat := ("0000000000000000",
                                              "1000000000000000",
                                              "0110000000000000",
                                              "1100000000000000",
                                              "1000100000000000",
                                              "1100010000000000",

                                              "1100011000000000",
                                              "1000011100000000",
                                              "0000011110000000",
                                              "1000001111000000",

                                              "1000001111100000",
                                              "0000001111110000",
                                              "0000001111110000",
                                              "0000000111111100",

                                              "0000000111111110",
                                              "0000000111111110")                                           ; --! WFG sampling pattern 90 degrees shift with only one pattern sequence


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

   -- ------------------------------------------------------------------------------------------------------
   --!   RAM parameters
   -- ------------------------------------------------------------------------------------------------------
constant c_RAM_TYPE           : t_str_arr(0 to 1) := ("FAST_2kx18", "SLOW_2kx18")                           ; --! RAM type
constant c_RAM_TYPE_DATA_TX   : integer   := 0                                                              ; --! RAM type: Data transfer
constant c_RAM_TYPE_PRM_STORE : integer   := 1                                                              ; --! RAM type: Parameters storage

constant c_RAM_INIT_EMPTY     : integer_vector(0 to 1) := (0, 0)                                            ; --! RAM initialization: RAM empty at start

constant c_RAM_PRM_DIS        : bit       := '0'                                                            ; --! RAM: parameter configured in Disable
constant c_RAM_PRM_ENA        : bit       := '1'                                                            ; --! RAM: parameter configured in Enable
constant c_RAM_CLK_RE         : bit       := '0'                                                            ; --! RAM: clock front polarity on rising edge
constant c_RAM_CLK_FE         : bit       := '1'                                                            ; --! RAM: clock front polarity on falling edge

constant c_RAM_ADD_S          : integer   := 16                                                             ; --! RAM: Address bus size
constant c_RAM_DATA_S         : integer   := 24                                                             ; --! RAM: Data bus size

constant c_RAM_ECC_ADD_S      : integer   := 11                                                             ; --! RAM with ECC: Address bus size
constant c_RAM_ECC_DATA_S     : integer   := 18                                                             ; --! RAM with ECC: Data bus size

constant c_RFB_ADD_S          : integer   :=  5                                                             ; --! Register File Block: Address bus size
constant c_RFB_DATA_S         : integer   := 16                                                             ; --! Register File Block: Data bus size

   -- ------------------------------------------------------------------------------------------------------
   --!   Convert RAM initialization table to string
   -- ------------------------------------------------------------------------------------------------------
   function conv_ram_init (
         i_ram_init           : in     integer_vector                                                       ; --  RAM initialization table
         i_ram_add_s          : in     integer                                                              ; --  RAM address bus size
         i_ram_data_s         : in     integer                                                                --  RAM data bus size
   ) return string;

end pkg_fpga_tech;

package body pkg_fpga_tech is

   -- ------------------------------------------------------------------------------------------------------
   --!   Convert RAM initialization table to string
   -- ------------------------------------------------------------------------------------------------------
   function conv_ram_init (
         i_ram_init           : in     integer_vector                                                       ; --  RAM initialization table
         i_ram_add_s          : in     integer                                                              ; --  RAM address bus size
         i_ram_data_s         : in     integer                                                                --  RAM data bus size
   ) return string is
   constant c_SEPARATOR       : string  := ","                                                              ; --! Separator
   constant c_RAM_S           : integer := (2**i_ram_add_s)-1                                               ; --! RAM size

   variable v_ram_init        : line                                                                        ; --! RAM initialization line
   begin

      -- Check if RAM must be empty at start
      if i_ram_init'length <= 2 then
         return "";

      else

         for k in 0 to c_RAM_S loop

            -- Import RAM init word value
            if i_ram_init'length > k then
               write(v_ram_init, std_logic_vector(to_signed(i_ram_init(k), i_ram_data_s)));

            -- else configure RAM init word to zero
            else
               write(v_ram_init, std_logic_vector(to_signed(0, i_ram_data_s)));

            end if;

            -- Write separator
            if k /= c_RAM_S then
               write(v_ram_init, c_SEPARATOR);

            end if;

         end loop;

         -- Return table
         return v_ram_init.all;

      end if;

   end conv_ram_init;

end package body pkg_fpga_tech;
