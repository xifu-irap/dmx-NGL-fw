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
--!   @file                   clock_model.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Periodic signals model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;

entity clock_model is generic (
         g_CLK_REF_PER        : time    := c_CLK_REF_PER_DEF                                                ; --! Reference Clock period
         g_SYNC_PER           : time    := c_SYNC_PER_DEF                                                   ; --! Pixel sequence synchronization period
         g_SYNC_SHIFT         : time    := c_SYNC_SHIFT_DEF                                                   --! Pixel sequence synchronization shift
   ); port (
         o_clk_ref            : out    std_logic                                                            ; --! Reference Clock
         o_sync               : out    std_logic                                                              --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
   );
end entity clock_model;

architecture Behavioral of clock_model is
constant c_CLK_PER_HALF       : time    := g_CLK_REF_PER/2                                                  ; --! Half clock period
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reference Clock generation
   -- ------------------------------------------------------------------------------------------------------
   P_o_clk_ref : process
   begin

      o_clk_ref <= c_HGH_LEV;
      wait for g_CLK_REF_PER - c_CLK_PER_HALF;
      o_clk_ref <= c_LOW_LEV;
      wait for c_CLK_PER_HALF;

   end process P_o_clk_ref;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence synchronization generation
   -- ------------------------------------------------------------------------------------------------------
   P_o_sync : process
   begin

      o_sync <= c_LOW_LEV;
      wait for g_SYNC_SHIFT;
      o_sync <= c_HGH_LEV;
      wait for c_SYNC_HIGH;
      o_sync <= c_LOW_LEV;
      wait for g_SYNC_PER - g_SYNC_SHIFT - c_SYNC_HIGH;

   end process P_o_sync;

end architecture Behavioral;
