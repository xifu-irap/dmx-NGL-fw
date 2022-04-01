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
--!   @file                   squid2_fbk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid2 Feedback management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid2_fbk_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90° shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         i_sq2_fb_mode        : in     std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0)                    ; --! Squid 2 Feedback mode
         i_sq2_lkp_off        : in     std_logic_vector(c_DFLD_S2OFF_COL_S  -1 downto 0)                    ; --! Squid 2 Feedback lockpoint offset
         i_s1_dta_err_cor     : in     std_logic_vector(c_SQ1_DATA_FBK_S    -1 downto 0)                    ; --! SQUID1 Data error corrected (signed)

         i_mem_sq2_lkp        : in     t_mem(
                                       add(              c_MEM_S2LKP_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_S2LKP_PIX_S-1 downto 0))                     ; --! Squid2 Feedback lockpoint: memory inputs
         o_sq2_lkp_data       : out    std_logic_vector(c_DFLD_S2LKP_PIX_S-1 downto 0)                      ; --! Squid2 Feedback lockpoint: data read

         o_sq2_fbk_mux        : out    std_logic_vector(c_DFLD_S2LKP_PIX_S-1 downto 0)                      ; --! Squid2 Feedback Multiplexer
         o_sq2_fbk_off        : out    std_logic_vector(c_DFLD_S2OFF_COL_S-1 downto 0)                        --! Squid2 Feedback offset

   );
end entity squid2_fbk_mgt;

architecture RTL of squid2_fbk_mgt is
constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_S2M_SYNC_DATA_NPER/2                        ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= c_PIXEL_POS_MAX_VAL-1                                             ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1) + 1                              ; --! Pixel position: size bus (signed)

signal   pls_cnt              : std_logic_vector(  c_PLS_CNT_S-1 downto 0)                                  ; --! Pulse shaping counter
signal   pixel_pos            : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! Pixel position
signal   pixel_pos_inc        : std_logic_vector(c_PIXEL_POS_S-2 downto 0)                                  ; --! Pixel position increasing

signal   mem_sq2_lkp_pp       : std_logic                                                                   ; --! Squid2 feedback lockpoint, TH/HK side: ping-pong buffer bit
signal   mem_sq2_lkp_prm      : t_mem(
                                add(           c_MEM_S2LKP_ADD_S-1 downto 0),
                                data_w(       c_DFLD_S2LKP_PIX_S-1 downto 0))                               ; --! Squid2 feedback lockpoint, getting parameter side: memory inputs

signal   sq2_fb_mode_sync     : std_logic_vector(c_DFLD_SQ2FBMD_COL_S-1 downto 0)                           ; --! Squid2 feedback mode synchronized on first Pixel sequence
signal   sq2_fb_close         : std_logic_vector(c_SQ2_DAC_DATA_S-1 downto 0)                               ; --! Squid2 feedback close mode
signal   sq2_fb_tst_pattern   : std_logic_vector(c_SQ2_DAC_DATA_S-1 downto 0)                               ; --! Squid2 feedback test pattern mode
signal   sq2_lkp              : std_logic_vector(c_SQ2_DAC_MUX_S-1  downto 0)                               ; --! Squid2 feedback lockpoint

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_cnt  <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            pls_cnt <= std_logic_vector(to_signed(c_PLS_CNT_INIT, pls_cnt'length));

         elsif pls_cnt(pls_cnt'high) = '1' then
            pls_cnt <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

         else
            pls_cnt <= std_logic_vector(signed(pls_cnt) - 1);

         end if;

      end if;

   end process P_pls_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pixel_pos   <= (others => '1');

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = '1' then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = '1' then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   pixel_pos_inc <= std_logic_vector(resize(unsigned(to_signed(c_PIXEL_POS_MAX_VAL, pixel_pos'length) - signed(pixel_pos)), pixel_pos_inc'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals synchronized on first Pixel sequence
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_fb_mode_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sq2_fb_mode_sync        <= c_DST_SQ2FBMD_OFF;
         mem_sq2_lkp_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = '1' then
            sq2_fb_mode_sync     <= i_sq2_fb_mode;
            mem_sq2_lkp_prm.pp   <= mem_sq2_lkp_pp;

         end if;

      end if;

   end process P_sq2_fb_mode_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for Squid2 feedback lockpoint
   --    @Req : REG_CY_SQ2_PXL_LOCKPOINT
   --    @Req : DRE-DMX-FW-REQ-0300
   -- ------------------------------------------------------------------------------------------------------
   I_mem_sq2_pxl_lkp: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_S2LKP_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_S2LKP_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_S2LKP     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90° shifted clock (used for memory content correction)

         i_a_mem              => i_mem_sq2_lkp        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_sq2_lkp_data       , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_sq2_lkp_pp       , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90° shifted clock (used for memory content correction)

         i_b_mem              => mem_sq2_lkp_prm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => sq2_lkp              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory Squid2 feedback lockpoint signals: writing data signals
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_sq2_lkp_prm.add     <= pixel_pos_inc;
   mem_sq2_lkp_prm.we      <= '0';
   mem_sq2_lkp_prm.cs      <= '1';
   mem_sq2_lkp_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Squid2 feedback
   --    @Req : DRE-DMX-FW-REQ-0290
   --    @Req : DRE-DMX-FW-REQ-0330
   --    @Req : DRE-DMX-FW-REQ-0360
   -- ------------------------------------------------------------------------------------------------------
   P_sq2_fbk : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sq2_fbk_mux <= (others => '0');
         o_sq2_fbk_off <= c_EP_CMD_DEF_S2OFF;

      elsif rising_edge(i_clk) then
         if sq2_fb_mode_sync = c_DST_SQ2FBMD_OFF then
            o_sq2_fbk_mux <= (others => '0');
            o_sq2_fbk_off <= std_logic_vector(to_unsigned(c_SQ2_DAC_MDL_POINT,c_SQ2_DAC_DATA_S));

         elsif sq2_fb_mode_sync = c_DST_SQ2FBMD_CLOSE then
            o_sq2_fbk_mux <= (others => '0');
            o_sq2_fbk_off <= sq2_fb_close;

         elsif sq2_fb_mode_sync = c_DST_SQ2FBMD_TEST then
            o_sq2_fbk_mux <= (others => '0');
            o_sq2_fbk_off <= sq2_fb_tst_pattern;

         else
            o_sq2_fbk_mux <= sq2_lkp;
            o_sq2_fbk_off <= i_sq2_lkp_off;

         end if;

      end if;

   end process P_sq2_fbk;

   --TODO
   sq2_fb_close    <=  i_s1_dta_err_cor(i_s1_dta_err_cor'high downto i_s1_dta_err_cor'length-sq2_fb_close'length);
   sq2_fb_tst_pattern   <=  x"555";

end architecture RTL;
