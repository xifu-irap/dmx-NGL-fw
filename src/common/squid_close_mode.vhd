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
--!   @file                   squid_close_mode.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process parameter memories management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_close_mode is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_saofm              : in     std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                      ; --! SQUID AMP offset mode
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_mem_smfbm          : in     t_mem(
                                       add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                     ; --! SQUID MUX feedback mode: memory inputs

         i_smfbm_add          : in     std_logic_vector( c_MEM_SMFBM_ADD_S-1 downto 0)                      ; --! SQUID MUX feedback mode: address, memory output
         i_smfbm_cs           : in     std_logic                                                            ; --! SQUID MUX feedback mode: chip select, memory output ('0' = Inactive, '1' = Active)

         o_squid_amp_close    : out    std_logic                                                            ; --! SQUID AMP Close mode     ('0' = Yes, '1' = No)
         o_squid_close_mode_n : out    std_logic                                                            ; --! SQUID MUX/AMP Close mode ('0' = Yes, '1' = No)
         o_amp_frst_lst_frm   : out    std_logic                                                              --! SQUID AMP First and Last frame('0' = No, '1' = Yes)
   );
end entity squid_close_mode;

architecture RTL of squid_close_mode is
signal   mem_smfbm_pp         : std_logic                                                                   ; --! SQUID MUX feedback mode, TC/HK side: ping-pong buffer bit
signal   mem_smfbm_prm        : t_mem(
                                add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback mode, getting parameter side: memory inputs

signal   smfmd_sync           : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                             ; --! SQUID MUX feedback mode synchronized on first Pixel sequence
signal   saofm_close_sync     : std_logic                                                                   ; --! SQUID AMP offset close mode synchronized on first Pixel sequence
signal   saofm_close_sync_r   : std_logic                                                                   ; --! SQUID AMP offset close mode synchronized on first Pixel sequence register

signal   smfbm                : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback mode

begin

  -- ------------------------------------------------------------------------------------------------------
   --!   Signal synchronized on first Pixel sequence
   -- ------------------------------------------------------------------------------------------------------
   P_sync: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_smfbm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;
         smfmd_sync            <= c_DST_SMFMD_OFF;
         saofm_close_sync      <= c_LOW_LEV;
         saofm_close_sync_r    <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if (i_smfbm_cs = c_HGH_LEV) and i_smfbm_add = std_logic_vector(to_unsigned(c_TAB_SMFBM_NW-1, i_smfbm_add'length)) then
            mem_smfbm_prm.pp <= mem_smfbm_pp;
            smfmd_sync       <= i_smfmd;

            if i_saofm = c_DST_SAOFM_CLOSE then
               saofm_close_sync <= c_HGH_LEV;

            else
               saofm_close_sync <= c_LOW_LEV;

            end if;

         end if;

         saofm_close_sync_r <= saofm_close_sync;

      end if;

   end process P_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID MUX feedback mode
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smfbm_st: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMFBM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMFBM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMFBM     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_smfbm          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smfbm_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smfbm_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => smfbm                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory SQUID MUX feedback mode: writing data signals
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smfbm_prm.add     <= i_smfbm_add;
   mem_smfbm_prm.we      <= c_LOW_LEV;
   mem_smfbm_prm.cs      <= c_HGH_LEV;
   mem_smfbm_prm.data_w  <= c_DST_SMFBM_OPEN;

  -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX/AMP Close mode by pixel
   -- ------------------------------------------------------------------------------------------------------
   P_squid_close_mode: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_squid_amp_close    <= c_LOW_LEV;
         o_squid_close_mode_n <= c_HGH_LEV;
         o_amp_frst_lst_frm   <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if i_saofm = c_DST_SAOFM_CLOSE then
            o_squid_amp_close <= c_HGH_LEV;

         else
            o_squid_amp_close <= c_LOW_LEV;

         end if;

         if (smfbm = c_DST_SMFBM_CLOSE and smfmd_sync = c_DST_SMFMD_ON) or (saofm_close_sync = c_HGH_LEV) then
            o_squid_close_mode_n <= c_LOW_LEV;

         else
            o_squid_close_mode_n <= c_HGH_LEV;

         end if;

         if (saofm_close_sync xor saofm_close_sync_r) = c_HGH_LEV then
            o_amp_frst_lst_frm <= c_HGH_LEV;

         elsif (i_smfbm_cs = c_HGH_LEV) and i_smfbm_add = std_logic_vector(to_unsigned(c_TAB_SMFBM_NW-1, i_smfbm_add'length)) then
            o_amp_frst_lst_frm <= c_LOW_LEV;

         end if;

      end if;

   end process P_squid_close_mode;

end architecture RTL;
