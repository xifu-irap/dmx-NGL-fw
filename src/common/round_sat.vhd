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
--!   @file                   round_sat.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Round and saturation on 1 clock cycle. Carry on LSB.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity round_sat is generic (
         g_RST_LEV_ACT        : std_logic                                                                   ; --! Reset level activation value
         g_DATA_CARRY_S       : integer                                                                       --! Data with carry bus size
   ); port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_data_carry         : in     std_logic_vector(g_DATA_CARRY_S-1 downto 0)                          ; --! Data with carry on lsb (signed)

         o_data_rnd_sat       : out    std_logic_vector(g_DATA_CARRY_S-2 downto 0)                            --! Data rounded with saturation (signed)
   );
end entity round_sat;

architecture RTL of round_sat is
constant c_LOW_LEV            : std_logic := '0'                                                            ; --! Low  level value
constant c_HGH_LEV            : std_logic := not(c_LOW_LEV)                                                 ; --! High level value
constant c_ZERO               : std_logic_vector(g_DATA_CARRY_S-2 downto 0) := (others => '0')              ; --! Zero value

signal   data_round           : std_logic_vector(g_DATA_CARRY_S-2 downto 0)                                 ; --! Data rounded

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Data rounded
   -- ------------------------------------------------------------------------------------------------------
   data_round <= std_logic_vector(unsigned(i_data_carry(i_data_carry'high downto 1)) +
                           resize(unsigned('0' & i_data_carry(0 downto 0)), data_round'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Data rounded with saturation
   -- ------------------------------------------------------------------------------------------------------
   P_data_rnd_sat : process (i_rst, i_clk)
   begin

      if i_rst = g_RST_LEV_ACT then
         o_data_rnd_sat <= c_ZERO;

      elsif rising_edge(i_clk) then

         -- Saturation on maximum value
         if (not(i_data_carry(i_data_carry'high)) and data_round(data_round'high)) = c_HGH_LEV then
            o_data_rnd_sat(o_data_rnd_sat'high)             <= c_LOW_LEV;
            o_data_rnd_sat(o_data_rnd_sat'high-1 downto 0)  <= (others => c_HGH_LEV);

         else
            o_data_rnd_sat <= data_round;

         end if;

      end if;

   end process P_data_rnd_sat;

end architecture RTL;
