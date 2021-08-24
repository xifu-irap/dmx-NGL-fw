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
--!   @file                   squid_dac_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid DAC management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;

entity squid_dac_mgt is port
   (     i_rst_sq1_pls_shape  : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_sq1_pls_shape  : in     std_logic                                                            ; --! SQUID1 pulse shaping Clock

         i_sync_rpls          : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on pulse shaping Clock

         o_sq1_dac_data       : out    std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC - Data
         o_sq2_dac_mux        : out    std_logic_vector(c_SQ2_DAC_MUX_S -1 downto 0)                          --! SQUID2 DAC - Multiplexer

   );
end entity squid_dac_mgt;

architecture RTL of squid_dac_mgt is

begin

   -- TODO
   o_sq1_dac_data    <= (others => '0');
   o_sq2_dac_mux     <= (others => '0');

end architecture RTL;
