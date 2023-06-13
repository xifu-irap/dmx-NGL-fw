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
--!   @file                   rg_tsten_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Register TSTEN Test pattern enable
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity rg_tsten_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ep_cmd_rx_wd_dta_r : in     std_logic_vector(    c_DFLD_TSTEN_S-1 downto 0)                      ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     : in     std_logic                                                            ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r : in     std_logic                                                            ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)
         i_cs_rg_tsten        : in     std_logic                                                            ; --! Chip selects register TSTEN

         i_tst_pat_end_pat    : in     std_logic                                                            ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         i_tst_pat_empty      : in     std_logic                                                            ; --! Test pattern empty ('0' = No, '1' = Yes)

         o_rg_tsten           : out    std_logic_vector(    c_DFLD_TSTEN_S-1 downto 0)                        --! Test pattern enable
   );
end entity rg_tsten_mgt;

architecture RTL of rg_tsten_mgt is
signal   rg_tsten_lop         : std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                             ; --! Test pattern enable, field Loop number
signal   rg_tsten_inf         : std_logic                                                                   ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
signal   rg_tsten_ena         : std_logic                                                                   ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern enable
   -- ------------------------------------------------------------------------------------------------------
   P_rg_tsten : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         rg_tsten_lop <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);
         rg_tsten_inf <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_INF_POS);
         rg_tsten_ena <= c_EP_CMD_DEF_TSTEN(c_DFLD_TSTEN_ENA_POS);

      elsif rising_edge(i_clk) then

         if i_ep_cmd_rx_ner_ry_r = '1' and i_ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and i_cs_rg_tsten = '1' then
            if i_ep_cmd_rx_wd_dta_r(c_DFLD_TSTEN_INF_POS) = '1' then
               rg_tsten_lop <= std_logic_vector(to_unsigned(0, rg_tsten_lop'length));

            else
               rg_tsten_lop <= i_ep_cmd_rx_wd_dta_r(c_DFLD_TSTEN_LOP_S + c_DFLD_TSTEN_LOP_POS-1 downto c_DFLD_TSTEN_LOP_POS);

            end if;

         elsif i_tst_pat_empty = '1' then
            rg_tsten_lop <= std_logic_vector(to_unsigned(0, rg_tsten_lop'length));

         elsif rg_tsten_lop /= std_logic_vector(to_unsigned(0, rg_tsten_lop'length)) and i_tst_pat_end_pat = '1' then
            rg_tsten_lop <= std_logic_vector(signed(rg_tsten_lop) - 1);

         end if;

         if i_ep_cmd_rx_ner_ry_r = '1' and i_ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and i_cs_rg_tsten = '1' then
            rg_tsten_inf <= i_ep_cmd_rx_wd_dta_r(c_DFLD_TSTEN_INF_POS);

         elsif i_tst_pat_empty = '1' then
            rg_tsten_inf <= '0';

         end if;

         if i_ep_cmd_rx_ner_ry_r = '1' and i_ep_cmd_rx_rw_r = c_EP_CMD_ADD_RW_W and i_cs_rg_tsten = '1' then
            rg_tsten_ena <= i_ep_cmd_rx_wd_dta_r(c_DFLD_TSTEN_ENA_POS);

         elsif (rg_tsten_lop = std_logic_vector(to_unsigned(0, rg_tsten_lop'length)) and rg_tsten_inf = '0') or i_tst_pat_empty = '1' then
            rg_tsten_ena <= '0';

         end if;

      end if;

   end process P_rg_tsten;

   o_rg_tsten  <= rg_tsten_ena & rg_tsten_inf & rg_tsten_lop;

end architecture RTL;
