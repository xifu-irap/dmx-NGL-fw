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
--!   @file                   in_rs_clk_sq1_adc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Data resynchronization on SQUID1 ADC Clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;

entity in_rs_clk_sq1_adc is port
   (     i_rst_sq1_adc        : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc        : in     std_logic                                                            ; --! SQUID1 ADC Clock

         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_c0_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 0 - Data
         i_c0_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c1_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 1 - Data
         i_c1_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c2_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 2 - Data
         i_c2_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 - Out of range (‘0’ = No, ‘1’ = under/over range)
         i_c3_sq1_adc_data    : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC, col. 3 - Data
         i_c3_sq1_adc_oor     : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 - Out of range (‘0’ = No, ‘1’ = under/over range)

         o_sync_radc          : out    std_logic                                                            ; --! Pixel sequence synchronization, synchronized on SQUID1 ADC Clock
         o_sq1_adc_data_radc  : out    t_sq1_adc_data_v(0 to c_DMX_NB_COL-1)                                ; --! SQUID1 ADC - Data, synchronized on SQUID1 ADC Clock
         o_sq1_adc_oor_radc   : out    std_logic_vector(c_DMX_NB_COL-1 downto 0)                              --! SQUID1 ADC - Out of range, sync. on SQUID1 ADC Clock (‘0’= No, ‘1’= under/over range)
   );
end entity in_rs_clk_sq1_adc;

architecture RTL of in_rs_clk_sq1_adc is
signal   sync_r               : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)

signal   c0_sq1_adc_data_r    : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC, col. 0 - Data register
signal   c1_sq1_adc_data_r    : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC, col. 1 - Data register
signal   c2_sq1_adc_data_r    : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC, col. 2 - Data register
signal   c3_sq1_adc_data_r    : t_sq1_adc_data_v(0 to c_FF_RSYNC_NB-1)                                      ; --! SQUID1 ADC, col. 3 - Data register

signal   c0_sq1_adc_oor_r     : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 0 - Out of range register (‘0’ = No, ‘1’ = under/over range)
signal   c1_sq1_adc_oor_r     : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 1 - Out of range register (‘0’ = No, ‘1’ = under/over range)
signal   c2_sq1_adc_oor_r     : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 2 - Out of range register (‘0’ = No, ‘1’ = under/over range)
signal   c3_sq1_adc_oor_r     : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID1 ADC, col. 3 - Out of range register (‘0’ = No, ‘1’ = under/over range)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_rst_sq1_adc, i_clk_sq1_adc)
   begin

      if i_rst_sq1_adc = '1' then
         sync_r            <= (others => c_I_SYNC_DEF);

         c0_sq1_adc_data_r <= (others => c_I_SQ1_ADC_DATA_DEF);
         c1_sq1_adc_data_r <= (others => c_I_SQ1_ADC_DATA_DEF);
         c2_sq1_adc_data_r <= (others => c_I_SQ1_ADC_DATA_DEF);
         c3_sq1_adc_data_r <= (others => c_I_SQ1_ADC_DATA_DEF);

         c0_sq1_adc_oor_r  <= (others => c_I_SQ1_ADC_OOR_DEF);
         c1_sq1_adc_oor_r  <= (others => c_I_SQ1_ADC_OOR_DEF);
         c2_sq1_adc_oor_r  <= (others => c_I_SQ1_ADC_OOR_DEF);
         c3_sq1_adc_oor_r  <= (others => c_I_SQ1_ADC_OOR_DEF);

      elsif rising_edge(i_clk_sq1_adc) then
         sync_r            <= sync_r(                      sync_r'high-1 downto 0) & i_sync;

         c0_sq1_adc_data_r <= i_c0_sq1_adc_data & c0_sq1_adc_data_r(0 to c0_sq1_adc_data_r'high-1);
         c1_sq1_adc_data_r <= i_c1_sq1_adc_data & c1_sq1_adc_data_r(0 to c1_sq1_adc_data_r'high-1);
         c2_sq1_adc_data_r <= i_c2_sq1_adc_data & c2_sq1_adc_data_r(0 to c2_sq1_adc_data_r'high-1);
         c3_sq1_adc_data_r <= i_c3_sq1_adc_data & c3_sq1_adc_data_r(0 to c3_sq1_adc_data_r'high-1);         

         c0_sq1_adc_oor_r  <= c0_sq1_adc_oor_r(c0_sq1_adc_oor_r'high-1 downto 0) & i_c0_sq1_adc_oor;
         c1_sq1_adc_oor_r  <= c1_sq1_adc_oor_r(c1_sq1_adc_oor_r'high-1 downto 0) & i_c1_sq1_adc_oor;
         c2_sq1_adc_oor_r  <= c2_sq1_adc_oor_r(c2_sq1_adc_oor_r'high-1 downto 0) & i_c2_sq1_adc_oor;
         c3_sq1_adc_oor_r  <= c3_sq1_adc_oor_r(c3_sq1_adc_oor_r'high-1 downto 0) & i_c3_sq1_adc_oor;

      end if;

   end process P_rsync;

   o_sync_radc             <= sync_r(sync_r'high);

   o_sq1_adc_data_radc(0)  <= c0_sq1_adc_data_r(c0_sq1_adc_data_r'high);
   o_sq1_adc_data_radc(1)  <= c1_sq1_adc_data_r(c1_sq1_adc_data_r'high);
   o_sq1_adc_data_radc(2)  <= c2_sq1_adc_data_r(c2_sq1_adc_data_r'high);
   o_sq1_adc_data_radc(3)  <= c3_sq1_adc_data_r(c3_sq1_adc_data_r'high);

   o_sq1_adc_oor_radc(0)   <= c0_sq1_adc_oor_r( c0_sq1_adc_oor_r'high);
   o_sq1_adc_oor_radc(1)   <= c1_sq1_adc_oor_r( c1_sq1_adc_oor_r'high);
   o_sq1_adc_oor_radc(2)   <= c2_sq1_adc_oor_r( c2_sq1_adc_oor_r'high);
   o_sq1_adc_oor_radc(3)   <= c3_sq1_adc_oor_r( c3_sq1_adc_oor_r'high);

end architecture rtl;
