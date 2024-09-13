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
use     work.pkg_type.all;
use     work.pkg_project.all;

entity pulse_shaping is generic (
         g_SQM_DATA_COMP      : std_logic                                                                   ; --! SQUID MUX data complemented ('0' = No, '1' = Yes)
         g_X_K_S              : integer                                                                     ; --! Data in bus size (<= c_MULT_ALU_PORTB_S-1)
         g_A_EXP              : integer                                                                     ; --! A[k]: filter exponent parameter (<= c_MULT_ALU_PORTC_S-g_X_K_S-1)
         g_Y_K_S              : integer                                                                       --! y[k]: filtered data out bus size
   ); port (
         i_rst_sqm_adc_dac_lc : in     std_logic                                                            ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID MUX ADC/DAC internal Clock
         i_x_init             : in     std_logic_vector(g_X_K_S-1 downto 0)                                 ; --! Last value reached by y[k] at the end of last slice (signed)
         i_x_final            : in     std_logic_vector(g_X_K_S-1 downto 0)                                 ; --! Final value to reach by y[k] (signed)
         i_a_mant_k           : in     std_logic_vector(g_A_EXP-1 downto 0)                                 ; --! A[k]: filter mantissa parameter (unsigned)
         o_y_k                : out    std_logic_vector(g_Y_K_S-1 downto 0)                                   --! y[k]: filtered data out (unsigned)
   );
end entity pulse_shaping;

architecture RTL of pulse_shaping is
constant c_Y_K_RST_VAL        : integer := c_DAC_MDL_POINT/2**(g_X_K_S-g_Y_K_S)                             ; --! y[k]: filtered data out reset value

signal   x_init_rsize         : std_logic_vector(g_X_K_S   downto 0)                                        ; --! Last value reached by y[k] at the end of last slice resized (unsigned)
signal   x_final_rsize        : std_logic_vector(g_X_K_S   downto 0)                                        ; --! Final value to reach by y[k] resized (unsigned)
signal   a_mant_k_rsize       : std_logic_vector(g_A_EXP   downto 0)                                        ; --! A[k]: filter mantissa parameter resized (unsigned)
signal   x_final_shift        : std_logic_vector(c_MULT_ALU_PORTC_S-1 downto 0)                             ; --! Final value to reach by y[k] resized (unsigned)

signal   w_k                  : std_logic_vector(g_Y_K_S   downto 0)                                        ; --! Filter output (unsigned)
signal   w_k_r                : std_logic_vector(g_Y_K_S-1 downto 0)                                        ; --! Filter output register
signal   y_k                  : std_logic_vector(g_Y_K_S-1 downto 0)                                        ; --! Filtered data out with potential complementation

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on Multiplier ALU inputs format
   -- ------------------------------------------------------------------------------------------------------
   x_init_rsize   <= std_logic_vector(resize(  signed(i_x_init) ,  x_init_rsize'length));
   x_final_rsize  <= std_logic_vector(resize(  signed(i_x_final),  x_final_rsize'length));
   a_mant_k_rsize <= std_logic_vector(resize(unsigned(i_a_mant_k), a_mant_k_rsize'length));

   x_final_shift(x_final_shift'high   downto g_A_EXP) <= std_logic_vector(resize(signed(i_x_final), x_final_shift'length - g_A_EXP));
   x_final_shift(           g_A_EXP-1 downto       0) <= c_ZERO(g_A_EXP-1 downto 0);

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_DSP_L_SPLIT IpCore instantiation
   --!    w[k] = Min(Max(x_final * 2^(g_A_EXP) + (x_init - x_final) * a_mant_k[k mod c_PIXEL_ADC_NB_CYC]) ; 0) ; 2^(g_X_K_S + g_A_EXP) - 1)
   --!    y[k] = floor(w[k] * 2^(Y_K_S-g_X_K_S-g_A_EXP))
   -- ------------------------------------------------------------------------------------------------------
   I_dsp: entity work.dsp generic map (
         g_PORTA_S            => g_A_EXP+1            , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => g_X_K_S+1            , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_MULT_ALU_PORTC_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => g_Y_K_S+1            , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_LIN_SAT            => c_MULT_ALU_LSAT_ENA  , -- integer range 0 to 1                             ; --! Linear saturation (0 = Disable, 1 = Enable)
         g_SAT_RANK           => c_MULT_ALU_SAT_NU    , -- integer                                          ; --! Extrem values reached on result bus, not used if linear saturation enabled
                                                                                                              --!     range from -2**(g_SAT_RANK-1) to 2**(g_SAT_RANK-1) - 1
         g_PRE_ADDER_OP       => c_HGH_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst_sqm_adc_dac_lc , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk_sqm_adc_dac    , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => a_mant_k_rsize       , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => x_init_rsize         , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => x_final_shift        , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => x_final_rsize        , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => w_k                  , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on Multiplier ALU inputs format
   -- ------------------------------------------------------------------------------------------------------
   P_w_k_r : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
         w_k_r <= std_logic_vector(to_unsigned(c_Y_K_RST_VAL, w_k_r'length));

      elsif rising_edge(i_clk_sqm_adc_dac) then
         w_k_r <= w_k(w_k_r'range);

      end if;

   end process P_w_k_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Filtered data out with potential complementation (unsigned)
   --     y_k unsigned output adapted in order to get the correspondence:
   --     - w_k = -2^(c_SQM_DAC_DATA_S-1)   -> y_k = 0                      (DAC analog output = - Vref)
   --     - w_k =  2^(c_SQM_DAC_DATA_S-1)-1 -> y_k = 2^(c_SQM_DAC_DATA_S)-1 (DAC analog output =   Vref)
   --     Either: y_k = w_k + 2^(c_SQM_DAC_DATA_S-1)
   -- ------------------------------------------------------------------------------------------------------
   -- Case SQUID MUX data not complemented
   G_sqm_dta_comp_n: if g_SQM_DATA_COMP = c_LOW_LEV generate
      P_yk : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
      begin

         if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
            y_k <= std_logic_vector(to_unsigned(c_Y_K_RST_VAL, y_k'length));

         elsif rising_edge(i_clk_sqm_adc_dac) then
            y_k <= not(w_k_r(w_k_r'high)) & w_k_r(w_k_r'high-1 downto 0);

         end if;

      end process P_yk;

   end generate G_sqm_dta_comp_n;

   -- Case SQUID MUX data complemented
   G_sqm_dta_comp: if g_SQM_DATA_COMP = c_HGH_LEV generate
      P_yk : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
      begin

         if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
               y_k <= std_logic_vector(to_unsigned(c_Y_K_RST_VAL, y_k'length));

         elsif rising_edge(i_clk_sqm_adc_dac) then
            if w_k_r = c_ZERO(w_k_r'range) then
               y_k(y_k'high) <= c_HGH_LEV;

            else
               y_k(y_k'high) <= w_k_r(w_k_r'high);

            end if;

            if (w_k_r(w_k_r'high) = c_HGH_LEV and w_k_r(w_k_r'high-1 downto 0) = c_ZERO(w_k_r'high-1 downto 0)) then
               y_k(y_k'high-1 downto 0) <= (others => c_HGH_LEV);

            else
               y_k(y_k'high-1 downto 0) <= std_logic_vector(signed(c_ZERO(y_k'high-1 downto 0)) - signed(w_k_r(y_k'high-1 downto 0)));

            end if;

         end if;

      end process P_yk;

   end generate G_sqm_dta_comp;

   -- ------------------------------------------------------------------------------------------------------
   --!   y[k]: filtered data out (unsigned)
   -- ------------------------------------------------------------------------------------------------------
   P_o_yk : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then

         if c_PAD_REG_SET_AUTH = c_LOW_LEV then
            o_y_k <= c_ZERO(o_y_k'range);

         else
            o_y_k <= std_logic_vector(to_unsigned(c_Y_K_RST_VAL, o_y_k'length));

         end if;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         o_y_k <= y_k;

      end if;

   end process P_o_yk;

end architecture RTL;
