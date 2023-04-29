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
--!   @file                   sqm_spi_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX SPI management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity sqm_spi_mgt is port (
         o_sqm_adc_spi_mosi   : out    std_logic                                                            ; --! SQUID MUX ADC: SPI Serial Data In Out
         o_sqm_adc_spi_sclk   : out    std_logic                                                            ; --! SQUID MUX ADC: SPI Serial Clock (CPOL = '0', CPHA = '0')
         o_sqm_adc_spi_cs_n   : out    std_logic                                                              --! SQUID MUX ADC: SPI Chip Select ('0' = Active, '1' = Inactive)

   );
end entity sqm_spi_mgt;

architecture RTL of sqm_spi_mgt is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX ADC, static configuration without SPI
   --    @Req : DRE-DMX-FW-REQ-0100
   -- ------------------------------------------------------------------------------------------------------
   o_sqm_adc_spi_mosi   <= '1';     -- Duty Cycle Stabilizer ('0' = Disable, '1' = Enable)
   o_sqm_adc_spi_sclk   <= '1';     -- Data format ('0' = Binary, '1' = Twos complement)
   o_sqm_adc_spi_cs_n   <= '1';     -- Static configuration ('0' = No, '1' = Yes)

end architecture RTL;
