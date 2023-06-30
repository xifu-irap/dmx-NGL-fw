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
--!   @file                   test_pattern_gen.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Test pattern generation
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

entity test_pattern_gen is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge
         i_tsten_lop          : in     std_logic_vector(c_DFLD_TSTEN_LOP_S-1 downto 0)                      ; --! Test pattern enable, field Loop number
         i_tsten_inf          : in     std_logic                                                            ; --! Test pattern enable, field Infinity loop ('0' = Inactive, '1' = Active)
         i_tsten_ena          : in     std_logic                                                            ; --! Test pattern enable, field Enable ('0' = Inactive, '1' = Active)

         i_mem_tstpt          : in     t_mem(
                                       add(c_MEM_TSTPT_ADD_S-1 downto 0),
                                       data_w(c_DFLD_TSTPT_S-1 downto 0))                                   ; --! Test pattern: memory inputs
         o_tstpt_data         : out    std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                          ; --! Test pattern: data read

         o_test_pattern_sqm   : out    std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! Test pattern: MUX SQUID
         o_test_pattern_sqa   : out    std_logic_vector(c_SQA_DAC_DATA_S-1 downto 0)                        ; --! Test pattern: AMP SQUID
         o_test_pattern_sc    : out    std_logic_vector(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0)      ; --! Test pattern: Science Telemetry
         o_tst_pat_end_pat    : out    std_logic                                                            ; --! Test pattern end of one pattern  ('0' = Inactive, '1' = Active)
         o_tst_pat_end        : out    std_logic                                                            ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)
         o_tst_pat_end_re     : out    std_logic                                                            ; --! Test pattern end of all patterns rising edge ('0' = Inactive, '1' = Active)
         o_tst_pat_empty      : out    std_logic                                                              --! Test pattern empty ('0' = No, '1' = Yes)

   );
end entity test_pattern_gen;

architecture RTL of test_pattern_gen is
constant c_TST_RG_POS_MAX_VAL : integer   := (c_TST_PAT_RGN_NB - 1) * c_TST_PAT_COEF_NB                     ; --! Test pattern region position: maximal value
constant c_TST_RG_POS_S       : integer   := log2_ceil(c_TST_RG_POS_MAX_VAL + 1) + 1                        ; --! Test pattern region position: size bus (signed)

constant c_TST_CF_POS_MAX_VAL : integer   := c_TST_PAT_COEF_NB - 2                                          ; --! Test pattern coefficient position: maximal value
constant c_TST_CF_POS_S       : integer   := log2_ceil(c_TST_CF_POS_MAX_VAL + 1) + 1                        ; --! Test pattern coefficient position: size bus (signed)

constant c_TST_INDMAX1_POS    : integer   := c_MEM_RD_DATA_NPER                                             ; --! Test pattern: Index Maximum First reading position
constant c_TST_INDMAX_CHK_POS : integer   := c_TST_INDMAX1_POS    + 1                                       ; --! Test pattern: Index Maximum Check position
constant c_TST_INDMAX2_POS    : integer   := c_TST_INDMAX_CHK_POS + c_MEM_RD_DATA_NPER + 1                  ; --! Test pattern: Index Maximum Second reading position
constant c_TST_ITCPT_COEF_POS : integer   := c_TST_INDMAX2_POS    + 1                                       ; --! Test pattern: Intercept coefficient position
constant c_TST_SLOPE_COEF_POS : integer   := c_TST_ITCPT_COEF_POS + 1                                       ; --! Test pattern: Slope coefficient position
constant c_TST_RES_POS        : integer   := c_TST_SLOPE_COEF_POS + c_DSP_NPER                              ; --! Test pattern: Result position

signal   mem_tstpt_pp         : std_logic                                                                   ; --! Test pattern, TC/HK side: ping-pong buffer bit
signal   mem_tstpt_prm        : t_mem(
                                add(          c_MEM_TSTPT_ADD_S-1 downto 0),
                                data_w(          c_DFLD_TSTPT_S-1 downto 0))                                ; --! Test pattern, getting parameter side: memory inputs

signal   sync_re_r            : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge register
signal   loop_nb_minus1       : std_logic_vector(c_DFLD_TSTEN_LOP_S  downto 0)                              ; --! Loop number minus 1

signal   tst_region_pos       : std_logic_vector(c_TST_RG_POS_S-1    downto 0)                              ; --! Test pattern: region position
signal   tst_region_pos_msb_r : std_logic                                                                   ; --! Test pattern: region position MSB register
signal   tst_coef_pos         : std_logic_vector(c_TST_CF_POS_S-1    downto 0)                              ; --! Test pattern: coefficient position
signal   tst_pos              : std_logic_vector(c_MEM_TSTPT_ADD_S   downto 0)                              ; --! Test pattern: global position
signal   tst_coef_sel         : std_logic_vector(c_TST_RES_POS       downto 0)                              ; --! Test pattern: coefficient select

signal   tst_prm              : std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                                 ; --! Test pattern: parameters from memory
signal   tst_slope_coef       : std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                                 ; --! Test pattern: Slope coefficient
signal   tst_itcpt_coef       : std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                                 ; --! Test pattern: Intercept coefficient
signal   tst_index_max        : std_logic_vector(c_DFLD_TSTPT_S   downto 0)                                 ; --! Test pattern: Index Maximum
signal   tst_index            : std_logic_vector(c_DFLD_TSTPT_S   downto 0)                                 ; --! Test pattern: Index
signal   tst_index_minus1     : std_logic_vector(c_DFLD_TSTPT_S   downto 0)                                 ; --! Test pattern: Index minus 1
signal   tst_res              : std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                                 ; --! Test pattern: Result
signal   test_pattern         : std_logic_vector(c_DFLD_TSTPT_S-1 downto 0)                                 ; --! Test pattern

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence synchronization, rising edge register
   -- ------------------------------------------------------------------------------------------------------
   P_sync_re_r : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         sync_re_r   <= '0';

      elsif rising_edge(i_clk) then
         sync_re_r   <= i_sync_re;

      end if;

   end process P_sync_re_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Loop number minus 1
   -- ------------------------------------------------------------------------------------------------------
   P_loop_nb_minus1 : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         loop_nb_minus1 <= (others => '1');

      elsif rising_edge(i_clk) then
         loop_nb_minus1 <= std_logic_vector(signed(resize(unsigned(i_tsten_lop), loop_nb_minus1'length)) - 1);

      end if;

   end process P_loop_nb_minus1;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern: region position
   -- ------------------------------------------------------------------------------------------------------
   P_tst_region_pos : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_region_pos       <= std_logic_vector(to_signed(-c_TST_PAT_COEF_NB, tst_region_pos'length));
         tst_region_pos_msb_r <= '1';

      elsif rising_edge(i_clk) then
         if i_tsten_ena = '0' then
            tst_region_pos <= std_logic_vector(to_signed(-c_TST_PAT_COEF_NB, tst_region_pos'length));

         elsif tst_coef_sel(c_TST_INDMAX_CHK_POS) = '1' and tst_index_max = std_logic_vector(to_unsigned(0, tst_index_max'length)) then
            tst_region_pos <= std_logic_vector(to_unsigned(c_TST_RG_POS_MAX_VAL, tst_region_pos'length));

         elsif ((i_sync_re or sync_re_r) and tst_region_pos(tst_region_pos'high)) = '1' then
            tst_region_pos <= std_logic_vector(to_unsigned(c_TST_RG_POS_MAX_VAL, tst_region_pos'length));

         elsif (i_sync_re and not(tst_region_pos(tst_region_pos'high))) = '1' and unsigned(tst_index) >= unsigned(tst_index_max) then
            tst_region_pos <= std_logic_vector(signed(tst_region_pos) - to_signed(c_TST_PAT_COEF_NB, tst_region_pos'length));

         end if;

         tst_region_pos_msb_r <= tst_region_pos(tst_region_pos'high);

      end if;

   end process P_tst_region_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern: coefficient position
   -- ------------------------------------------------------------------------------------------------------
   P_tst_coef_pos : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_coef_pos <= (others => '1');

      elsif rising_edge(i_clk) then
         if i_tsten_ena = '1' then
            if (sync_re_r or tst_coef_sel(c_TST_INDMAX_CHK_POS)) = '1' then
               tst_coef_pos <= std_logic_vector(to_unsigned(c_TST_CF_POS_MAX_VAL, tst_coef_pos'length));

            elsif tst_coef_pos(tst_coef_pos'high) = '0' then
               tst_coef_pos <= std_logic_vector(signed(tst_coef_pos) - 1);

            end if;

         end if;

      end if;

   end process P_tst_coef_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern: coefficient select
   -- ------------------------------------------------------------------------------------------------------
   P_tst_coef_sel : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_coef_sel <= (others => '0');

      elsif rising_edge(i_clk) then
         if i_tsten_ena = '1' then
            tst_coef_sel <= tst_coef_sel(tst_coef_sel'high-1 downto 0) & sync_re_r;

         end if;

      end if;

   end process P_tst_coef_sel;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for test pattern parameters
   --    @Req : REG_TEST_PATTERN
   --    @Req : DRE-DMX-FW-REQ-0440
   -- ------------------------------------------------------------------------------------------------------
   I_mem_tstpt_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_TSTPT_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_TSTPT_S       , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_TSTPT     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_tstpt          , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_tstpt_data         , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_tstpt_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_tstpt_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => tst_prm              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory test pattern parameters: memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   tst_pos <=  std_logic_vector(to_signed(c_TST_RG_POS_MAX_VAL + 1, tst_pos'length) -
                                resize(signed(tst_region_pos), tst_pos'length) +
                                resize(signed(tst_coef_pos),   tst_pos'length));

   mem_tstpt_prm.add     <= tst_pos(tst_pos'high-1 downto 0);
   mem_tstpt_prm.we      <= '0';
   mem_tstpt_prm.cs      <= '1';
   mem_tstpt_prm.data_w  <= (others => '0');

   P_mem_tstpt_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_tstpt_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if tst_region_pos(tst_region_pos'high) = '1' then
            mem_tstpt_prm.pp   <= mem_tstpt_pp;

         end if;

      end if;

   end process P_mem_tstpt_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern parameters dispatch
   -- ------------------------------------------------------------------------------------------------------
   P_tst_prm_dispatch : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_slope_coef <= (others => '0');
         tst_itcpt_coef <= (others => '0');
         tst_index_max  <= (others => '0');

      elsif rising_edge(i_clk) then
         if tst_coef_sel(c_TST_SLOPE_COEF_POS) = '1' then
            tst_slope_coef <= tst_prm;

         end if;

         if tst_coef_sel(c_TST_ITCPT_COEF_POS) = '1' then
            tst_itcpt_coef <= tst_prm;

         end if;

         if (tst_coef_sel(c_TST_INDMAX1_POS) or tst_coef_sel(c_TST_INDMAX2_POS)) = '1' then
            tst_index_max <= std_logic_vector(resize(unsigned(tst_prm), tst_index_max'length));

         end if;

      end if;

   end process P_tst_prm_dispatch;

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern index
   -- ------------------------------------------------------------------------------------------------------
   P_tst_index : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         tst_index <= (others => '0');

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            if (tst_region_pos(tst_region_pos'high) = '1') or (unsigned(tst_index) >= unsigned(tst_index_max)) then
               tst_index <= std_logic_vector(to_unsigned(1, tst_index'length));

            else
               tst_index <= std_logic_vector(unsigned(tst_index) + 1);

            end if;

         end if;

      end if;

   end process P_tst_index;

   tst_index_minus1 <= std_logic_vector(unsigned(tst_index) - 1);

   -- ------------------------------------------------------------------------------------------------------
   --!   Test pattern generation
   -- ------------------------------------------------------------------------------------------------------
   I_tst_pat_gen: entity work.dsp generic map (
         g_PORTA_S            => c_DFLD_TSTPT_S + 1   , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_TSTPT_S       , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_DFLD_TSTPT_S       , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_DFLD_TSTPT_S       , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => 0                    , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_DFLD_TSTPT_S - 1   , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => tst_index_minus1     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => tst_slope_coef       , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => tst_itcpt_coef       , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => tst_res              , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs generation
   -- ------------------------------------------------------------------------------------------------------
   P_out : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         test_pattern      <= (others => '0');
         o_tst_pat_end_pat <= '0';
         o_tst_pat_end     <= '1';
         o_tst_pat_end_re  <= '0';
         o_tst_pat_empty   <= '0';

      elsif rising_edge(i_clk) then
         if tst_coef_sel(c_TST_RES_POS) = '1' then
            test_pattern <= tst_res;

         end if;

         if (tst_coef_sel(c_TST_INDMAX_CHK_POS) and i_tsten_ena) = '1' and tst_index_max = std_logic_vector(to_unsigned(0, tst_index_max'length)) then
            o_tst_pat_end_pat <= '1';

         else
            o_tst_pat_end_pat <= tst_region_pos(tst_region_pos'high) and not(tst_region_pos_msb_r) and i_tsten_ena;

         end if;

         o_tst_pat_end        <= loop_nb_minus1(loop_nb_minus1'high) and not(i_tsten_inf);
         o_tst_pat_end_re     <= not(o_tst_pat_end) and loop_nb_minus1(loop_nb_minus1'high) and not(i_tsten_inf);

         if tst_region_pos = std_logic_vector(to_unsigned(c_TST_RG_POS_MAX_VAL, tst_region_pos'length)) and tst_index_max = std_logic_vector(to_unsigned(0, tst_index_max'length)) then
            o_tst_pat_empty   <= tst_coef_sel(c_TST_INDMAX_CHK_POS);

         else
            o_tst_pat_empty   <= '0';

         end if;

      end if;

   end process P_out;

   I_test_pattern_sqm : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_TSTPT_S       , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SQM_DATA_FBK_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => test_pattern         , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => o_test_pattern_sqm     -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)          --! Data stalled on Mean Significant Bit
   );

   I_test_pattern_sqa : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_TSTPT_S       , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SQA_DAC_DATA_S       -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => test_pattern         , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => o_test_pattern_sqa     -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)          --! Data stalled on Mean Significant Bit
   );

   I_test_pattern_sc  : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_TSTPT_S       , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB  -- integer                               --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => test_pattern         , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => o_test_pattern_sc      -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)          --! Data stalled on Mean Significant Bit
   );

end architecture RTL;
