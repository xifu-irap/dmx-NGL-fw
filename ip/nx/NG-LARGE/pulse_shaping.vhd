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
--!   @file                   pulse_shaping.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Pulse shaping
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

library nx;
use     nx.nxpackage.all;

entity pulse_shaping is generic
   (     g_X_K_S              : integer                                                                     ; --! Data in bus size (<= c_MULT_ALU_PORTB_S-1)
         g_A_EXP              : integer                                                                     ; --! A[k]: filter exponent parameter (<= c_MULT_ALU_PORTC_S-g_X_K_S-1)
         g_Y_K_S              : integer                                                                       --! y[k]: filtered data out bus size
   ); port
   (     i_rst_sqm_pls_shape  : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID MUX ADC/DAC internal Clock
         i_x_init             : in     std_logic_vector(g_X_K_S-1 downto 0)                                 ; --! Last value reached by y[k] at the end of last slice (unsigned)
         i_x_final            : in     std_logic_vector(g_X_K_S-1 downto 0)                                 ; --! Final value to reach by y[k] (unsigned)
         i_a_mant_k           : in     std_logic_vector(g_A_EXP-1 downto 0)                                 ; --! A[k]: filter mantissa parameter (unsigned)
         o_y_k                : out    std_logic_vector(g_Y_K_S-1 downto 0)                                   --! y[k]: filtered data out (unsigned)
   );
end entity pulse_shaping;

architecture RTL of pulse_shaping is
constant c_FILT_SAT_RANK      : bit_vector(c_MULT_ALU_SAT_RNK_S-1 downto 0):=
                                to_bitvector(std_logic_vector(to_unsigned(g_X_K_S + g_A_EXP,
                                c_MULT_ALU_SAT_RNK_S)))                                                     ; --! Filter: saturation rank range from 0 to 2^(c_FILT_SAT_RANK+1) - 1

signal   x_init_rsize         : std_logic_vector( c_MULT_ALU_PORTB_S-1 downto 0)                            ; --! Last value reached by y[k] at the end of last slice resized (unsigned)
signal   x_final_rsize        : std_logic_vector( c_MULT_ALU_PORTD_S-1 downto 0)                            ; --! Final value to reach by y[k] resized (unsigned)
signal   a_mant_k_rsize       : std_logic_vector( c_MULT_ALU_PORTA_S-1 downto 0)                            ; --! A[k]: filter mantissa parameter resized (unsigned)
signal   x_final_shift        : std_logic_vector( c_MULT_ALU_PORTC_S-1 downto 0)                            ; --! Final value to reach by y[k] resized (unsigned)

signal   w_k                  : std_logic_vector(c_MULT_ALU_RESULT_S-1 downto 0)                            ; --! Filter output (unsigned)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on Multiplier ALU inputs format
   -- ------------------------------------------------------------------------------------------------------
   x_init_rsize   <= std_logic_vector(resize(unsigned(i_x_init) ,  x_init_rsize'length));
   x_final_rsize  <= std_logic_vector(resize(unsigned(i_x_final),  x_final_rsize'length));
   a_mant_k_rsize <= std_logic_vector(resize(unsigned(i_a_mant_k), a_mant_k_rsize'length));

   x_final_shift(x_final_shift'high   downto g_A_EXP) <= std_logic_vector(resize(unsigned(i_x_final), x_final_shift'length - g_A_EXP));
   x_final_shift(           g_A_EXP-1 downto       0) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_DSP_L_SPLIT IpCore instantiation
   --!    w[k] = Min(Max(x_final * 2^(g_A_EXP) + (x_init - x_final) * a_mant_k[k mod c_PIXEL_ADC_NB_CYC]) ; 0) ; 2^(g_X_K_S + g_A_EXP) - 1)
   --!    y[k] = floor(w[k] * 2^(Y_K_S-g_X_K_S-g_A_EXP))
   -- ------------------------------------------------------------------------------------------------------
   I_dsp: entity nx.nx_dsp_l_split generic map
   (     SIGNED_MODE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type                     ('0' = unsigned,           '1' = signed)
         PRE_ADDER_OP         => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Pre-Adder operation           ('0' = add,                '1' = subtract)
         ALU_DYNAMIC_OP       => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU Dynamic operation enable  ('0' = ALU_STAT_OP used,   '1' = Port D LSB used)
         ALU_OP               => c_MULT_ALU_OP_ADD    , -- bit_vector(MULT_ALU_OP_S-1 downto 0)             ; --! ALU Static operation
         ALU_MUX              => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU swap operands             ('0' = no swap,            '1' = swap)
         Z_FEEDBACK_SHL12     => c_MULT_ALU_PRM_DIS   , -- bit                                              ; --! ALU shift of MUX_ALU input    (see below Z_FEEDBACK_SHL12 & MUX_X for configuration)
         ENABLE_SATURATION    => c_MULT_ALU_PRM_ENA   , -- bit                                              ; --! Saturation enable             ('0' = disable,            '1' = enable)
         SATURATION_RANK      => c_FILT_SAT_RANK      , -- bit_vector(5 downto 0)                           ; --! Extrem values reached on result bus and overflow management
                                                                                                              --!   unsigned: range from             0  to 2**(SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(SAT_RANK) to 2**(SAT_RANK)   - 1

         MUX_CI               => c_MULT_ALU_PRM_NU    , -- bit                                              ; --! Multiplexer ALU Carry In ('0' = ALU Carry In,            '1' = Cascaded ALU Carry In)
         MUX_A                => '0'                  , -- bit                                              ; --! Multiplexer Port A       ('0' = Port A,                  '1' = Cascaded Port A)
         MUX_B                => '0'                  , -- bit                                              ; --! Multiplexer Port B       ('0' = Port B,                  '1' = Cascaded Port B)
         MUX_P                => '1'                  , -- bit                                              ; --! Multiplexer Pre-Adder    ('0' = MUX_PORTB,               '1' = MUX_PORTB +/- Port D)
         MUX_Y                => '0'                  , -- bit                                              ; --! Multiplexer Multiplier   ('0' = MUX_PORTA * MUX_PRE_ADD, '1' = MUX_PORTB & MUX_PORTA)
         MUX_X                => "00"                 , -- bit_vector(1 downto 0)                           ; --! Multiplexer ALU operand  ("X0X" = Port C,                "010" = MUX_ALU,
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

   )     port map
   (     ck                   => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! Clock
         r                    => i_rst_sqm_pls_shape  , -- in     std_logic                                 ; --! Reset pipeline registers ('0' = Inactive, '1' = Active)
         rz                   => i_rst_sqm_pls_shape  , -- in     std_logic                                 ; --! Reset Z output register  ('0' = Inactive, '1' = Active)
         we                   => '1'                  , -- in     std_logic                                 ; --! Write Enable ('0' = Internal registers frozen, '1' = Normal operation)

         ci                   => '0'                  , -- in     std_logic                                 ; --! ALU Carry In
         a                    => a_mant_k_rsize       , -- in     slv( MULT_ALU_PORTA_S-1 downto 0)         ; --! Port A
         b                    => x_init_rsize         , -- in     slv( MULT_ALU_PORTB_S-1 downto 0)         ; --! Port B
         c                    => x_final_shift        , -- in     slv( MULT_ALU_PORTC_S-1 downto 0)         ; --! Port C
         d                    => x_final_rsize        , -- in     slv( MULT_ALU_PORTD_S-1 downto 0)         ; --! Port D

         cci                  => '0'                  , -- in     std_logic                                 ; --! Cascaded ALU Carry In
         cai                  => (others => '0')      , -- in     slv(MULT_ALU_CPORTA_S-1 downto 0)         ; --! Cascaded Port A
         cbi                  => (others => '0')      , -- in     slv( MULT_ALU_PORTB_S-1 downto 0)         ; --! Cascaded Port B
         czi                  => (others => '0')      , -- in     slv(MULT_ALU_RESULT_S-1 downto 0)         ; --! Cascaded Result Input

         co                   => open                 , -- out    std_logic                                 ; --! ALU Carry buffer           (MUX_CARRY_OUT registered output)
         co36                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 36
         co56                 => open                 , -- out    std_logic                                 ; --! Carry Output: Result bit 56
         ovf                  => open                 , -- out    std_logic                                 ; --! Overflow ('0' = No, '1' = Yes)
         z                    => w_k                  , -- out    slv(MULT_ALU_RESULT_S-1 downto 0)         ; --! Result buffer              (MUX_ALU       registered output)

         cco                  => open                 , -- out    std_logic                                 ; --! Cascaded ALU Carry buffer  (MUX_CARRY_OUT registered output)
         cao                  => open                 , -- out    slv(MULT_ALU_CPORTA_S-1 downto 0)         ; --! Cascaded Port A buffer     (MUX_PORTA     registered output)
         cbo                  => open                 , -- out    slv(MULT_ALU_PORTB_S -1 downto 0)         ; --! Cascaded Port B buffer     (MUX_PORTB     registered output)
         czo                  => open                   -- out    slv(MULT_ALU_RESULT_S-1 downto 0)           --! Cascaded Result buffer     (MUX_ALU       registered output)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   y[k]: filtered data out
   -- ------------------------------------------------------------------------------------------------------
   P_yk : process (i_rst_sqm_pls_shape, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_pls_shape = '1' then

         if c_PAD_REG_SET_AUTH = '0' then
            o_y_k <= (others => '0');

         else
            o_y_k <= std_logic_vector(to_unsigned(c_DAC_MDL_POINT/2**(g_X_K_S-g_Y_K_S) , o_y_k'length));

         end if;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         o_y_k <= w_k(g_A_EXP + g_X_K_S - 1 downto g_A_EXP + g_X_K_S - g_Y_K_S);

      end if;

   end process P_yk;

end architecture rtl;
