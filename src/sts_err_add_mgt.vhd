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
--!   @file                   sts_err_add_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command: Status, error invalid address management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sts_err_add_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         o_ep_cmd_sts_err_add : out    std_logic                                                              --! EP command: Status, error invalid address
   );
end entity sts_err_add_mgt;

architecture RTL of sts_err_add_mgt is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error invalid address
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_add : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if    i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_TM_MODE  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SQ1FBMD  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SQ2FBMD  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_STATUS   then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_VERSION  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FB0(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
               i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FB0_ADD_S)      = c_EP_CMD_ADD_S1FB0(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FB0_ADD_S)      and
               i_ep_cmd_rx_add_norw(   c_MEM_S1FB0_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S1FB0_NW, c_MEM_S1FB0_ADD_S))  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FBM(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
               i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FBM_ADD_S)      = c_EP_CMD_ADD_S1FBM(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FBM_ADD_S)      and
               i_ep_cmd_rx_add_norw(   c_MEM_S1FBM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S1FBM_NW, c_MEM_S1FBM_ADD_S))  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSH(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
               i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_PLSSH_ADD_S)      and
               i_ep_cmd_rx_add_norw(       c_TAB_PLSSH_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_TAB_PLSSH_S))  then
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_CLR;

         else
            o_ep_cmd_sts_err_add <= c_EP_CMD_ERR_SET;

         end if;

      end if;

   end process P_ep_cmd_sts_err_add;

end architecture RTL;
