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
--!   @file                   register_cs_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Chip selects register management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity register_cs_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ep_cmd_rx_wd_add_r : in     std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                           ; --! EP command receipted: address word, read/write bit cleared, registered
         o_cs_rg              : out    std_logic_vector(c_EP_CMD_REG_MX_STIN(1)-1 downto 0)                   --! Chip selects register ('0' = Inactive, '1' = Active)
   );
end entity register_cs_mgt;

architecture RTL of register_cs_mgt is
signal   cs_rg                : std_logic_vector(c_EP_CMD_POS_LAST-1 downto 0)                              ; --! Chip selects register ('0' = Inactive, '1' = Active)
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Chip selects register
   -- ------------------------------------------------------------------------------------------------------
   cs_rg(c_EP_CMD_POS_AQMDE)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_AQMDE  else '0';
   cs_rg(c_EP_CMD_POS_SMFMD)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SMFMD  else '0';
   cs_rg(c_EP_CMD_POS_SAOFM)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_SAOFM  else '0';
   cs_rg(c_EP_CMD_POS_TSTEN)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_TSTEN  else '0';
   cs_rg(c_EP_CMD_POS_BXLGT)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_BXLGT  else '0';
   cs_rg(c_EP_CMD_POS_DLFLG)  <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_DLFLG  else '0';
   cs_rg(c_EP_CMD_POS_STATUS) <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_STATUS else '0';
   cs_rg(c_EP_CMD_POS_FW_VER) <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_FW_VER else '0';
   cs_rg(c_EP_CMD_POS_HW_VER) <= '1' when  i_ep_cmd_rx_wd_add_r = c_EP_CMD_ADD_HW_VER else '0';

   cs_rg(c_EP_CMD_POS_TSTPT)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)      = c_EP_CMD_ADD_TSTPT(i_ep_cmd_rx_wd_add_r'high downto c_MEM_TSTPT_ADD_S)         and
       i_ep_cmd_rx_wd_add_r(   c_MEM_TSTPT_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_TSTPT_NW, c_MEM_TSTPT_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_HKEEP)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)      = c_EP_CMD_ADD_HKEEP(i_ep_cmd_rx_wd_add_r'high downto c_MEM_HKEEP_ADD_S)         and
       i_ep_cmd_rx_wd_add_r(   c_MEM_HKEEP_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_HKEEP_NW, c_MEM_HKEEP_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_PARMA)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PARMA(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)      = c_EP_CMD_ADD_PARMA(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PARMA_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_PARMA_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PARMA_NW, c_MEM_PARMA_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_KIKNM)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_KIKNM(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                     >= c_EP_CMD_ADD_KIKNM(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_KIKNM(0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                               + to_unsigned(c_TAB_KIKNM_NW, c_EP_CMD_ADD_COLPOSL)))            else '0';
   cs_rg(c_EP_CMD_POS_KNORM)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_KNORM(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)      = c_EP_CMD_ADD_KNORM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_KNORM_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_KNORM_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_KNORM_NW, c_MEM_KNORM_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SMFB0)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFB0(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)      = c_EP_CMD_ADD_SMFB0(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFB0_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SMFB0_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFB0_NW, c_MEM_SMFB0_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SMLKV)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMLKV(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                     >= c_EP_CMD_ADD_SMLKV(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      < std_logic_vector(unsigned(c_EP_CMD_ADD_SMLKV(0)(c_EP_CMD_ADD_COLPOSL-1 downto 0))
                                                                                               + to_unsigned(c_TAB_SMLKV_NW, c_EP_CMD_ADD_COLPOSL)))            else '0';
   cs_rg(c_EP_CMD_POS_SMFBM)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBM(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)      = c_EP_CMD_ADD_SMFBM(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SMFBM_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SMFBM_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SMFBM_NW, c_MEM_SMFBM_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SAOFF)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFF(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)      = c_EP_CMD_ADD_SAOFF(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_SAOFF_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_SAOFF_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_SAOFF_NW, c_MEM_SAOFF_ADD_S)))            else '0';

   cs_rg(c_EP_CMD_POS_SAOFC)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFC(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOFC(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAOFL)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOFL(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOFL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SMFBD)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMFBD(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SMFBD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAODD)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAODD(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAODD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SAOMD)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SAOMD(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SAOMD(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_SMPDL)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_SMPDL(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_SMPDL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_PLSSH)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSH(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      = c_EP_CMD_ADD_PLSSH(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_PLSSH_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(     c_TAB_PLSSH_S-1    downto 0)                      < std_logic_vector(to_unsigned(c_TAB_PLSSH_NW, c_TAB_PLSSH_S)))                else '0';

   cs_rg(c_EP_CMD_POS_PLSSS)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_PLSSS(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_PLSSS(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_RLDEL)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_RLDEL(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_RLDEL(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_RLTHR)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_RLTHR(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto 0)                      = c_EP_CMD_ADD_RLTHR(0)(c_EP_CMD_ADD_COLPOSL-1  downto 0))                     else '0';

   cs_rg(c_EP_CMD_POS_DLCNT)  <= '1' when
      (i_ep_cmd_rx_wd_add_r(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) = c_EP_CMD_ADD_DLCNT(0)(i_ep_cmd_rx_wd_add_r'high downto c_EP_CMD_ADD_COLPOSH+1) and
       i_ep_cmd_rx_wd_add_r(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)      = c_EP_CMD_ADD_DLCNT(0)(c_EP_CMD_ADD_COLPOSL-1  downto c_MEM_DLCNT_ADD_S)      and
       i_ep_cmd_rx_wd_add_r(   c_MEM_DLCNT_ADD_S-1  downto 0)                      < std_logic_vector(to_unsigned(c_TAB_DLCNT_NW, c_MEM_DLCNT_ADD_S)))            else '0';

   P_cs_rg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_cs_rg(c_EP_CMD_POS_LAST-1 downto 0) <= (others => '0');

      elsif rising_edge(i_clk) then
         o_cs_rg(c_EP_CMD_POS_LAST-1 downto 0) <= cs_rg;

      end if;

   end process P_cs_rg;

   o_cs_rg(c_EP_CMD_REG_MX_STIN(1)-1 downto c_EP_CMD_POS_LAST) <= (others => '0');

end architecture RTL;
