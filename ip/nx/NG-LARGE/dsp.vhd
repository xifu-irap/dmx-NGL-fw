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
--!   @file                   dsp.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Digital Signal Processing. Realize the signed operation in 3 clock cycles:
--!                            o_z = o_cz = i_a * (i_b +- i_d) + i_carry + mux(i_cz, i_c)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_fpga_tech.all;

library nx;
use     nx.nxpackage.all;

entity dsp is generic (
         g_PORTA_S            : integer                                                                     ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            : integer                                                                     ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            : integer                                                                     ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           : integer                                                                     ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     : integer                                                                     ; --! Result LSB position

         g_DATA_TYPE          : bit                                                                         ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           : integer                                                                     ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       : bit                                                                         ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           : bit                                                                           --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_carry              : in     std_logic                                                            ; --! Carry In
         i_a                  : in     std_logic_vector( g_PORTA_S-1 downto 0)                              ; --! Port A
         i_b                  : in     std_logic_vector( g_PORTB_S-1 downto 0)                              ; --! Port B
         i_c                  : in     std_logic_vector( g_PORTC_S-1 downto 0)                              ; --! Port C
         i_d                  : in     std_logic_vector( g_PORTB_S-1 downto 0)                              ; --! Port D
         i_cz                 : in     std_logic_vector(c_MULT_ALU_RESULT_S-1 downto 0)                     ; --! Cascaded Result Input

         o_z                  : out    std_logic_vector(g_RESULT_S-1 downto 0)                              ; --! Result
         o_cz                 : out    std_logic_vector(c_MULT_ALU_RESULT_S-1 downto 0)                       --! Cascaded Result
   );
end entity dsp;

architecture RTL of dsp is
constant c_SAT_RANK           : bit_vector(c_MULT_ALU_SAT_RNK_S-1 downto 0):=
                                to_bitvector(std_logic_vector(to_unsigned(g_SAT_RANK,c_MULT_ALU_SAT_RNK_S))); --! Extrem values reached on result bus [-2**(g_SAT_RANK); 2**(g_SAT_RANK)-1]
constant c_MUX_X              : bit_vector(1 downto 0):= g_MUX_C_CZ & '1'                                   ; --! Multiplexer ALU operand

signal   port_a               : std_logic_vector( c_MULT_ALU_PORTA_S-1 downto 0)                            ; --! Port A
signal   port_b               : std_logic_vector( c_MULT_ALU_PORTB_S-1 downto 0)                            ; --! Port B
signal   port_c               : std_logic_vector( c_MULT_ALU_PORTC_S-1 downto 0)                            ; --! Port C
signal   port_d               : std_logic_vector( c_MULT_ALU_PORTD_S-1 downto 0)                            ; --! Port B

signal   result               : std_logic_vector(c_MULT_ALU_RESULT_S-1 downto 0)                            ; --! Filter output (unsigned)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on Multiplier ALU inputs format
   -- ------------------------------------------------------------------------------------------------------
   G_data_signed: if g_DATA_TYPE = c_MULT_ALU_SIGNED generate
      port_a <= std_logic_vector(resize(signed(i_a), port_a'length));
      port_b <= std_logic_vector(resize(signed(i_b), port_b'length));
      port_c <= std_logic_vector(resize(signed(i_c), port_c'length));
      port_d <= std_logic_vector(resize(signed(i_d), port_d'length));
   end generate G_data_signed;

   G_data_unsigned: if g_DATA_TYPE = c_MULT_ALU_UNSIGNED generate
      port_a <= std_logic_vector(resize(unsigned(i_a), port_a'length));
      port_b <= std_logic_vector(resize(unsigned(i_b), port_b'length));
      port_c <= std_logic_vector(resize(unsigned(i_c), port_c'length));
      port_d <= std_logic_vector(resize(unsigned(i_d), port_d'length));
   end generate G_data_unsigned;

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_DSP_L_SPLIT IpCore instantiation
   -- ------------------------------------------------------------------------------------------------------
   I_dsp: entity nx.nx_dsp_l_split generic map (
         SIGNED_MODE          => g_DATA_TYPE          , -- bit                                              ; --! Data type                     ('0' = unsigned,           '1' = signed)
         PRE_ADDER_OP         => g_PRE_ADDER_OP       , -- bit                                              ; --! Pre-Adder operation           ('0' = add,                '1' = subtract)
         ALU_DYNAMIC_OP       => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU Dynamic operation enable  ('0' = ALU_STAT_OP used,   '1' = Port D LSB used)
         ALU_OP               => c_MULT_ALU_OP_ADDC   , -- bit_vector(MULT_ALU_OP_S-1 downto 0)             ; --! ALU Static operation
         ALU_MUX              => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU swap operands             ('0' = no swap,            '1' = swap)
         Z_FEEDBACK_SHL12     => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU shift of MUX_ALU input    (see below Z_FEEDBACK_SHL12 & MUX_X for configuration)
         ENABLE_SATURATION    => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Saturation enable             ('0' = disable,            '1' = enable)
         SATURATION_RANK      => c_SAT_RANK           , -- bit_vector(5 downto 0)                           ; --! Extrem values reached on result bus and overflow management
                                                                                                              --!   unsigned: range from             0  to 2**(SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(SAT_RANK) to 2**(SAT_RANK)   - 1

         MUX_CI               => c_MULT_ALU_PRM_NU    , -- bit                                              ; --! Multiplexer ALU Carry In ('0' = ALU Carry In,            '1' = Cascaded ALU Carry In)
         MUX_A                => '0'                  , -- bit                                              ; --! Multiplexer Port A       ('0' = Port A,                  '1' = Cascaded Port A)
         MUX_B                => '0'                  , -- bit                                              ; --! Multiplexer Port B       ('0' = Port B,                  '1' = Cascaded Port B)
         MUX_P                => '1'                  , -- bit                                              ; --! Multiplexer Pre-Adder    ('0' = MUX_PORTB,               '1' = MUX_PORTB +/- Port D)
         MUX_Y                => '0'                  , -- bit                                              ; --! Multiplexer Multiplier   ('0' = MUX_PORTA * MUX_PRE_ADD, '1' = MUX_PORTB & MUX_PORTA)
         MUX_X                => c_MUX_X              , -- bit_vector(1 downto 0)                           ; --! Multiplexer ALU operand  ("X0X" = Port C,                "010" = MUX_ALU,
                                                                                                              --!   "011"= Cascaded Result Input, "110"= MUX_ALU(39:0) & Port C(15:0),
                                                                                                              --!   "111"= Cascaded Result Input(39:0) & Port C(15:0))
         CO_SEL               => c_MULT_ALU_PRM_NU    , -- bit                                              ; --! Multiplexer ALU Carry Out('0' = ALU(36),                 '1' = ALU(48))
         MUX_Z                => '0'                  , -- bit                                              ; --! Multiplexer ALU ('0' = ALU(Port D, MUX_ALU_OP, MUX_MULT, MUX_CARRY) '1' = MUX_MULT)

         PR_CI_MUX            => '1'                  , -- bit                                              ; --! Multiplexer ALU Carry In   pipe register level number
         PR_A_MUX             => "01"                 , -- bit_vector(1 downto 0)                           ; --! Multiplexer Port A         pipe register level number
         PR_B_MUX             => "01"                 , -- bit_vector(1 downto 0)                           ; --! Multiplexer Port B         pipe register level number
         PR_C_MUX             => '1'                  , -- bit                                              ; --! Multiplexer Port C         pipe register level number
         PR_D_MUX             => '1'                  , -- bit                                              ; --! Multiplexer Port D         pipe register level number
         PR_P_MUX             => '0'                  , -- bit                                              ; --! Multiplexer Pre-Adder      pipe register level number
         PR_MULT_MUX          => '0'                  , -- bit                                              ; --! Multiplier Out             pipe register level number
         PR_Y_MUX             => '1'                  , -- bit                                              ; --! Multiplexer Multiplier     pipe register level number
         PR_ALU_MUX           => '0'                  , -- bit                                              ; --! ALU Out                    pipe register level number
         PR_X_MUX             => '1'                  , -- bit                                              ; --! Multiplexer ALU operand    pipe register level number
         PR_CO_MUX            => '1'                  , -- bit                                              ; --! Multiplexer ALU Carry Out  pipe register level number
         PR_OV_MUX            => '1'                  , -- bit                                              ; --! Overflow                   pipe register level number
         PR_Z_MUX             => '1'                  , -- bit                                              ; --! Multiplexer ALU            pipe register level number
         PR_A_CASCADE_MUX     => "00"                 , -- bit_vector(1 downto 0)                           ; --! Cascaded Port A buffer     pipe register level number
         PR_B_CASCADE_MUX     => "00"                 , -- bit_vector(1 downto 0)                           ; --! Cascaded Port B buffer     pipe register level number

         ENABLE_PR_CI_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU Carry In   register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_A_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port A         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_B_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port B         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_C_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port C         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_D_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Port D         register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_P_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Pre-Adder      register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_MULT_RST   => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplier Out             register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_Y_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer Multiplier     register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_ALU_RST    => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! ALU Out                    register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_X_RST      => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU operand    register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_CO_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Multiplexer ALU Carry Out  register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_OV_RST     => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Overflow                   register reset ('0' = Disable, '1' = Enable)
         ENABLE_PR_Z_RST      => c_MULT_ALU_PRM_ENA     -- bit                                                --! Multiplexer ALU            register reset ('0' = Disable, '1' = Enable)

   )     port map (
         ck                   => i_clk                , -- in     std_logic                                 ; --! Clock
         r                    => i_rst                , -- in     std_logic                                 ; --! Reset pipeline registers ('0' = Inactive, '1' = Active)
         rz                   => i_rst                , -- in     std_logic                                 ; --! Reset Z output register  ('0' = Inactive, '1' = Active)
         we                   => '1'                  , -- in     std_logic                                 ; --! Write Enable ('0' = Internal registers frozen, '1' = Normal operation)

         ci                   => i_carry              , -- in     std_logic                                 ; --! ALU Carry In
         a                    => port_a               , -- in     slv( MULT_ALU_PORTA_S-1 downto 0)         ; --! Port A
         b                    => port_b               , -- in     slv( MULT_ALU_PORTB_S-1 downto 0)         ; --! Port B
         c                    => port_c               , -- in     slv( MULT_ALU_PORTC_S-1 downto 0)         ; --! Port C
         d                    => port_d               , -- in     slv( MULT_ALU_PORTD_S-1 downto 0)         ; --! Port D

         cci                  => '0'                  , -- in     std_logic                                 ; --! Cascaded ALU Carry In
         cai                  => (others => '0')      , -- in     slv(MULT_ALU_CPORTA_S-1 downto 0)         ; --! Cascaded Port A
         cbi                  => (others => '0')      , -- in     slv( MULT_ALU_PORTB_S-1 downto 0)         ; --! Cascaded Port B
         czi                  => i_cz                 , -- in     slv(MULT_ALU_RESULT_S-1 downto 0)         ; --! Cascaded Result Input

         co                   => open                 , -- out    std_logic                                 ; --! ALU Carry buffer           (MUX_CARRY_OUT registered output)
         co36                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 36
         co56                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 56
         ovf                  => open                 , -- out    std_logic                                 ; --! Overflow ('0' = No, '1' = Yes)
         z                    => result               , -- out    slv(MULT_ALU_RESULT_S-1 downto 0)         ; --! Result buffer              (MUX_ALU       registered output)

         cco                  => open                 , -- out    std_logic                                 ; --! Cascaded ALU Carry buffer  (MUX_CARRY_OUT registered output)
         cao                  => open                 , -- out    slv(MULT_ALU_CPORTA_S-1 downto 0)         ; --! Cascaded Port A buffer     (MUX_PORTA     registered output)
         cbo                  => open                 , -- out    slv(MULT_ALU_PORTB_S -1 downto 0)         ; --! Cascaded Port B buffer     (MUX_PORTB     registered output)
         czo                  => o_cz                   -- out    slv(MULT_ALU_RESULT_S-1 downto 0)           --! Cascaded Result buffer     (MUX_ALU       registered output)
   );

   o_z <= result(g_RESULT_S+g_RESULT_LSB_POS-1 downto g_RESULT_LSB_POS);

end architecture RTL;
