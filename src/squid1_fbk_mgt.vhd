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
--!   @file                   squid1_fbk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid1 feedback management
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

entity squid1_fbk_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90° shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         i_s1_dta_pixel_pos   : in     std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID1 Data error corrected pixel position
         i_s1_dta_err_cor     : in     std_logic_vector(c_SQ1_DATA_FBK_S-1 downto 0)                        ; --! SQUID1 Data error corrected (signed)
         i_s1_dta_err_cor_cs  : in     std_logic                                                            ; --! SQUID1 Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_sq1_fb0        : in     t_mem(
                                       add(              c_MEM_S1FB0_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_S1FB0_PIX_S-1 downto 0))                     ; --! Squid1 feedback value in open loop: memory inputs
         o_sq1_fb0_data       : out    std_logic_vector(c_DFLD_S1FB0_PIX_S-1 downto 0)                      ; --! Squid1 feedback value in open loop: data read

         i_sq1_fb_mode        : in     std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0)                    ; --! Squid1 Feedback mode (on/off)
         i_mem_sq1_fbm        : in     t_mem(
                                       add(              c_MEM_S1FBM_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_S1FBM_PIX_S-1 downto 0))                     ; --! Squid1 feedback mode: memory inputs
         o_sq1_fbm_data       : out    std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0)                      ; --! Squid1 feedback mode: data read

         o_sq1_data_fbk       : out    std_logic_vector( c_SQ1_DATA_FBK_S-1 downto 0)                         --! SQUID1 Data feedback (signed)
   );
end entity squid1_fbk_mgt;

architecture RTL of squid1_fbk_mgt is
constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_DAC_SYNC_DATA_NPER/2                        ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= c_PIXEL_POS_MAX_VAL-1                                             ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)+1                                ; --! Pixel position: size bus (signed)

signal   mem_s1_dta_err_cor   : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(c_SQ1_DATA_FBK_S-1 downto 0)              ; --! Memory data storage SQUID1 Data error corrected
signal   s1_dta_err_cor_rd    : std_logic_vector( c_SQ1_DATA_FBK_S-1 downto 0)                              ; --! SQUID1 Data error corrected (signed) read from memory

signal   pls_cnt              : std_logic_vector(       c_PLS_CNT_S-1 downto 0)                             ; --! Pulse counter
signal   pixel_pos            : std_logic_vector(     c_PIXEL_POS_S-1 downto 0)                             ; --! Pixel position
signal   pixel_pos_inc        : std_logic_vector(     c_PIXEL_POS_S-2 downto 0)                             ; --! Pixel position increasing

signal   mem_sq1_fb0_pp       : std_logic                                                                   ; --! Squid1 feedback value in open loop, TH/HK side: ping-pong buffer bit
signal   mem_sq1_fb0_prm      : t_mem(
                                add(              c_MEM_S1FB0_ADD_S-1 downto 0),
                                data_w(          c_DFLD_S1FB0_PIX_S-1 downto 0))                            ; --! Squid1 feedback value in open loop, getting parameter side: memory inputs

signal   mem_sq1_fbm_pp       : std_logic                                                                   ; --! Squid1 feedback mode, TH/HK side: ping-pong buffer bit
signal   mem_sq1_fbm_prm      : t_mem(
                                add(              c_MEM_S1FBM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_S1FBM_PIX_S-1 downto 0))                            ; --! Squid1 feedback mode, getting parameter side: memory inputs

signal   sq1_fb_mode_sync     : std_logic_vector(c_DFLD_SQ1FBMD_COL_S-1 downto 0)                           ; --! Squid1 Feedback mode (on/off) synchronized on first Pixel sequence

signal   sq1_fbm              : std_logic_vector(c_DFLD_S1FBM_PIX_S-1 downto 0)                             ; --! Squid1 feedback mode

signal   sq1_fb0              : std_logic_vector(c_DFLD_S1FB0_PIX_S-1 downto 0)                             ; --! Squid1 feedback value in open loop (signed)
signal   sq1_fb0_rs           : std_logic_vector(  c_SQ1_DATA_FBK_S-1 downto 0)                             ; --! Squid1 feedback value in open loop (signed) resized
signal   sq1_fb_tst_pattern   : std_logic_vector(  c_SQ1_DATA_FBK_S-1 downto 0)                             ; --! Squid1 feedback test pattern (signed)

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
   P_sq1_fb_mode_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sq1_fb_mode_sync        <= c_DST_SQ1FBMD_OFF;
         mem_sq1_fb0_prm.pp      <= c_MEM_STR_ADD_PP_DEF;
         mem_sq1_fbm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = '1' then
            sq1_fb_mode_sync     <= i_sq1_fb_mode;
            mem_sq1_fb0_prm.pp   <= mem_sq1_fb0_pp;
            mem_sq1_fbm_prm.pp   <= mem_sq1_fbm_pp;

         end if;

      end if;

   end process P_sq1_fb_mode_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for Squid1 feedback value in open loop
   --    @Req : DRE-DMX-FW-REQ-0200
   --    @Req : REG_CY_SQ1_FB0
   -- ------------------------------------------------------------------------------------------------------
   I_mem_sq1_fb0_val: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_S1FB0_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_S1FB0_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_S1FB0     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90° shifted clock (used for memory content correction)

         i_a_mem              => i_mem_sq1_fb0        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_sq1_fb0_data       , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_sq1_fb0_pp       , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90° shifted clock (used for memory content correction)

         i_b_mem              => mem_sq1_fb0_prm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => sq1_fb0              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   sq1_fb0_rs(sq1_fb0_rs'high downto c_SQ1_DATA_FBK_S-c_DFLD_S1FB0_PIX_S) <= sq1_fb0;

   G_sq1_fb0_rs_lsb: if c_SQ1_DATA_FBK_S-c_DFLD_S1FB0_PIX_S > 0 generate
      sq1_fb0_rs(c_SQ1_DATA_FBK_S-c_DFLD_S1FB0_PIX_S-1 downto 0) <= (others => '0');

   end generate;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Squid1 feedback value in open loop: writing data signals
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_sq1_fb0_prm.add     <= pixel_pos_inc;
   mem_sq1_fb0_prm.we      <= '0';
   mem_sq1_fb0_prm.cs      <= '1';
   mem_sq1_fb0_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for Squid1 feedback mode
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : REG_CY_SQ1_FB_MODE
   -- ------------------------------------------------------------------------------------------------------
   I_mem_sq1_fbm_st: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_S1FBM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_S1FBM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_S1FBM     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90° shifted clock (used for memory content correction)

         i_a_mem              => i_mem_sq1_fbm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_sq1_fbm_data       , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_sq1_fbm_pp       , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90° shifted clock (used for memory content correction)

         i_b_mem              => mem_sq1_fbm_prm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => sq1_fbm              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Squid1 feedback mode: writing data signals
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_sq1_fbm_prm.add     <= pixel_pos_inc;
   mem_sq1_fbm_prm.we      <= '0';
   mem_sq1_fbm_prm.cs      <= '1';
   mem_sq1_fbm_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory data storage SQUID1 Data error corrected
   -- ------------------------------------------------------------------------------------------------------
   P_s1_dta_err_cor_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if i_s1_dta_err_cor_cs = '1' then
            mem_s1_dta_err_cor(to_integer(unsigned(i_s1_dta_pixel_pos))) <= i_s1_dta_err_cor;
         end if;
      end if;

   end process P_s1_dta_err_cor_wr;

   P_s1_dta_err_cor_rd : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         s1_dta_err_cor_rd <= (others => '0');

      elsif rising_edge(i_clk) then
         s1_dta_err_cor_rd <= mem_s1_dta_err_cor(to_integer(unsigned(pixel_pos_inc)));
      end if;

   end process P_s1_dta_err_cor_rd;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID1 Data feedback
   --    @Req : DRE-DMX-FW-REQ-0210
   -- ------------------------------------------------------------------------------------------------------
   P_sq1_data_fbk : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sq1_data_fbk <= (others => '0');

      elsif rising_edge(i_clk) then
         if sq1_fb_mode_sync = c_DST_SQ1FBMD_OFF then
            o_sq1_data_fbk <= (others => '0');

         elsif sq1_fbm = c_DST_SQ1FBMD_CLOSE then
            o_sq1_data_fbk <= s1_dta_err_cor_rd;

         elsif sq1_fbm = c_DST_SQ1FBMD_TEST then
            o_sq1_data_fbk <= sq1_fb_tst_pattern;

         else
            o_sq1_data_fbk <= sq1_fb0_rs;

         end if;
      end if;

   end process P_sq1_data_fbk;

   --TODO
   sq1_fb_tst_pattern      <= std_logic_vector(to_unsigned(0, o_sq1_data_fbk'length));

end architecture RTL;
