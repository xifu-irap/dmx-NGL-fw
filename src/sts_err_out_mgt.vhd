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

entity sts_err_out_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_ep_cmd_rx_add_norw : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared
         i_ep_cmd_rx_wd_data  : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: data word
         i_ep_cmd_rx_rw       : in     std_logic                                                            ; --! EP command receipted: read/write bit
         i_ep_cmd_rx_out_rdy  : in     std_logic                                                            ; --! EP command receipted: error data out of range ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd_sts_err_out : out    std_logic                                                              --! EP command: Status, error data out of range
   );
end entity sts_err_out_mgt;

architecture RTL of sts_err_out_mgt is
signal   cond_aqmde           : std_logic                                                                   ; --! Error data out of range condition: DATA_ACQ_MODE
signal   cond_smfmd           : std_logic                                                                   ; --! Error data out of range condition: SQ_MUX_FB_ON_OFF
signal   cond_saofm           : std_logic                                                                   ; --! Error data out of range condition: SQ_AMP_OFFSET_MODE
signal   cond_tsten           : std_logic                                                                   ; --! Error data out of range condition: TEST_PATTERN_ENABLE
signal   cond_smfbm           : std_logic                                                                   ; --! Error data out of range condition: CY_MUX_SQ_FB_MODE
signal   cond_saoff           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_FINE
signal   cond_saofl           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_LSB
signal   cond_saofc           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_COARSE
signal   cond_smfbd           : std_logic                                                                   ; --! Error data out of range condition: CY_MUX_SQ_FB_DELAY
signal   cond_saodd           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_DAC_DELAY
signal   cond_saomd           : std_logic                                                                   ; --! Error data out of range condition: CY_AMP_SQ_OFFSET_MUX_DELAY
signal   cond_smpdl           : std_logic                                                                   ; --! Error data out of range condition: CY_SAMPLING_DELAY
signal   cond_plsss           : std_logic                                                                   ; --! Error data out of range condition: CY_FB1_PULSE_SHAPING_SELECTION

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Error data out of range conditions
   -- ------------------------------------------------------------------------------------------------------
   cond_aqmde     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3)  or
                    (not(i_ep_cmd_rx_wd_data(2)) and  i_ep_cmd_rx_wd_data(1) and i_ep_cmd_rx_wd_data(0)) or
                    (    i_ep_cmd_rx_wd_data(2)  and (i_ep_cmd_rx_wd_data(1) xor i_ep_cmd_rx_wd_data(0)));

   cond_smfmd     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or
                     i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2)  or i_ep_cmd_rx_wd_data(1);

   cond_saofm     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2);

   cond_tsten     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6);

   cond_smfbm     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2)  or
                    (i_ep_cmd_rx_wd_data(1) and i_ep_cmd_rx_wd_data(0));

   cond_saoff     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3);

   cond_saofl     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12);

   cond_saofc     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12);

   cond_smfbd     <= '1' when (i_ep_cmd_rx_wd_data(c_DFLD_SMFBD_COL_S-1) = '0' and
                     i_ep_cmd_rx_wd_data(c_DFLD_SMFBD_COL_S-2 downto 0) > std_logic_vector(to_unsigned(2*c_PIXEL_DAC_NB_CYC, c_DFLD_SMFBD_COL_S-1))) else
                     i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10);

   cond_saodd     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10);

   cond_saomd     <= '1' when (i_ep_cmd_rx_wd_data(c_DFLD_SAOMD_COL_S-1) = '0' and
                     i_ep_cmd_rx_wd_data(c_DFLD_SAOMD_COL_S-2 downto 0) > std_logic_vector(to_unsigned(2*c_PIXEL_DAC_NB_CYC, c_DFLD_SAOMD_COL_S-1))) else
                     i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10);

   cond_smpdl     <= '1' when i_ep_cmd_rx_wd_data(c_DFLD_SMPDL_COL_S-1 downto 0) >= std_logic_vector(to_unsigned(c_PIXEL_ADC_NB_CYC , c_DFLD_SMPDL_COL_S)) else
                     i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5);

   cond_plsss     <= i_ep_cmd_rx_wd_data(15) or i_ep_cmd_rx_wd_data(14) or i_ep_cmd_rx_wd_data(13) or i_ep_cmd_rx_wd_data(12) or
                     i_ep_cmd_rx_wd_data(11) or i_ep_cmd_rx_wd_data(10) or i_ep_cmd_rx_wd_data(9)  or i_ep_cmd_rx_wd_data(8)  or
                     i_ep_cmd_rx_wd_data(7)  or i_ep_cmd_rx_wd_data(6)  or i_ep_cmd_rx_wd_data(5)  or i_ep_cmd_rx_wd_data(4)  or
                     i_ep_cmd_rx_wd_data(3)  or i_ep_cmd_rx_wd_data(2);

   -- ------------------------------------------------------------------------------------------------------
   --!   EP command: Status, error data out of range
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

               if    i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_AQMDE  then
                  o_ep_cmd_sts_err_out <= cond_aqmde xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SMFMD  then
                  o_ep_cmd_sts_err_out <= cond_smfmd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_SAOFM  then
                  o_ep_cmd_sts_err_out <= cond_saofm xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw = c_EP_CMD_ADD_TSTEN  then
                  o_ep_cmd_sts_err_out <= cond_tsten xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBM(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      = c_EP_CMD_ADD_SMFBM(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SMFBM_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SMFBM_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S))               then
                  o_ep_cmd_sts_err_out <= cond_smfbm xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFF(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      = c_EP_CMD_ADD_SAOFF(0)(c_EP_CMD_ADD_COLPOSL-1    downto c_MEM_SAOFF_ADD_S)      and
                     i_ep_cmd_rx_add_norw(   c_MEM_SAOFF_ADD_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S))               then
                  o_ep_cmd_sts_err_out <= cond_saoff xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFL(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFL(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saofl xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFC(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOFC(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saofc xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBD(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMFBD(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_smfbd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAODD(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAODD(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saodd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOMD(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SAOMD(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_saomd xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMPDL(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_SMPDL(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_smpdl xor c_EP_CMD_ERR_CLR;

               elsif i_ep_cmd_rx_add_norw(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSS(0)(i_ep_cmd_rx_add_norw'high downto c_EP_CMD_ADD_COLPOSH+1) and
                     i_ep_cmd_rx_add_norw(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      = c_EP_CMD_ADD_PLSSS(0)(c_EP_CMD_ADD_COLPOSL-1    downto 0)                      then
                  o_ep_cmd_sts_err_out <= cond_plsss xor c_EP_CMD_ERR_CLR;

               else
                  o_ep_cmd_sts_err_out <= c_EP_CMD_ERR_CLR;

               end if;

            end if;

         end if;

      end if;

   end process P_ep_cmd_sts_err_out;

end architecture RTL;
