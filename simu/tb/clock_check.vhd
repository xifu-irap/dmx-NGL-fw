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
--!   @file                   clock_check.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Clock parameters check
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_model.all;

entity clock_check is generic (
         g_CLK_PER_L          : time                                                                        ; --! Low  level clock period expected time
         g_CLK_PER_H          : time                                                                        ; --! High level clock period expected time
         g_CLK_ST_ENA         : std_logic                                                                   ; --! Clock state value when enable goes to active
         g_CLK_ST_DIS         : std_logic                                                                     --! Clock state value when enable goes to inactive
   ); port (
         i_clk                : in     std_logic                                                            ; --! Clock
         i_ena                : in     std_logic                                                            ; --! Enable ('0' = Inactive, '1' = Active)
         i_chk_osc_ena_l      : in     std_logic                                                            ; --! Check oscillation on clock when enable inactive ('0' = No, '1' = Yes)

         o_err_n_clk_chk      : out    integer_vector(0 to c_ERR_N_CLK_CHK_S-1)                               --! Clock check error number:
                                                                                                              --!  - Position 4: clock state error when enable goes to active
                                                                                                              --!  - Position 3: clock state error when enable goes to inactive
                                                                                                              --!  - Position 2: low  level clock period timing error
                                                                                                              --!  - Position 1: high level clock period timing error
                                                                                                              --!  - Position 0: clock oscillation error when enable is inactive
   );
end entity clock_check;

architecture Behavioral of clock_check is
signal   clk_delay            : std_logic                                                                   ; --! Clock delayed

signal   err_n_clk_st_ena_h   : integer                                                                     ; --! Number of clock state error when enable goes to active
signal   err_n_clk_st_ena_l   : integer                                                                     ; --! Number of clock state error when enable goes to inactive
signal   err_n_clk_per_h      : integer                                                                     ; --! Number of low  level clock period timing error
signal   err_n_clk_per_l      : integer                                                                     ; --! Number of high level clock period timing error
signal   err_n_clk_osc_ena_l  : integer                                                                     ; --! Number of clock oscillation error when enable is inactive
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of clock state error when enable goes to active/inactive
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_clk_st_ena : process
   begin

      if now = 0 ps then
         err_n_clk_st_ena_h <= 0;
         err_n_clk_st_ena_l <= 0;

      end if;

      wait until i_ena'event;

      if i_ena = '1' and i_clk = not(g_CLK_ST_ENA) then
         err_n_clk_st_ena_h <= err_n_clk_st_ena_h + 1;

      elsif i_ena = '0' and i_clk = not(g_CLK_ST_DIS) then
         err_n_clk_st_ena_l <= err_n_clk_st_ena_l + 1;

      end if;

   end process P_err_n_clk_st_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of low/high level clock period timing error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_clk_per : process
   constant c_TIMOUT_CLK_EV   : time   := 4*(g_CLK_PER_L + g_CLK_PER_H)                                     ; --! Time out clock event detection
   variable v_record_time     : time                                                                        ; --! Record time
   begin

      if now = 0 ps then
         err_n_clk_per_h   <= 0;
         err_n_clk_per_l   <= 0;

      end if;

      v_record_time := now;

      wait until i_clk'event for c_TIMOUT_CLK_EV;

      if i_ena = '1' and i_ena'last_event > c_TIMOUT_CLK_EV then

         if i_clk = '1'  and (now-v_record_time) /= g_CLK_PER_L then
            err_n_clk_per_l <= err_n_clk_per_l + 1;

         elsif i_clk = '0' and (now-v_record_time) /= g_CLK_PER_H then
            err_n_clk_per_h <= err_n_clk_per_h + 1;

         end if;

      end if;

   end process P_err_n_clk_per;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of clock oscillation error when enable is inactive
   -- ------------------------------------------------------------------------------------------------------
   clk_delay <= transport i_clk after 0 ps;

   P_err_n_clk_osc_ena : process
   begin

      if now = 0 ps then
         err_n_clk_osc_ena_l  <= 0;

      end if;

      wait until clk_delay'event;

      if i_ena = '0' and i_chk_osc_ena_l = '1' then
         err_n_clk_osc_ena_l <= err_n_clk_osc_ena_l + 1;

      end if;

   end process P_err_n_clk_osc_ena;

   o_err_n_clk_chk(4) <= err_n_clk_st_ena_h;
   o_err_n_clk_chk(3) <= err_n_clk_st_ena_l;
   o_err_n_clk_chk(2) <= err_n_clk_per_l;
   o_err_n_clk_chk(1) <= err_n_clk_per_h;
   o_err_n_clk_chk(0) <= err_n_clk_osc_ena_l;

end architecture Behavioral;
