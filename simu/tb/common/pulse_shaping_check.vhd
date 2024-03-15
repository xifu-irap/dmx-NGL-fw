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
--!   @file                   pulse_shaping_check.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Pulse shaping check
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_model.all;

entity pulse_shaping_check is port (
         i_arst               : in     std_logic                                                            ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
         i_clk_sqm_dac        : in     std_logic                                                            ; --! SQUID MUX DAC: Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_sqm_dac_ana        : in     real                                                                 ; --! SQUID MUX DAC: Analog
         i_pls_shp_fc         : in     integer                                                              ; --! Pulse shaping cut frequency (Hz)

         o_err_num_pls_shp    : out    integer                                                                --! Pulse shaping error number
   );
end entity pulse_shaping_check;

architecture Behavioral of pulse_shaping_check is
constant c_ONE_REAL           : real   := 1.0                                                               ; --! One  real value
constant c_2PI_REAL           : real   := 2.0 * MATH_PI                                                     ; --! 2*Pi real value

constant c_PLS_CNT_MAX_VAL    : integer:= c_PIXEL_DAC_NB_CYC - 2                                            ; --! Pulse shaping counter: maximal value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL+1)+1                                  ; --! Pulse shaping counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 1                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)+1                                ; --! Pixel position: size bus (signed)

signal   sqm_dac_ana_r        : real_vector(0 to c_PIXEL_DAC_NB_CYC)                                        ; --! SQUID MUX DAC: Analog register
signal   sync_r               : std_logic                                                                   ; --! Pixel sequence synchronization register
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization rising edge

signal   pls_shp_fc_rsync     : integer                                                                     ; --! Pulse shaping cut frequency (Hz), resynchronized

signal   pls_cnt              : std_logic_vector(c_PLS_CNT_S-1 downto 0)                                    ; --! Pulse shaping counter
signal   pixel_pos            : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position

signal   cmd_exp              : real                                                                        ; --! Command expected
signal   coef_lp_filt         : real                                                                        ; --! Low pass filter coefficient
signal   lp_filter            : real                                                                        ; --! Low pass filter

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals register
   -- ------------------------------------------------------------------------------------------------------
   P_sig_reg : process (i_arst, i_clk_sqm_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         sqm_dac_ana_r     <= (others => c_ZERO_REAL);
         sync_r            <= c_I_SYNC_DEF;
         sync_re           <= c_LOW_LEV;

      elsif rising_edge(i_clk_sqm_dac) then
         sqm_dac_ana_r  <= i_sqm_dac_ana & sqm_dac_ana_r(0 to sqm_dac_ana_r'high-1);
         sync_r   <= i_sync;
         sync_re  <= not(sync_r) and i_sync;

      end if;

   end process P_sig_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse shaping counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt: process (i_arst, i_clk_sqm_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         pls_cnt     <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));
         pixel_pos   <= c_MINUSONE(pixel_pos'range);

      elsif rising_edge(i_clk_sqm_dac) then

         if (sync_re or pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_MAX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

         if sync_re = c_HGH_LEV then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Get low pass filter inputs
   -- ------------------------------------------------------------------------------------------------------
   P_get_lp_filt_in: process (i_arst, i_clk_sqm_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         cmd_exp  <= c_ZERO_REAL;
         pls_shp_fc_rsync  <= c_PLS_CUT_FREQ_DEF;

      elsif rising_edge(i_clk_sqm_dac) then

         if pls_cnt = c_ZERO(pls_cnt'range) then
            cmd_exp <= i_sqm_dac_ana;

         end if;

         if pixel_pos = std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length)) and pls_cnt = c_ZERO(pls_cnt'range) then
            pls_shp_fc_rsync <= i_pls_shp_fc;

         end if;

      end if;

   end process P_get_lp_filt_in;

   -- ------------------------------------------------------------------------------------------------------
   --!   Low pass filter coefficient
   -- ------------------------------------------------------------------------------------------------------
   coef_lp_filt <= c_ONE_REAL when pls_shp_fc_rsync = integer'high else
                   c_ONE_REAL / (c_ONE_REAL + real(c_CLK_ADC_FREQ)/( c_2PI_REAL * real(pls_shp_fc_rsync)));

   -- ------------------------------------------------------------------------------------------------------
   --!   Low pass filter calculation
   -- ------------------------------------------------------------------------------------------------------
   P_lp_filter: process (i_arst, i_clk_sqm_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         lp_filter   <= c_ZERO_REAL;

      elsif rising_edge(i_clk_sqm_dac) then
         lp_filter   <= coef_lp_filt * cmd_exp + (c_ONE_REAL - coef_lp_filt) * lp_filter;

      end if;

   end process P_lp_filter;

   -- ------------------------------------------------------------------------------------------------------
   --!   Error calculation
   -- ------------------------------------------------------------------------------------------------------
   P_err_num_pls_shp: process (i_arst, i_clk_sqm_dac)
   begin

      if i_arst = c_RST_LEV_ACT then
         o_err_num_pls_shp   <= c_ZERO_INT;

      elsif rising_edge(i_clk_sqm_dac) then
         if ((sqm_dac_ana_r(sqm_dac_ana_r'high) - lp_filter) > c_PLS_SHP_ERR_VAL) or ((sqm_dac_ana_r(sqm_dac_ana_r'high) - lp_filter) < -c_PLS_SHP_ERR_VAL) then
            o_err_num_pls_shp <= o_err_num_pls_shp + 1;

         end if;

      end if;

   end process P_err_num_pls_shp;

end architecture Behavioral;
