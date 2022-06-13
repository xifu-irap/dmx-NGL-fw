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
--!   @file                   sqa_fbk_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SQUID AMP Feedback management
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

entity sqa_fbk_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         i_saofm              : in     std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                      ; --! SQUID AMP offset mode
         i_saofc              : in     std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                      ; --! SQUID AMP lockpoint coarse offset

         i_saomd              : in     std_logic_vector(c_DFLD_SAOMD_COL_S-1 downto 0)                      ; --! SQUID AMP offset MUX delay
         i_sqm_dta_err_cor    : in     std_logic_vector(c_SQM_DATA_FBK_S  -1 downto 0)                      ; --! SQUID MUX Data error corrected (signed)

         i_mem_saoff          : in     t_mem(
                                       add(              c_MEM_SAOFF_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SAOFF_PIX_S-1 downto 0))                     ; --! SQUID AMP lockpoint fine offset: memory inputs
         o_saoff_data         : out    std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                      ; --! SQUID AMP lockpoint fine offset: data read

         o_sqa_fbk_mux        : out    std_logic_vector(c_DFLD_SAOFF_PIX_S-1 downto 0)                      ; --! SQUID AMP Feedback Multiplexer
         o_sqa_fbk_off        : out    std_logic_vector(c_DFLD_SAOFC_COL_S-1 downto 0)                        --! SQUID AMP coarse offset

   );
end entity sqa_fbk_mgt;

architecture RTL of sqa_fbk_mgt is
constant c_PLS_RW_CNT_NB_VAL  : integer:= c_PIXEL_DAC_NB_CYC * c_MUX_FACT/2                                 ; --! Pulse by row counter: number of value
constant c_PLS_RW_CNT_MAX_VAL : integer:= c_PLS_RW_CNT_NB_VAL - 2                                           ; --! Pulse by row counter: maximal value
constant c_PLS_RW_CNT_INIT    : integer:= c_PLS_RW_CNT_MAX_VAL - c_SAD_SYNC_DATA_NPER/2 - 4                 ; --! Pulse by row counter: initialization value
constant c_PLS_RW_CNT_S       : integer:= log2_ceil(c_PLS_RW_CNT_MAX_VAL + 1) + 1                           ; --! Pulse by row counter: size bus (signed)

constant c_PLS_CNT_NB_VAL     : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Pulse counter: number of value
constant c_PLS_CNT_MAX_VAL    : integer:= c_PLS_CNT_NB_VAL - 2                                              ; --! Pulse counter: maximal value
constant c_PLS_CNT_INIT       : integer:= c_PLS_CNT_MAX_VAL - c_SAM_SYNC_DATA_NPER/2                        ; --! Pulse counter: initialization value
constant c_PLS_CNT_S          : integer:= log2_ceil(c_PLS_CNT_MAX_VAL + 1) + 1                              ; --! Pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 2                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_INIT     : integer:= c_PIXEL_POS_MAX_VAL-1                                             ; --! Pixel position: initialization value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1) + 1                              ; --! Pixel position: size bus (signed)

signal   pls_rw_cnt           : std_logic_vector(c_PLS_RW_CNT_S-1 downto 0)                                 ; --! Pulse by row counter
signal   pls_cnt              : std_logic_vector(  c_PLS_CNT_S-1 downto 0)                                  ; --! Pulse shaping counter
signal   pls_cnt_init         : std_logic_vector(       c_PLS_CNT_S-1 downto 0)                             ; --! Pulse counter initialization
signal   pixel_pos            : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! Pixel position
signal   pixel_pos_init       : std_logic_vector(     c_PIXEL_POS_S-1 downto 0)                             ; --! Pixel position initialization
signal   pixel_pos_inc        : std_logic_vector(c_PIXEL_POS_S-2 downto 0)                                  ; --! Pixel position increasing

signal   mem_saoff_pp         : std_logic                                                                   ; --! SQUID AMP lockpoint fine offset, TH/HK side: ping-pong buffer bit
signal   mem_saoff_prm        : t_mem(
                                add(           c_MEM_SAOFF_ADD_S-1 downto 0),
                                data_w(       c_DFLD_SAOFF_PIX_S-1 downto 0))                               ; --! SQUID AMP lockpoint fine offset, getting parameter side: memory inputs

signal   saofm_sync           : std_logic_vector(c_DFLD_SAOFM_COL_S-1 downto 0)                             ; --! SQUID AMP offset mode synchronized on first Pixel sequence
signal   sqa_fb_close         : std_logic_vector(c_SQA_DAC_DATA_S-1 downto 0)                               ; --! SQUID AMP feedback close mode
signal   sqa_fb_tst_pattern   : std_logic_vector(c_SQA_DAC_DATA_S-1 downto 0)                               ; --! SQUID AMP feedback test pattern mode
signal   saoff                : std_logic_vector(c_SQA_DAC_MUX_S-1  downto 0)                               ; --! SQUID AMP lockpoint fine offset

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse by row counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_rw_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_INIT, pls_rw_cnt'length));

         elsif pls_rw_cnt(pls_rw_cnt'high) = '1' then
            pls_rw_cnt <= std_logic_vector(to_unsigned(c_PLS_RW_CNT_MAX_VAL, pls_rw_cnt'length));

         else
            pls_rw_cnt <= std_logic_vector(signed(pls_rw_cnt) - 1);

         end if;

      end if;

   end process P_pls_rw_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter/Pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0380
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt_del : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)));
         pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

      elsif rising_edge(i_clk) then
         if    unsigned(i_saomd) <= to_unsigned(c_SAM_SYNC_DATA_NPER, c_DFLD_SAOMD_COL_S) then
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT, pls_cnt_init'length)) + resize(unsigned(i_saomd(i_saomd'high downto 1)), pls_cnt_init'length));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT , pixel_pos'length));

         else
            pls_cnt_init   <= std_logic_vector(unsigned(to_signed(c_PLS_CNT_INIT - c_PIXEL_DAC_NB_CYC/2, pls_cnt_init'length)) + resize(unsigned(i_saomd(i_saomd'high downto 1)),pls_cnt_init'length));
            pixel_pos_init <= std_logic_vector(to_signed(c_PIXEL_POS_INIT + 1 , pixel_pos'length));

         end if;

      end if;

   end process P_pls_cnt_del;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   --    @Req : DRE-DMX-FW-REQ-0375
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
   --    @Req : DRE-DMX-FW-REQ-0385
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
         saofm_sync           <= c_DST_SAOFM_OFF;
         mem_saoff_prm.pp     <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = '1' then
            saofm_sync        <= i_saofm;
            mem_saoff_prm.pp  <= mem_saoff_pp;

         end if;

      end if;

   end process P_sig_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID AMP lockpoint fine offset
   --    @Req : REG_CY_AMP_SQ_OFFSET_FINE
   --    @Req : DRE-DMX-FW-REQ-0300
   -- ------------------------------------------------------------------------------------------------------
   I_mem_sqa_pxl_lkp: entity work.dmem_ecc generic map
   (     g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SAOFF_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SAOFF_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SAOFF     -- t_int_arr                                          --! Memory content at initialization
   ) port map
   (     i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_saoff          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_saoff_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_saoff_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_saoff_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => saoff                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory SQUID AMP lockpoint fine offset signals: writing data signals
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_saoff_prm.add     <= pixel_pos_inc;
   mem_saoff_prm.we      <= '0';
   mem_saoff_prm.cs      <= '1';
   mem_saoff_prm.data_w  <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP feedback Multiplexer
   --    @Req : DRE-DMX-FW-REQ-0330
   --    @Req : DRE-DMX-FW-REQ-0360
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fbk_mux : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sqa_fbk_mux <= (others => '0');

      elsif rising_edge(i_clk) then
         if saofm_sync = c_DST_SAOFM_OFFSET then
            o_sqa_fbk_mux <= saoff;

         else
            o_sqa_fbk_mux <= (others => '0');

         end if;

      end if;

   end process P_sqa_fbk_mux;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID AMP coarse offset
   --    @Req : DRE-DMX-FW-REQ-0290
   --    @Req : DRE-DMX-FW-REQ-0330
   -- ------------------------------------------------------------------------------------------------------
   P_sqa_fbk_off : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sqa_fbk_off <= c_EP_CMD_DEF_SAOFC;

      elsif rising_edge(i_clk) then
         if pls_rw_cnt(pls_rw_cnt'high) = '1' then

            if i_saofm = c_DST_SAOFM_OFFSET then
               o_sqa_fbk_off <= i_saofc;

            elsif i_saofm = c_DST_SAOFM_CLOSE then
               o_sqa_fbk_off <= sqa_fb_close;

            elsif i_saofm = c_DST_SAOFM_TEST then
               o_sqa_fbk_off <= sqa_fb_tst_pattern;

            else
               o_sqa_fbk_off <= std_logic_vector(to_unsigned(c_SQA_DAC_MDL_POINT,c_SQA_DAC_DATA_S));

            end if;

         end if;

      end if;

   end process P_sqa_fbk_off;

   --TODO
   sqa_fb_close    <=  i_sqm_dta_err_cor(i_sqm_dta_err_cor'high downto i_sqm_dta_err_cor'length-sqa_fb_close'length);
   sqa_fb_tst_pattern   <=  x"555";

end architecture RTL;
