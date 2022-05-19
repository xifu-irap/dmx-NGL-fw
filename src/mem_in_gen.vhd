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
--!   @file                   mem_in_gen.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Memory inputs generation
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity mem_in_gen is generic
   (     g_MEM_ADD_S          : integer                                                                     ; --! Memory address size
         g_MEM_DATA_S         : integer                                                                     ; --! Memory data size
         g_MEM_ADD_END        : integer                                                                       --! Memory address end
   ); port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_col_nb             : in     std_logic_vector(log2_ceil(c_NB_COL)-1 downto 0)                     ; --! Column number
         i_ep_cmd_rx_wd_add_r : in     std_logic_vector( g_MEM_ADD_S-1 downto 0)                            ; --! EP command receipted: address word, read/write bit cleared, registered
         i_ep_cmd_rx_wd_dta_r : in     std_logic_vector(g_MEM_DATA_S-1 downto 0)                            ; --! EP command receipted: data word, registered
         i_ep_cmd_rx_rw_r     : in     std_logic                                                            ; --! EP command receipted: read/write bit, registered
         i_ep_cmd_rx_ner_ry_r : in     std_logic                                                            ; --! EP command receipted with no error ready, registered ('0'= Not ready, '1'= Ready)

         i_cs_rg              : in     std_logic                                                            ; --! Chip select register ('0' = Inactive, '1' = Active)

         o_mem_in             : out    t_mem_arr(0 to c_NB_COL-1)                                           ; --! Memory inputs
         o_cs_data_rd         : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! Chip select data read ('0' = Inactive, '1' = Active)
   );
end entity mem_in_gen;

architecture RTL of mem_in_gen is
begin

   G_column_mgt : for k in 0 to o_mem_in'high generate
   begin

      P_mem_in : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            o_mem_in(k).cs <= '0';
            o_mem_in(k).pp <= '0';

         elsif rising_edge(i_clk) then
            if i_col_nb = std_logic_vector(to_unsigned(k, log2_ceil(o_mem_in'length))) then

               if i_cs_rg = '1' then
                  o_mem_in(k).cs <= i_ep_cmd_rx_ner_ry_r;

                  if i_ep_cmd_rx_wd_add_r = std_logic_vector(to_unsigned(g_MEM_ADD_END, g_MEM_ADD_S)) then
                     o_mem_in(k).pp <= i_ep_cmd_rx_ner_ry_r and not(i_ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);

                  end if;

               end if;

             end if;

         end if;

      end process P_mem_in;

      o_mem_in(k).add    <= i_ep_cmd_rx_wd_add_r;
      o_mem_in(k).we     <= not(i_ep_cmd_rx_rw_r xor c_EP_CMD_ADD_RW_W);
      o_mem_in(k).data_w <= i_ep_cmd_rx_wd_dta_r;
      o_cs_data_rd(k)    <= o_mem_in(k).cs and not(o_mem_in(k).we);

   end generate G_column_mgt;

end architecture RTL;
