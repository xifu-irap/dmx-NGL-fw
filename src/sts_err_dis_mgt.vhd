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
--!   @file                   sts_err_dis_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command: Status, error last SPI command discarded
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sts_err_dis_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_tm_mode_st_dump    : in     std_logic                                                            ; --! Telemetry mode, status "Dump" ('0' = Inactive, '1' = Active)

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         o_ep_cmd_sts_err_dis : out    std_logic                                                              --! EP command: Status, error last SPI command discarded
   );
end entity sts_err_dis_mgt;

architecture RTL of sts_err_dis_mgt is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error last SPI command discarded
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_dis : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_sts_err_dis <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_R then
            o_ep_cmd_sts_err_dis <= c_EP_CMD_ERR_CLR;

         else
            case i_ep_cmd_rx_add_norw is
               when c_EP_CMD_ADD_TM_MODE  =>
                  o_ep_cmd_sts_err_dis <= i_tm_mode_st_dump xor c_EP_CMD_ERR_CLR;

               when others                =>
                  o_ep_cmd_sts_err_dis <= c_EP_CMD_ERR_CLR;

            end case;

         end if;

      end if;

   end process P_ep_cmd_sts_err_dis;

end architecture RTL;
