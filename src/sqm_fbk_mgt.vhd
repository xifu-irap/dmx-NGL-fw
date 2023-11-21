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

entity sqm_fbk_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge
         i_tst_pat_end        : in     std_logic                                                            ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)

         i_test_pattern       : in     std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! Test pattern
         i_sqm_dta_pixel_pos  : in     std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         i_sqm_dta_err_cor    : in     std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         i_sqm_dta_err_cor_cs : in     std_logic                                                            ; --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)

         i_mem_smfb0          : in     t_mem(
                                       add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                     ; --! SQUID MUX feedback value in open loop: memory inputs
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_smfbd              : in     std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback delay
         i_mem_smfbm          : in     t_mem(
                                       add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                       data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                     ; --! SQUID MUX feedback mode: memory inputs
         o_smfbm_data         : out    std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                      ; --! SQUID MUX feedback mode: data read

         o_sqm_data_fbk       : out    std_logic_vector( c_SQM_DATA_FBK_S-1 downto 0)                       ; --! SQUID MUX Data feedback (signed)
         o_sqm_pixel_pos_init : out    std_logic_vector(  c_SQM_PXL_POS_S-1 downto 0)                       ; --! SQUID MUX Pixel position initialization
         o_sqm_pls_cnt_init   : out    std_logic_vector(  c_SQM_PLS_CNT_S-1 downto 0)                         --! SQUID MUX Pulse shaping counter initialization
   );
end entity sqm_fbk_mgt;

architecture RTL of sqm_fbk_mgt is
constant c_MINUSTWO           : std_logic_vector(c_SQM_PLS_CNT_S-1 downto 0):=
                                std_logic_vector(to_signed(-2, c_SQM_PLS_CNT_S))                            ; --! Minus two value

constant c_FRAME_NB_CYC       : integer := c_MUX_FACT * c_PIXEL_DAC_NB_CYC                                  ; --! Frame period number
constant c_FRAME_NB_CYC_S     : integer := log2_ceil(c_FRAME_NB_CYC)                                        ; --! Frame period number bus size
constant c_SMFBD_POSITIVE_S   : integer := c_FRAME_NB_CYC_S + 1                                             ; --! SQUID MUX feedback delay in positive bus size
constant c_SMFBD_CMP_R_S      : integer := 2 * c_DSP_NPER + 2                                               ; --! SQUID MUX feedback delay compare register bus size

constant c_PLS_CNT_INIT_SAT   : integer := c_SQM_PXL_POS_S + log2_ceil(c_PIXEL_DAC_NB_CYC+1)+1              ; --! Pulse counter initialization saturation
constant c_PLS_CNT_INIT_SHT   : integer := 2                                                                ; --! Pulse counter initialization number cycle shift
constant c_PLS_CNT_INIT_SHT_V : std_logic_vector(c_SMFBD_POSITIVE_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_PLS_CNT_INIT_SHT , c_SMFBD_POSITIVE_S))      ; --! Pulse counter initialization number cycle shift vector

constant c_FBK_PLS_CNT_NB_VAL : integer:= c_PIXEL_DAC_NB_CYC/2                                              ; --! Feedback Pulse counter: number of value
constant c_FBK_PLS_CNT_MX_VAL : integer:= c_FBK_PLS_CNT_NB_VAL - 2                                          ; --! Feedback Pulse counter: maximal value

constant c_PXL_POS_INIT_SAT   : integer := c_MULT_ALU_PORTA_S + c_SMFBD_POSITIVE_S                          ; --! Pixel position initialization saturation
constant c_PXL_DAC_NCYC_INV   : integer := div_round(2**(c_MULT_ALU_PORTA_S), c_PIXEL_DAC_NB_CYC)           ; --! DAC clock period number allocated to one pixel acquisition inverted
constant c_PXL_DAC_NCYC_INV_V : std_logic_vector(c_MULT_ALU_PORTA_S-1 downto 0) :=
                                std_logic_vector(to_unsigned(c_PXL_DAC_NCYC_INV , c_MULT_ALU_PORTA_S))      ; --! DAC clock period number allocated to one pixel acquisition inverted vector
constant c_PXL_DAC_NCYC_NEG_V : std_logic_vector(c_MULT_ALU_PORTA_S-1 downto 0) :=
                                std_logic_vector(to_signed(-c_PIXEL_DAC_NB_CYC , c_MULT_ALU_PORTA_S))       ; --! DAC clock period number allocated to one pixel acquisition negative vector

constant c_FBK_PXL_POS_INIT   : integer:= c_SQM_PXL_POS_MX_VAL - 1                                          ; --! Feedback Pixel position: initialization value
constant c_FBK_PXL_POS_SHIFT  : integer:= 2                                                                 ; --! Feedback Pixel position: shift

signal   tst_pat_end_r        : std_logic                                                                   ; --! Test pattern end of all patterns register
signal   tst_pat_end_dtc      : std_logic                                                                   ; --! Test pattern end of all patterns dectect
signal   tst_pat_end_sync     : std_logic                                                                   ; --! Test pattern end of all patterns, sync on pixel sequence
signal   test_pattern_sync    : std_logic_vector(  c_SQM_DATA_FBK_S-1 downto 0)                             ; --! Test pattern, synchronized on first pixel sequence

signal   mem_sqm_dta_err_cor  : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(c_SQM_DATA_FBK_S-1 downto 0)              ; --! Memory data storage SQUID MUX Data error corrected
signal   sqm_dta_err_cor_rd   : std_logic_vector( c_SQM_DATA_FBK_S-1 downto 0)                              ; --! SQUID MUX Data error corrected (signed) read from memory

signal   smfbd_r              : std_logic_vector(c_DFLD_SMFBD_COL_S-1 downto 0)                             ; --! SQUID MUX feedback delay register
signal   smfbd_cmp            : std_logic                                                                   ; --! SQUID MUX feedback delay compare
signal   smfbd_cmp_r          : std_logic_vector(   c_SMFBD_CMP_R_S-1 downto 0)                             ; --! SQUID MUX feedback delay compare register
signal   smfbd_positive       : std_logic_vector(c_SMFBD_POSITIVE_S-1 downto 0)                             ; --! SQUID MUX feedback delay in positive

signal   pixel_pos_div        : std_logic_vector(   c_SQM_PXL_POS_S-1 downto 0)                             ; --! Pixel position division result
signal   sqm_pixel_pos_init   : std_logic_vector(   c_SQM_PXL_POS_S-1 downto 0)                             ; --! SQUID MUX Pixel position initialization
signal   fbk_pixel_pos_init   : std_logic_vector(   c_SQM_PXL_POS_S-1 downto 0)                             ; --! Feedback Pixel position initialization
signal   pixel_pos_init       : std_logic_vector(   c_SQM_PXL_POS_S-1 downto 0)                             ; --! Feedback Pixel position initialization
signal   pixel_pos            : std_logic_vector(   c_SQM_PXL_POS_S-1 downto 0)                             ; --! Feedback Pixel position
signal   pixel_pos_inc        : std_logic_vector(   c_SQM_PXL_POS_S-2 downto 0)                             ; --! Feedback Pixel position increasing
signal   sqm_pls_cnt_init     : std_logic_vector(   c_SQM_PLS_CNT_S-1 downto 0)                             ; --! SQUID MUX Pulse shaping counter initialization
signal   pls_cnt_div_rem      : std_logic_vector(   c_SQM_PLS_CNT_S-1 downto 0)                             ; --! Pulse counter division remainder
signal   pls_cnt              : std_logic_vector(   c_SQM_PLS_CNT_S-2 downto 0)                             ; --! Feedback Pulse counter

signal   mem_smfb0_pp         : std_logic                                                                   ; --! SQUID MUX feedback value in open loop, TC/HK side: ping-pong buffer bit
signal   mem_smfb0_prm        : t_mem(
                                add(              c_MEM_SMFB0_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFB0_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback value in open loop, getting parameter side: memory inputs

signal   mem_smfbm_pp         : std_logic                                                                   ; --! SQUID MUX feedback mode, TC/HK side: ping-pong buffer bit
signal   mem_smfbm_prm        : t_mem(
                                add(              c_MEM_SMFBM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMFBM_PIX_S-1 downto 0))                            ; --! SQUID MUX feedback mode, getting parameter side: memory inputs

signal   smfmd_sync           : std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                             ; --! SQUID MUX feedback mode synchronized on first Pixel sequence

signal   smfbm                : std_logic_vector(c_DFLD_SMFBM_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback mode
signal   smfb0                : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback value in open loop (signed)
signal   smfb0_rs             : std_logic_vector(  c_SQM_DATA_FBK_S-1 downto 0)                             ; --! SQUID MUX feedback value in open loop resized data stalled on MSB (signed)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern end of all patterns
   -- ------------------------------------------------------------------------------------------------------
   P_tst_pat_end : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_pat_end_r     <= c_HGH_LEV;
         tst_pat_end_dtc   <= c_LOW_LEV;
         tst_pat_end_sync  <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         tst_pat_end_r     <= i_tst_pat_end;

         if (not(tst_pat_end_r) and i_tst_pat_end) = c_HGH_LEV then
            tst_pat_end_dtc <= c_HGH_LEV;

         elsif i_sync_re = c_HGH_LEV then
            tst_pat_end_dtc <= c_LOW_LEV;

         end if;

         if i_sync_re = c_HGH_LEV then
            tst_pat_end_sync  <= tst_pat_end_dtc;

         end if;

      end if;

   end process P_tst_pat_end;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX feedback delay compare
   -- ------------------------------------------------------------------------------------------------------
   P_smfbd_cmp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         smfbd_r     <= c_EP_CMD_DEF_SMFBD;
         smfbd_cmp   <= c_LOW_LEV;
         smfbd_cmp_r <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         smfbd_r  <= i_smfbd;

         if smfbd_r /= i_smfbd then
            smfbd_cmp <= c_HGH_LEV;

         else
            smfbd_cmp <= c_LOW_LEV;

         end if;
         smfbd_cmp_r <= smfbd_cmp_r(smfbd_cmp_r'high-1 downto 0) & smfbd_cmp;

      end if;

   end process P_smfbd_cmp;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX feedback delay in positive
   -- ------------------------------------------------------------------------------------------------------
   P_smfbd_positive : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         smfbd_positive  <= c_ZERO(smfbd_positive'range);

      elsif rising_edge(i_clk) then
         if i_smfbd(i_smfbd'high) = c_HGH_LEV then
            smfbd_positive <= std_logic_vector(signed(to_unsigned(c_FRAME_NB_CYC-c_DAC_SYNC_DATA_NPER-c_PLS_CNT_INIT_SHT, smfbd_positive'length))
                                      + resize(signed(i_smfbd), smfbd_positive'length));

         else
            smfbd_positive <= std_logic_vector(resize(signed(i_smfbd), smfbd_positive'length) - signed(to_unsigned(c_DAC_SYNC_DATA_NPER + c_PLS_CNT_INIT_SHT, smfbd_positive'length)));

         end if;

      end if;

   end process P_smfbd_positive;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position division result
   -- ------------------------------------------------------------------------------------------------------
   I_pixel_pos_div: entity work.dsp generic map (
         g_PORTA_S            => c_MULT_ALU_PORTA_S   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SMFBD_POSITIVE_S   , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_MULT_ALU_PORTC_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_SQM_PXL_POS_S      , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_MULT_ALU_PORTA_S   , -- integer                                          ; --! Result LSB position
         g_SAT_RANK           => c_PXL_POS_INIT_SAT   , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => c_PXL_DAC_NCYC_INV_V , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => smfbd_positive       , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => c_ZERO(c_MULT_ALU_PORTC_S-1 downto 0),  -- in slv( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_PLS_CNT_INIT_SHT_V , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => pixel_pos_div        , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter division remainder
   -- ------------------------------------------------------------------------------------------------------
   I_pls_cnt_div_rem: entity work.dsp generic map (
         g_PORTA_S            => c_MULT_ALU_PORTA_S   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SQM_PXL_POS_S      , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SMFBD_POSITIVE_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_SQM_PLS_CNT_S      , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_ZERO_INT           , -- integer                                          ; --! Result LSB position
         g_SAT_RANK           => c_PLS_CNT_INIT_SAT   , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => c_LOW_LEV_B          , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => c_LOW_LEV_B            -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => c_LOW_LEV            , -- in     std_logic                                 ; --! Carry In
         i_a                  => c_PXL_DAC_NCYC_NEG_V , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => pixel_pos_div        , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => smfbd_positive       , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => c_ZERO(c_SQM_PXL_POS_S-1 downto 0),     -- in slv( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => c_ZERO(c_MULT_ALU_RESULT_S-1 downto 0), -- in slv c_MULT_ALU_RESULT_S      ; --! Cascaded Result Input

         o_z                  => pls_cnt_div_rem      , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0280
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_pixel_pos_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_pixel_pos_init <= c_MINUSONE(sqm_pixel_pos_init'range);

      elsif rising_edge(i_clk) then
         if pls_cnt_div_rem = c_MINUSTWO then
            if pixel_pos_div = c_MINUSONE(pixel_pos_div'range) then
               sqm_pixel_pos_init <= std_logic_vector(to_unsigned(c_SQM_PXL_POS_MX_VAL, sqm_pixel_pos_init'length));

            else
               sqm_pixel_pos_init <= std_logic_vector(signed(pixel_pos_div) - 1);

            end if;

         else
            sqm_pixel_pos_init <= pixel_pos_div;

         end if;

      end if;

   end process P_sqm_pixel_pos_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Internal pixel position initialization
   --    @Req : DRE-DMX-FW-REQ-0280
   -- ------------------------------------------------------------------------------------------------------
   P_fbk_pixel_pos_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_FBK_PXL_POS_INIT, fbk_pixel_pos_init'length));

      elsif rising_edge(i_clk) then
         if    sqm_pixel_pos_init = c_ZERO(sqm_pixel_pos_init'range) then
            fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_SQM_PXL_POS_MX_VAL, fbk_pixel_pos_init'length));

         elsif sqm_pixel_pos_init = c_MINUSONE(sqm_pixel_pos_init'range) then
            fbk_pixel_pos_init <= std_logic_vector(to_unsigned(c_SQM_PXL_POS_MX_VAL-1, fbk_pixel_pos_init'length));

         else
            fbk_pixel_pos_init <= std_logic_vector(signed(sqm_pixel_pos_init) - c_FBK_PXL_POS_SHIFT);

         end if;

      end if;

   end process P_fbk_pixel_pos_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Pulse counter initialization
   --    @Req : DRE-DMX-FW-REQ-0280
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_pls_cnt_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_pls_cnt_init  <= c_MINUSONE(sqm_pls_cnt_init'range);

      elsif rising_edge(i_clk) then
         if pls_cnt_div_rem = c_MINUSTWO then
            sqm_pls_cnt_init <= std_logic_vector(to_unsigned(c_SQM_PLS_CNT_MX_VAL, sqm_pls_cnt_init'length));

         else
            sqm_pls_cnt_init <= pls_cnt_div_rem;

         end if;

      end if;

   end process P_sqm_pls_cnt_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX initialization outputs
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_init : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqm_pixel_pos_init <= std_logic_vector(to_signed(c_SQM_PXL_POS_INIT, o_sqm_pixel_pos_init'length));
         pixel_pos_init       <= std_logic_vector(to_signed(c_FBK_PXL_POS_INIT, pixel_pos_init'length));
         o_sqm_pls_cnt_init   <= std_logic_vector(to_signed(c_SQM_PLS_CNT_INIT, o_sqm_pls_cnt_init'length));

      elsif rising_edge(i_clk) then
         if smfbd_cmp_r(smfbd_cmp_r'high) = c_HGH_LEV then
            o_sqm_pixel_pos_init <= sqm_pixel_pos_init;
            pixel_pos_init       <= fbk_pixel_pos_init;
            o_sqm_pls_cnt_init   <= sqm_pls_cnt_init;

         end if;

      end if;

   end process P_sqm_init;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pulse counter
   -- ------------------------------------------------------------------------------------------------------
   P_pls_cnt : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         pls_cnt  <= std_logic_vector(to_unsigned(c_FBK_PLS_CNT_MX_VAL, pls_cnt'length));

      elsif rising_edge(i_clk) then
         if i_sync_re = c_HGH_LEV then
            pls_cnt <= o_sqm_pls_cnt_init(o_sqm_pls_cnt_init'high downto 1);

         elsif pls_cnt(pls_cnt'high) = c_HGH_LEV then
            pls_cnt <= std_logic_vector(to_unsigned(c_FBK_PLS_CNT_MX_VAL, pls_cnt'length));

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

      if i_rst = c_RST_LEV_ACT then
         pixel_pos   <= c_MINUSONE(pixel_pos'range);

      elsif rising_edge(i_clk) then
         if i_sync_re = c_HGH_LEV then
            pixel_pos <= pixel_pos_init;

         elsif (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(to_unsigned(c_SQM_PXL_POS_MX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_pos;

   pixel_pos_inc <= std_logic_vector(resize(unsigned(to_signed(c_SQM_PXL_POS_MX_VAL, pixel_pos'length) - signed(pixel_pos)), pixel_pos_inc'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals synchronized on first Pixel sequence
   -- ------------------------------------------------------------------------------------------------------
   P_sig_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         smfmd_sync            <= c_DST_SMFMD_OFF;
         mem_smfb0_prm.pp      <= c_MEM_STR_ADD_PP_DEF;
         mem_smfbm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (pls_cnt(pls_cnt'high) and pixel_pos(pixel_pos'high)) = c_HGH_LEV then
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
   I_mem_smfb0_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMFB0_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMFB0     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_smfb0          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => open                 , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smfb0_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smfb0_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => smfb0                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory SQUID MUX feedback value in open loop: memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smfb0_prm.add     <= pixel_pos_inc;
   mem_smfb0_prm.we      <= c_LOW_LEV;
   mem_smfb0_prm.cs      <= c_HGH_LEV;
   mem_smfb0_prm.data_w  <= c_ZERO(mem_smfb0_prm.data_w'range);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for SQUID MUX feedback mode
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : REG_CY_MUX_SQ_FB_MODE
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
   mem_smfbm_prm.cs      <= c_HGH_LEV;
   mem_smfbm_prm.data_w  <= c_DST_SMFBM_OPEN;

   --! SQUID MUX feedback mode, memory write enable
   P_mem_smfbm_prm_we : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_smfbm_prm.we  <= c_LOW_LEV;

      elsif rising_edge(i_clk) then
         if (smfbm = c_DST_SMFBM_TEST) and (pls_cnt = std_logic_vector(to_unsigned(c_MEM_RD_DATA_NPER, pls_cnt'length))) and (tst_pat_end_sync = c_HGH_LEV) then
            mem_smfbm_prm.we  <= c_HGH_LEV;

         else
            mem_smfbm_prm.we  <= c_LOW_LEV;

         end if;

      end if;

   end process P_mem_smfbm_prm_we;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory data storage SQUID MUX Data error corrected
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_dta_err_cor_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         if i_sqm_dta_err_cor_cs = c_HGH_LEV then
            mem_sqm_dta_err_cor(to_integer(unsigned(i_sqm_dta_pixel_pos))) <= i_sqm_dta_err_cor;
         end if;
      end if;

   end process P_sqm_dta_err_cor_wr;

   --! SQUID MUX Data error corrected: memory read
   P_sqm_dta_err_cor_rd : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sqm_dta_err_cor_rd <= c_ZERO(sqm_dta_err_cor_rd'range);

      elsif rising_edge(i_clk) then
         sqm_dta_err_cor_rd <= mem_sqm_dta_err_cor(to_integer(unsigned(pixel_pos_inc)));
      end if;

   end process P_sqm_dta_err_cor_rd;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern, synchronized at pixel sequence start
   -- ------------------------------------------------------------------------------------------------------
   I_smfb0_rs : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SQM_DATA_FBK_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => smfb0                , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => smfb0_rs             , -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)        ; --! Data stalled on Mean Significant Bit
         o_data               => open                   -- out    slv(          g_DATA_S-1 downto 0)          --! Data
   );

   --! Test pattern, synchronized on first pixel sequence
   P_test_pattern_sync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         test_pattern_sync <= c_ZERO(test_pattern_sync'range);

      elsif rising_edge(i_clk) then
         if (pixel_pos(pixel_pos'high) and pls_cnt(pls_cnt'high)) = c_HGH_LEV then
            if i_tst_pat_end = c_LOW_LEV then
               test_pattern_sync <= i_test_pattern;

            else
               test_pattern_sync <= smfb0_rs;

            end if;

         end if;

      end if;

   end process P_test_pattern_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data feedback
   --    @Req : DRE-DMX-FW-REQ-0210
   --    @Req : DRE-DMX-FW-REQ-0450
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_fbk : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sqm_data_fbk <= c_ZERO(o_sqm_data_fbk'range);

      elsif rising_edge(i_clk) then
         if smfmd_sync = c_DST_SMFMD_OFF then
            o_sqm_data_fbk <= c_ZERO(o_sqm_data_fbk'range);

         elsif smfbm = c_DST_SMFBM_CLOSE then
            o_sqm_data_fbk <= sqm_dta_err_cor_rd;

         elsif smfbm = c_DST_SMFBM_TEST then
            o_sqm_data_fbk <= test_pattern_sync;

         elsif smfbm = c_DST_SMFBM_OPEN then
            o_sqm_data_fbk <= smfb0_rs;

         end if;
      end if;

   end process P_sqm_data_fbk;

end architecture RTL;
