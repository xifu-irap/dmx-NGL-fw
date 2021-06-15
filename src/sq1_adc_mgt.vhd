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
--!   @file                   sq1_adc_mgt.vhd
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

entity sq1_adc_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_sq1_adc        : in     std_logic                                                            ; --! SQUID1 ADC Clock

         i_sync_radc          : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on SQUID1 ADC Clock
         i_sq1_adc_data_radc  : in     std_logic_vector(c_SQ1_ADC_DATA_S-1 downto 0)                        ; --! SQUID1 ADC - Data, synchronized on SQUID1 ADC Clock
         i_sq1_adc_oor_radc   : in     std_logic                                                              --! SQUID1 ADC - Out of range, sync. on SQUID1 ADC Clock (‘0’= No, ‘1’= under/over range)
   );
end entity sq1_adc_mgt;

architecture RTL of sq1_adc_mgt is
signal   sync_radc_r          : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on SQUID1 ADC Clock, register
signal   sync_radc_re         : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on SQUID1 ADC Clock, rising edge detect

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence synchronization signal – Rising Edge detect
   -- ------------------------------------------------------------------------------------------------------
   P_sync_radc_re : process (i_rst, i_clk_sq1_adc)
   begin

      if i_rst = '1' then
         sync_radc_r    <= c_I_SYNC_DEF;
         sync_radc_re   <= '0';

      elsif rising_edge(i_clk_sq1_adc) then
         sync_radc_r    <= i_sync_radc;
         sync_radc_re   <= not(sync_radc_r) and i_sync_radc;

      end if;

   end process P_sync_radc_re;


end architecture rtl;
