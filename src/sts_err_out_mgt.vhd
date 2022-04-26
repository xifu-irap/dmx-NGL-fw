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
--!   @file                   sts_err_out_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                EP command: Status, error data out of range management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity sts_err_out_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_out_rdy  : in     std_logic                                                            ; --! EP command receipted: error data out of range ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd_sts_err_out : out    std_logic                                                              --! EP command: Status, error data out of range
   );
end entity sts_err_out_mgt;

architecture RTL of sts_err_out_mgt is
signal   cond_sq1tmmode       : std_logic                                                                   ; --! Error data out of range condition: TM_MODE
signal   cond_sq1fbmd         : std_logic                                                                   ; --! Error data out of range condition: SQ1_FB_MODE
signal   cond_sq2fbmd         : std_logic                                                                   ; --! Error data out of range condition: SQ2_FB_MODE
signal   cond_s1fbm           : std_logic                                                                   ; --! Error data out of range condition: CY_SQ1_FB_MODE
signal   cond_s2lkp           : std_logic                                                                   ; --! Error data out of range condition: CY_SQ2_PXL_LOCKPOINT
signal   cond_s2lsb           : std_logic                                                                   ; --! Error data out of range condition: CY_SQ2_PXL_LOCKPOINT_LSB
signal   cond_s2off           : std_logic                                                                   ; --! Error data out of range condition: CY_SQ2_PXL_LOCKPOINT_OFFSET

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Error data out of range conditions
   -- ------------------------------------------------------------------------------------------------------
   cond_sq1tmmode <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2);

   cond_sq1fbmd <=   i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(1);

   cond_sq2fbmd <=   i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2);

   cond_s1fbm   <=   i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2)  or
                    (i_ep_cmd_rx_wd_data(1) and i_ep_cmd_rx_wd_data(0));

   cond_s2lkp  <=    i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3);

   cond_s2lsb  <=    i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12);

   cond_s2off  <=    i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error error data out of range
   -- ------------------------------------------------------------------------------------------------------
   P_ep_cmd_sts_err_out : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

      elsif rising_edge(i_clk) then
         if i_ep_cmd_rx_out_rdy = '1' then
            if i_ep_cmd_rx_rw = c_EP_CMD_ADD_RW_R then
               o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

            else

               if    i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_TM_MODE  then
                  o_ep_cmd_sts_err_out <= cond_sq1tmmode xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SQ1FBMD  then
                  o_ep_cmd_sts_err_out <= cond_sq1fbmd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SQ2FBMD  then
                  o_ep_cmd_sts_err_out <= cond_sq2fbmd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S1FBM(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FBM_ADD_S)      = c_EP_CMD_ADD_S1FBM(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S1FBM_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_S1FBM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S1FBM_NW, c_MEM_S1FBM_ADD_S))               then
                  o_ep_cmd_sts_err_out <= cond_s1fbm xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2LKP(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S2LKP_ADD_S)      = c_EP_CMD_ADD_S2LKP(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_S2LKP_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_S2LKP_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_S2LKP_NW, c_MEM_S2LKP_ADD_S))               then
                  o_ep_cmd_sts_err_out <= cond_s2lkp xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2LSB(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_S2LSB(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_s2lsb xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_S2OFF(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_S2OFF(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_s2off xor c_EP_CMD_ERR_CLR;

               else
                  o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

               end if;

            end if;

         end if;

      end if;

   end process P_ep_cmd_sts_err_out;

end architecture RTL;
