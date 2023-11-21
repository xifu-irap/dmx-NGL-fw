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
--!   @file                   sqm_dac_sys.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX DAC signals synchronized on system clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sqm_dac_sys is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization (System Clock)
         i_plsss              : in     std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                      ; --! SQUID MUX feedback pulse shaping set (System Clock)

         o_sync_rs_rsys       : out    std_logic                                                            ; --! Pixel sequence synchronization register (System Clock)
         o_plsss_rsys         : out    std_logic_vector(c_DFLD_PLSSS_PLS_S-1 downto 0)                        --! SQUID MUX feedback pulse shaping set register (System Clock)
   );
end entity sqm_dac_sys;

architecture RTL of sqm_dac_sys is
attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_sync_rs_rsys        : signal is true                                   ; --! Disabling signal optimization: o_sync_rs_rsys

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs registered on system clock
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sys: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sync_rs_rsys <= c_I_SYNC_DEF;
         o_plsss_rsys   <= c_EP_CMD_DEF_PLSSS;

      elsif rising_edge(i_clk) then
         o_sync_rs_rsys <= i_sync_rs;
         o_plsss_rsys   <= i_plsss;

      end if;

   end process P_reg_sys;

end architecture RTL;
