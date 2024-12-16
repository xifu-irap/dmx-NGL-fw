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
--!   @file                   squid_adc_bug_bypass.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX DAC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_adc_bug_bypass is generic (
         g_ADC_HW_BUG_BYPASS  : std_logic := c_LOW_LEV                                                        --! ADC harware bug bypass ('0' = No bug, '1' = Bug)
   ); port (
         i_rst_sqm_adc_dac_lc : in     std_logic                                                            ; --! Local reset for SQUID ADC/DAC, de-assertion on system clock
         i_clk_sqm_adc_dac    : in     std_logic                                                            ; --! SQUID ADC/DAC internal Clock

         i_sqm_adc_data_rs_dc : in     std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data, synchronized on SQUID ADC Data clock
         i_sqm_adc_oor_rs_dc  : in     std_logic                                                            ; --! SQUID MUX ADC: Out of range, synchronized on SQUID ADC Data clock

         o_sqm_adc_data_cor   : out    std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data corrected
         o_sqm_adc_oor_cor    : out    std_logic                                                              --! SQUID MUX ADC: Out of range corrected

   );
end entity squid_adc_bug_bypass;

architecture RTL of squid_adc_bug_bypass is
constant c_SQM_ADC_DTA_BIT_DF : integer:= c_SQM_ADC_DATA_S-2                                                ; --! SQUID ADC data bit number in default
constant c_SQM_ADC_DTA_TRS_V  : std_logic_vector(c_SQM_ADC_DATA_S   downto 0) :=
                                std_logic_vector(to_unsigned( 2048, c_SQM_ADC_DATA_S+1))                    ; --! SQUID ADC data threshold for bug detect

signal   sqm_adc_data_diff    : std_logic_vector(c_SQM_ADC_DATA_S downto 0)                                 ; --! SQUID ADC data difference
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID ADC: Out of range corrected
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_adc_oor_cor : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
   begin

      if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
         o_sqm_adc_oor_cor  <= c_LOW_LEV;

      elsif rising_edge(i_clk_sqm_adc_dac) then
         o_sqm_adc_oor_cor  <= i_sqm_adc_oor_rs_dc;

      end if;

   end process P_sqm_adc_oor_cor;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID ADC: Data corrected
   -- ------------------------------------------------------------------------------------------------------
   G_adc_no_bug: if g_ADC_HW_BUG_BYPASS = c_LOW_LEV generate

      --! ADC data with no bug bypass
      P_sqm_adc_data_cor : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
      begin

         if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
            o_sqm_adc_data_cor <= (others => c_LOW_LEV);

         elsif rising_edge(i_clk_sqm_adc_dac) then
            o_sqm_adc_data_cor  <= i_sqm_adc_data_rs_dc;

         end if;

      end process P_sqm_adc_data_cor;

   end generate G_adc_no_bug;

   G_adc_bug_bypass: if g_ADC_HW_BUG_BYPASS = c_HGH_LEV generate

      --! SQUID ADC data difference
      sqm_adc_data_diff <= std_logic_vector(resize(signed(i_sqm_adc_data_rs_dc), sqm_adc_data_diff'length) - resize(signed(o_sqm_adc_data_cor), sqm_adc_data_diff'length));

      --! ADC data with bug bypass
      P_sqm_adc_data_cor : process (i_rst_sqm_adc_dac_lc, i_clk_sqm_adc_dac)
      begin

         if i_rst_sqm_adc_dac_lc = c_RST_LEV_ACT then
            o_sqm_adc_data_cor <= (others => c_LOW_LEV);

         elsif rising_edge(i_clk_sqm_adc_dac) then
            o_sqm_adc_data_cor(o_sqm_adc_data_cor'high)         <= i_sqm_adc_data_rs_dc(o_sqm_adc_data_cor'high);
            o_sqm_adc_data_cor(c_SQM_ADC_DTA_BIT_DF-1 downto 0) <= i_sqm_adc_data_rs_dc(c_SQM_ADC_DTA_BIT_DF-1 downto 0);

            if  (o_sqm_adc_data_cor(c_SQM_ADC_DTA_BIT_DF) or i_sqm_adc_data_rs_dc(c_SQM_ADC_DTA_BIT_DF)) = c_LOW_LEV   and
               ((signed(sqm_adc_data_diff) > signed(c_SQM_ADC_DTA_TRS_V)) or
               ((signed(sqm_adc_data_diff) + signed(c_SQM_ADC_DTA_TRS_V)) < signed(c_ZERO(sqm_adc_data_diff'range)))) then
               o_sqm_adc_data_cor(c_SQM_ADC_DTA_BIT_DF) <= c_HGH_LEV;

            else
               o_sqm_adc_data_cor(c_SQM_ADC_DTA_BIT_DF) <= i_sqm_adc_data_rs_dc(c_SQM_ADC_DTA_BIT_DF);

            end if;

         end if;

      end process P_sqm_adc_data_cor;

   end generate G_adc_bug_bypass;

end architecture RTL;
