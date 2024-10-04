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
--!   @file                   in_rs_sqm_adc_dc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Data resynchronization on SQUID ADC Data clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

entity in_rs_sqm_adc_dc is port (
         i_sqm_adc_dc         : in     std_logic                                                            ; --! SQUID MUX ADC: Data clock

         i_sqm_adc_data       : in     std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data, no rsync
         i_sqm_adc_oor        : in     std_logic                                                            ; --! SQUID MUX ADC: Out of range, no rsync ('0'= No, '1'= under/over range)

         o_sqm_adc_data_rs_dc : out    std_logic_vector(c_SQM_ADC_DATA_S-1 downto 0)                        ; --! SQUID MUX ADC: Data, synchronized on SQUID ADC Data clock
         o_sqm_adc_oor_rs_dc  : out    std_logic                                                              --! SQUID MUX ADC: Out of range, synchronized on SQUID ADC Data clock

   );
end entity in_rs_sqm_adc_dc;

architecture RTL of in_rs_sqm_adc_dc is
signal   sqm_adc_data_r       : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_SQM_ADC_DATA_S-1 downto 0)                ; --! SQUID MUX ADC: Data register
signal   sqm_adc_oor_r        : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID MUX ADC: Out of range register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Resynchronization
   -- ------------------------------------------------------------------------------------------------------
   P_rsync : process (i_sqm_adc_dc)
   begin

      if rising_edge(i_sqm_adc_dc) then
         sqm_adc_data_r <= i_sqm_adc_data & sqm_adc_data_r(0 to sqm_adc_data_r'high-1);
         sqm_adc_oor_r  <= sqm_adc_oor_r(sqm_adc_oor_r'high-1 downto 0) & i_sqm_adc_oor;

      end if;

   end process P_rsync;

   o_sqm_adc_data_rs_dc <= sqm_adc_data_r(sqm_adc_data_r'high);
   o_sqm_adc_oor_rs_dc  <= sqm_adc_oor_r(sqm_adc_oor_r'high);

end architecture RTL;
