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
--!   @file                   adder_sat.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Adder and saturation on 1 clock cycle
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity adder_sat is generic (
         g_RST_LEV_ACT        : std_logic                                                                   ; --! Reset level activation value
         g_DATA_S             : integer                                                                       --! Data bus size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_data_fst           : in     std_logic_vector(g_DATA_S-1 downto 0)                                ; --! Data first (signed)
         i_data_sec           : in     std_logic_vector(g_DATA_S-1 downto 0)                                ; --! Data second (signed)

         o_data_add_sat       : out    std_logic_vector(g_DATA_S-1 downto 0)                                  --! Data added with saturation (signed)
   );
end entity adder_sat;

architecture RTL of adder_sat is
signal   data_add             : std_logic_vector(g_DATA_S-1 downto 0)                                       ; --! Data added

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Data added
   -- ------------------------------------------------------------------------------------------------------
   data_add <= std_logic_vector(signed(i_data_fst) + signed(i_data_sec));

   -- ------------------------------------------------------------------------------------------------------
   --!   Data added with saturation
   -- ------------------------------------------------------------------------------------------------------
   P_data_add_sat : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         o_data_add_sat <= (others => '0');

      elsif rising_edge(i_clk) then

         -- Saturation on minimum value
         if    (    i_data_fst(i_data_fst'high)  and     i_data_sec(i_data_sec'high)  and not(data_add(data_add'high))) = '1' then
            o_data_add_sat(o_data_add_sat'high)            <= '1';
            o_data_add_sat(o_data_add_sat'high-1 downto 0) <= (others => '0');

         -- Saturation on maximum value
         elsif (not(i_data_fst(i_data_fst'high)) and not(i_data_sec(i_data_sec'high)) and     data_add(data_add'high))  = '1' then
            o_data_add_sat(o_data_add_sat'high)            <= '0';
            o_data_add_sat(o_data_add_sat'high-1 downto 0) <= (others => '1');

         else
            o_data_add_sat <= data_add;

         end if;

      end if;

   end process P_data_add_sat;

end architecture RTL;
