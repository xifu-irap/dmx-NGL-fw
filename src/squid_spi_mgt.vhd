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
--!   @file                   squid_spi_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid SPI management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;

entity squid_spi_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         o_sq1_adc_spi_mosi   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Serial Data In Out
         o_sq1_adc_spi_sclk   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Serial Clock (CPOL = ‘0’, CPHA = ’0’)
         o_sq1_adc_spi_cs_n   : out    std_logic                                                            ; --! SQUID1 ADC - SPI Chip Select ('0' = Active, '1' = Inactive)

         o_sq2_dac_data       : out    std_logic                                                            ; --!	SQUID2 DAC - Serial Data
         o_sq2_dac_sclk       : out    std_logic                                                            ; --!	SQUID2 DAC - Serial Clock
         o_sq2_dac_sync_n     : out    std_logic                                                              --!	SQUID2 DAC - Frame Synchronization ('0' = Active, '1' = Inactive)

   );
end entity squid_spi_mgt;

architecture RTL of squid_spi_mgt is

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid 1 ADC, static configuration without SPI
   -- ------------------------------------------------------------------------------------------------------
   o_sq1_adc_spi_mosi   <= '0';     -- Data format ('0' = Binary, '1' = Twos complement)
   o_sq1_adc_spi_sclk   <= '1';     -- Duty Cycle Stabilizer ('0' = Disable, '1' = Enable)
   o_sq1_adc_spi_cs_n   <= '1';     -- Static configuration ('0' = No, '1' = Yes)

   -- TODO
   o_sq2_dac_data       <= '0';
   o_sq2_dac_sclk       <= '0';
   o_sq2_dac_sync_n     <= '1';

end architecture RTL;
