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
--!   @file                   rst_gen.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Reset generation
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_type.all;

entity rst_gen is generic (
         g_CNT_RST_NB_VAL     : integer                                                                       --! Counter for reset generation: number of value
   ); port (
         i_clock              : in     std_logic                                                            ; --! Clock
         o_reset              : out    std_logic                                                              --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
   );
end entity rst_gen;

architecture RTL of rst_gen is
constant c_CNT_RST_MAX_VAL    : integer := g_CNT_RST_NB_VAL - 3                                             ; --! Counter for reset generation: maximal value
constant c_CNT_RST_S          : integer := log2_ceil(c_CNT_RST_MAX_VAL + 1) + 1                             ; --! Counter for reset generation: size bus (signed)

signal   cnt_rst              : std_logic_vector(c_CNT_RST_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_CNT_RST_MAX_VAL, c_CNT_RST_S))               ; --! Counter for reset generation
signal   cnt_rst_msb_r_n      : std_logic := c_HGH_LEV                                                      ; --! Counter for reset generation MSB inverted register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset generation
   -- ------------------------------------------------------------------------------------------------------
   P_cnt_rst : process (i_clock)
   begin

      if rising_edge(i_clock) then
         if cnt_rst(cnt_rst'high) = c_LOW_LEV then
            cnt_rst  <= std_logic_vector(signed(cnt_rst) - 1);

         end if;

         cnt_rst_msb_r_n  <= not(cnt_rst(cnt_rst'high));

      end if;

   end process P_cnt_rst;

   o_reset <= cnt_rst_msb_r_n;

end architecture RTL;
