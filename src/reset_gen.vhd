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
--!   @file                   reset_gen.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Reset generation
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

entity reset_gen is generic
   (     g_FF_RESET_NB        : integer                                                                       --! Flip-Flop number used for generated reset
   ); port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clock              : in     std_logic                                                            ; --! Clock
         i_ck_rdy             : in     std_logic                                                            ; --! Clock ready ('0' = Not ready, '1' = Ready)

         o_reset              : out    std_logic                                                              --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );
end entity reset_gen;

architecture RTL of reset_gen is
signal   reset                : std_logic_vector(g_FF_RESET_NB-1 downto 0)                                  ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset generation
   -- ------------------------------------------------------------------------------------------------------
   P_reset : process (i_arst_n, i_clock)
   begin

      if i_arst_n = '0' then
         reset <= (others => '1');

      elsif rising_edge(i_clock) then
         reset <= reset(reset'high-1 downto 0) & not(i_ck_rdy);

      end if;

   end process P_reset;

   o_reset <= reset(reset'high);

end architecture RTL;
