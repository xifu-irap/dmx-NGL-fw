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
--!   @file                   mem_scrubbing.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Memory scrubbing with ping-pong buffer bit for address management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;

entity mem_scrubbing is generic
   (     c_MEM_ADD_S          : integer                                                                     ; --! Memory address size (no ping-pong buffer bit)
         c_MEM_DATA_S         : integer                                                                       --! Memory Data to write in memory size
   ); port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_mem_no_scrub       : in     t_mem( add(c_MEM_ADD_S-1 downto 0), data_w(c_MEM_DATA_S-1 downto 0)) ; --! Memory signals no scrubbing
         o_mem_with_scrub     : out    t_mem( add(c_MEM_ADD_S   downto 0), data_w(c_MEM_DATA_S-1 downto 0))   --! Memory signals with scrubbing and ping-pong buffer bit for address management
   );
end entity mem_scrubbing;

architecture RTL of mem_scrubbing is
signal   mem_add_pp           : std_logic                                                                   ; --! Memory : ping-pong buffer bit for address management
signal   mem_add_scrub        : std_logic_vector(c_MEM_ADD_S   downto 0)                                    ; --! Memory : address with ping-pong buffer bit scrubbed

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory signals management
   -- ------------------------------------------------------------------------------------------------------
   P_mem_sig : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_add_pp           <= c_MEM_STR_ADD_PP_DEF;
         mem_add_scrub        <= (others => '0');
         o_mem_with_scrub.add <= (others => '0');
         o_mem_with_scrub.we  <= '0';

      elsif rising_edge(i_clk) then
         if (i_mem_no_scrub.pp and i_mem_no_scrub.we and i_mem_no_scrub.cs) = '1' then
            mem_add_pp <= not(mem_add_pp);

         end if;

         if i_mem_no_scrub.cs = '1' then
            o_mem_with_scrub.add <= (i_mem_no_scrub.we xor mem_add_pp) & i_mem_no_scrub.add;
            o_mem_with_scrub.we  <= i_mem_no_scrub.we;

         else
            mem_add_scrub  <= std_logic_vector(unsigned(mem_add_scrub) + 1);
            o_mem_with_scrub.add <= mem_add_scrub;
            o_mem_with_scrub.we  <= '0';

         end if;

      end if;

   end process P_mem_sig;

   o_mem_with_scrub.pp     <= mem_add_pp;
   o_mem_with_scrub.cs     <= '1';
   o_mem_with_scrub.data_w <= i_mem_no_scrub.data_w;

end architecture RTL;
