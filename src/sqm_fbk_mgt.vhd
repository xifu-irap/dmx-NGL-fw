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
--!   @file                   sqm_fbk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID MUX feedback management
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

entity sqm_fbk_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         i_sqm_dta_pixel_pos  : in     std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         i_sqm_dta_err_cor    : in     std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         i_sqm_dta_err_cor_cs : in     std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_smfb0          : in     t_mem(
                                       add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                     ; --! SQUID MUX feedback value in open loop: memory inputs
         o_smfb0_data         : out    std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                      ; --! SQUID MUX feedback value in open loop: data read

         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_smfbd              : in     std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback delay
         i_mem_smfbm          : in     t_mem(
                                       add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                     ; --! SQUID MUX feedback mode: memory inputs
         o_smfbm_data         : out    std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                      ; --! SQUID MUX feedback mode: data read

         o_sqm_data_fbk       : out    std_logic_vector( c_SQM_DATA_FBK_S-1 downto 0)                       ; --! SQUID MUX Data feedback (signed)

         o_init_fbk_pixel_pos : out    std_logic_vector(c_MUX_FACT_S-1      downto 0)                       ; --! Initialization feedback chain accumulators Pixel position
         o_init_fbk_acc       : out    std_logic                                                              --! Initialization feedback chain accumulators ('0' = Inactive, '1' = Active)
   );
end entity sqm_fbk_mgt;

architecture RTL of sqm_fbk_mgt is
constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_DAC_SYNC_DATA_NPER/2                        ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= c_PIXEL_POS_MAX_VAL - 1                                           ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)+1                                ; --! Pixel position: size bus (signed)

signal   mem_sqm_dta_err_cor  : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(c_SQM_DATA_FBK_S-1 downto 0)              ; --! Memory data storage SQUID MUX Data error corrected
signal   sqm_dta_err_cor_rd   : std_logic_vector( c_SQM_DATA_FBK_S-1 downto 0)                              ; --! SQUID MUX Data error corrected (signed) read from memory

signal   pls_cnt              : std_logic_vector(       c_PLS_CNT_S-1 downto 0)                             ; --! Pulse counter
signal   pls_cnt_init         : std_logic_vector(       c_PLS_CNT_S-1 downto 0)                             ; --! Pulse counter initialization
signal   pixel_pos            : std_logic_vector(     c_PIXEL_POS_S-1 downto 0)                             ; --! Pixel position
signal   pixel_pos_init       : std_logic_vector(     c_PIXEL_POS_S-1 downto 0)                             ; --! Pixel position initialization
signal   pixel_pos_inc        : std_logic_vector(     c_PIXEL_POS_S-2 downto 0)                             ; --! Pixel position increasing
signal   pixel_pos_inc_r      : t_slv_arr(0 to c_MEM_RD_DATA_NPER)(c_PIXEL_POS_S-2 downto 0)                ; --! Pixel position increasing register

signal   mem_smfb0_pp         : std_logic                                                                   ; --! SQUID MUX feedback value in open loop, TH/HK side: ping-pong buffer bit
signal   mem_smfb0_prm        : t_mem(
                                add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback value in open loop, getting parameter side: memory inputs

signal   mem_smfbm_pp         : std_logic                                                                   ; --! SQUID MUX feedback mode, TH/HK side: ping-pong buffer bit
signal   mem_smfbm_prm        : t_mem(
                                add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback mode, getting parameter side: memory inputs

signal   smfmd_sync           : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                             ; --! SQUID MUX feedback mode synchronized on first Pixel sequence
signal   smfmd_sync_r         : t_slv_arr(0 to c_MEM_RD_DATA_NPER-1)(c_DFLD_SMFMD_COL_S-1 downto 0)         ; --! SQUID MUX feedback mode synchronized on first Pixel sequence register

signal   smfbm                : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback mode

signal   smfb0                : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback value in open loop (signed)
signal   smfb0_rs             : std_logic_vector(  c_SQM_DATA_FBK_S-1 downto 0)                             ; --! SQUID MUX feedback value in open loop (signed) resized
signal   sqm_fb_tst_pattern   : std_logic_vector(  c_SQM_DATA_FBK_S-1 downto 0)                             ; --! SQUID MUX feedback test pattern (signed)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse shaping counter/Pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0280
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt_del : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)));
         pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

      elsif rising_edge(i_clk) then
         if    unsigned(i_smfbd) <= to_unsigned(c_DAC_SYNC_DATA_NPER, c_DFLD_SMFBD_COL_S) then
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)) + resize(unsigned(i_smfbd(i_smfbd'high downto 1)), pls_cnt_init'length));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         else
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT - c_PIXEL_DAC_NB_CYC/2, pls_cnt_init'length)) +
                            resize(unsigned(i_smfbd(i_smfbd'high downto 1)), pls_cnt_init'length));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT + 1 , pixel_pos'length));

         end if;

      end if;

   end process P_pls_cnt_del;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_cnt  <= std_logic_vector(to_unsigned(c_PLS_CNT_MAX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            pls_cnt <= pls_cnt_init;

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
   --    @Req : DRE-DMX-FW-REQ-0285
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pixel_pos   <= (others => '1');

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            pixel_pos <= pixel_pos_init;

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
   P_sig_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         smfmd_sync_r          <= (others => c_DST_SMFMD_OFF);
         smfmd_sync            <= c_DST_SMFMD_OFF;
         mem_smfb0_prm.pp      <= c_MEM_STR_ADD_PP_DEF;
         mem_smfbm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         smfmd_sync_r <= smfmd_sync & smfmd_sync_r(0 to smfmd_sync_r'high-1);

         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = '1' then
            smfmd_sync         <= i_smfmd;
            mem_smfb0_prm.pp   <= mem_smfb0_pp;
            mem_smfbm_prm.pp   <= mem_smfbm_pp;

         end if;

      end if;

   end process P_sig_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID MUX feedback value in open loop
   --    @Req : DRE-DMX-FW-REQ-0200
   --    @Req : REG_CY_MUX_SQ_FB0
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smfb0_val: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMFB0_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMFB0     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_smfb0          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_smfb0_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smfb0_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smfb0_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => smfb0                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   smfb0_rs(smfb0_rs'high downto c_SQM_DATA_FBK_S-c_DFLD_SMFB0_PIX_S) <= smfb0;

   G_smfb0_rs_lsb: if c_SQM_DATA_FBK_S-c_DFLD_SMFB0_PIX_S > 0 generate
      smfb0_rs(c_SQM_DATA_FBK_S-c_DFLD_SMFB0_PIX_S-1 downto 0) <= (others => '0');

   end generate;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory SQUID MUX feedback value in open loop: memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smfb0_prm.add     <= pixel_pos_inc;
   mem_smfb0_prm.we      <= '0';
   mem_smfb0_prm.cs      <= '1';
   mem_smfb0_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID MUX feedback mode
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : REG_CY_MUX_SQ_FB_MODE
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smfbm_st: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMFBM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMFBM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMFBM     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_smfbm          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_smfbm_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
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
   mem_smfbm_prm.add     <= pixel_pos_inc;
   mem_smfbm_prm.we      <= '0';
   mem_smfbm_prm.cs      <= '1';
   mem_smfbm_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory data storage SQUID MUX Data error corrected
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_dta_err_cor_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if i_sqm_dta_err_cor_cs = '1' then
            mem_sqm_dta_err_cor(to_integer(unsigned(i_sqm_dta_pixel_pos))) <= i_sqm_dta_err_cor;
         end if;
      end if;

   end process P_sqm_dta_err_cor_wr;

   P_sqm_dta_err_cor_rd : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_dta_err_cor_rd <= (others => '0');

      elsif rising_edge(i_clk) then
         sqm_dta_err_cor_rd <= mem_sqm_dta_err_cor(to_integer(unsigned(pixel_pos_inc)));
      end if;

   end process P_sqm_dta_err_cor_rd;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data feedback
   --    @Req : DRE-DMX-FW-REQ-0210
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_fbk : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sqm_data_fbk <= (others => '0');

      elsif rising_edge(i_clk) then
         if smfmd_sync = c_DST_SMFMD_OFF then
            o_sqm_data_fbk <= (others => '0');

         elsif smfbm = c_DST_SMFBM_CLOSE then
            o_sqm_data_fbk <= sqm_dta_err_cor_rd;

         elsif smfbm = c_DST_SMFBM_TEST then
            o_sqm_data_fbk <= sqm_fb_tst_pattern;

         else
            o_sqm_data_fbk <= smfb0_rs;

         end if;
      end if;

   end process P_sqm_data_fbk;

   -- ------------------------------------------------------------------------------------------------------
   --!   Initialization feedback chain accumulators
   -- ------------------------------------------------------------------------------------------------------
   P_init_fbk_acc : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pixel_pos_inc_r   <= (others => std_logic_vector(to_unsigned(0, c_PIXEL_POS_S-1)));
         o_init_fbk_acc    <= '1';

      elsif rising_edge(i_clk) then
         pixel_pos_inc_r   <= pixel_pos_inc & pixel_pos_inc_r(0 to pixel_pos_inc_r'high-1);

         if (smfbm = c_DST_SMFBM_CLOSE and smfmd_sync_r(smfmd_sync_r'high) = c_DST_SMFMD_ON) then
            o_init_fbk_acc <= '0';

         else
            o_init_fbk_acc <= '1';

         end if;

      end if;

   end process P_init_fbk_acc;

   o_init_fbk_pixel_pos <= pixel_pos_inc_r(pixel_pos_inc_r'high);

   --TODO
   sqm_fb_tst_pattern   <= std_logic_vector(to_unsigned(0, o_sqm_data_fbk'length));

end architecture RTL;
