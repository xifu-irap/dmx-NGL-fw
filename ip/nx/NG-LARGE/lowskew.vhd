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
--!   @file                   lowskew.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Low skew network connexion
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library nx;
use     nx.nxpackage.all;

entity lowskew is port
   (     i_sig                : in     std_logic                                                            ; --! Signal
         o_sig_lowskew        : out    std_logic                                                              --! Signal connected to lowskew network
   );
end entity lowskew;

architecture RTL of lowskew is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_BD IpCore instantiation
   -- ------------------------------------------------------------------------------------------------------
   I_lowskew: entity nx.nx_bd generic map
   (     mode                 => "local_lowskew"        -- string := "local_lowskew"                        ; --! Mode ("local_lowskew", “global_lowskew”)
   )     port map
   (     i                    => i_sig                , -- in     std_logic                                 ; --! Signal
         o                    => o_sig_lowskew          -- out    std_logic                                   --! Signal connected to lowskew network
   );

end architecture RTL;
