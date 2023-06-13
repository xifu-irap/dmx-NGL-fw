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
--!   @file                   science_data_mgt.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity science_data_mgt is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_ras_data_valid_rs  : in     std_logic                                                            ; --! RAS Data valid, synchronized on System Clock ('0' = No, '1' = Yes)
         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_tst_pat_end        : in     std_logic                                                            ; --! Test pattern end of all patterns ('0' = Inactive, '1' = Active)

         i_test_pattern       : in     std_logic_vector(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0)      ; --! Test pattern
         i_sqm_data_sc_msb    : in     t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science MSB
         i_sqm_data_sc_lsb    : in     t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science LSB
         i_sqm_data_sc_first  : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_last   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_rdy    : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         i_sqm_mem_dump_bsy   : in     std_logic                                                            ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sqm_mem_dump_add   : out    std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                       ; --! SQUID MUX Memory Dump: address
         i_sqm_mem_dump_data  : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --! SQUID MUX Memory Dump: data

         o_aqmde_dmp_tx_end   : out    std_logic                                                            ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)

         o_science_data_ser   : out    std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                   --! Science Data: Serial Data
   );
end entity science_data_mgt;

architecture RTL of science_data_mgt is
constant c_DT_PV              : integer:= 2                                                                 ; --! SQUID MUX Data science previous pipeline number
constant c_DTA_SC_RDY_NPER    : integer:= 3                                                                 ; --! SQUID MUX Data science ready period number from ready for all columns activated

constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Dump counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Dump counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_NB_VAL + 1) + 1                               ; --! Dump counter: size bus (signed)

signal   ras_data_valid_rs_r  : std_logic                                                                   ; --! RAS Data valid register ('0' = No, '1' = Yes)
signal   ras_data_valid_ltc   : std_logic                                                                   ; --! RAS Data valid synchronous latch

signal   sqm_data_sc_msb_pv   : t_slv_arr_tab(0 to c_NB_COL-1)(0 to c_DT_PV-1)(c_SC_DATA_SER_W_S-1 downto 0); --! SQUID MUX Data science MSB previous
signal   sqm_data_sc_lsb_pv   : t_slv_arr_tab(0 to c_NB_COL-1)(0 to c_DT_PV-1)(c_SC_DATA_SER_W_S-1 downto 0); --! SQUID MUX Data science LSB previous

signal   sqm_data_sc_msb_mux  : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID MUX Data science MSB multiplexed
signal   sqm_data_sc_lsb_mux  : t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)                    ; --! SQUID MUX Data science LSB multiplexed

signal   sqm_data_sc_rdy_ena  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready enable ('0' = Not ready, '1' = Ready)
signal   sqm_data_sc_rdy_and  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready "and-ed"
signal   sqm_dta_sc_rdy_all_r : std_logic_vector(c_DTA_SC_RDY_NPER-1 downto 0)                              ; --! SQUID MUX Data science ready for all columns register

signal   sqm_data_sc_sel      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science select ('0' = previous data, '1' = current data)
signal   sqm_data_sc_fst_ena  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science first pixel enable ('0' = No, '1' = Yes)
signal   sqm_data_sc_fst_and  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science first pixel "and-ed"
signal   sqm_data_sc_fst_all  : std_logic                                                                   ; --! SQUID MUX Data science first pixel for all columns
signal   sqm_dta_sc_fst_all_r : std_logic_vector(c_DTA_SC_RDY_NPER-2 downto 0)                              ; --! SQUID MUX Data science first pixel for all columns register
signal   sqm_data_sc_lst_ena  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science last pixel enable ('0' = No, '1' = Yes)
signal   sqm_data_sc_lst_and  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science last pixel "and-ed"
signal   sqm_data_sc_lst_all  : std_logic                                                                   ; --! SQUID MUX Data science last pixel for all columns
signal   sqm_dta_sc_lst_all_r : std_logic                                                                   ; --! SQUID MUX Data science last pixel for all columns register

signal   aqmde_r              : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode register
signal   aqmde_sync           : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode, sync on pixel sequence
signal   tst_pat_end_r        : std_logic                                                                   ; --! Test pattern end of all patterns register
signal   tst_pat_end_sync     : std_logic                                                                   ; --! Test pattern end of all patterns, sync on pixel sequence

signal   dmp_cnt              : std_logic_vector(c_DMP_CNT_S-1 downto 0)                                    ; --! Dump counter
signal   dmp_cnt_msb_r        : std_logic_vector(c_MEM_RD_DATA_NPER downto 0)                               ; --! Dump counter msb register

signal   ctrl_first_pkt       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Control first packet value

signal   science_data_tx_ena  : std_logic                                                                   ; --! Science Data transmit enable
signal   science_data         : t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB)(c_SC_DATA_SER_W_S-1 downto 0)     ; --! Science Data word
signal   ser_bit_cnt          : std_logic_vector(log2_ceil(c_SC_DATA_SER_W_S-1) downto 0)                   ; --! Serial bit counter

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   RAS Data valid synchronous latch
   -- ------------------------------------------------------------------------------------------------------
   P_ras_data_valid_ltc : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ras_data_valid_rs_r  <= '0';
         ras_data_valid_ltc   <= '0';

      elsif rising_edge(i_clk) then
         ras_data_valid_rs_r  <= i_ras_data_valid_rs;

         if (i_ras_data_valid_rs and not(ras_data_valid_rs_r)) = '1' then
            ras_data_valid_ltc   <= '1';

         elsif (aqmde_sync = c_DST_AQMDE_SCIE) and (sqm_dta_sc_fst_all_r(0) and science_data_tx_ena) = '1' then
            ras_data_valid_ltc   <= '0';

         end if;

      end if;

   end process P_ras_data_valid_ltc;

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science previous value
   -- ------------------------------------------------------------------------------------------------------
      P_sqm_data_sc_pv : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_msb_pv(k)   <= (others => (others => '0'));
            sqm_data_sc_lsb_pv(k)   <= (others => (others => '0'));

         elsif rising_edge(i_clk) then
            if i_sqm_data_sc_rdy(k) = '1' then
               sqm_data_sc_msb_pv(k) <= i_sqm_data_sc_msb(k) & sqm_data_sc_msb_pv(k)(0 to c_DT_PV-2);
               sqm_data_sc_lsb_pv(k) <= i_sqm_data_sc_lsb(k) & sqm_data_sc_lsb_pv(k)(0 to c_DT_PV-2);

            end if;

         end if;

      end process P_sqm_data_sc_pv;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science ready
   -- ------------------------------------------------------------------------------------------------------
      P_sqm_data_sc_rdy : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_rdy_ena(k)  <= '0';

         elsif rising_edge(i_clk) then
            if (sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high) or sqm_data_sc_fst_and(sqm_data_sc_fst_and'high)) = '1' then
               sqm_data_sc_rdy_ena(k)  <= '0';

            elsif i_sqm_data_sc_rdy(k) = '1' then
               sqm_data_sc_rdy_ena(k)  <= '1';

            end if;

         end if;

      end process P_sqm_data_sc_rdy;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science first pixel
   -- ------------------------------------------------------------------------------------------------------
      P_sqm_data_sc_fst : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_fst_ena(k)  <= '0';
            sqm_data_sc_sel(k)      <= '1';

         elsif rising_edge(i_clk) then
            if    sqm_data_sc_fst_and(sqm_data_sc_fst_and'high) = '1' then
               sqm_data_sc_fst_ena(k)  <= '0';
               sqm_data_sc_sel(k)      <= i_sqm_data_sc_first(k);

            elsif (i_sqm_data_sc_first(k) and i_sqm_data_sc_rdy(k)) = '1' then
               sqm_data_sc_fst_ena(k)  <= '1';

            end if;

         end if;

      end process P_sqm_data_sc_fst;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science last pixel
   -- ------------------------------------------------------------------------------------------------------
      P_sqm_data_sc_lst : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_lst_ena(k)  <= '0';

         elsif rising_edge(i_clk) then
            if     sqm_data_sc_fst_and(sqm_data_sc_fst_and'high) = '1' then
               sqm_data_sc_lst_ena(k)  <= '0';

            elsif (i_sqm_data_sc_last(k) and i_sqm_data_sc_rdy(k)) = '1' then
               sqm_data_sc_lst_ena(k)  <= '1';

            end if;

         end if;

      end process P_sqm_data_sc_lst;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science multiplexed
   -- ------------------------------------------------------------------------------------------------------
      P_sqm_data_sc_mux : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_msb_mux(k) <= (others => '0');
            sqm_data_sc_lsb_mux(k) <= (others => '0');

         elsif rising_edge(i_clk) then
            if sqm_dta_sc_rdy_all_r(0) = '1' then
               if sqm_data_sc_sel(k) = '0' then
                  sqm_data_sc_msb_mux(k) <= sqm_data_sc_msb_pv(k)(c_DT_PV-1);
                  sqm_data_sc_lsb_mux(k) <= sqm_data_sc_lsb_pv(k)(c_DT_PV-1);

               else
                  sqm_data_sc_msb_mux(k) <= i_sqm_data_sc_msb(k);
                  sqm_data_sc_lsb_mux(k) <= i_sqm_data_sc_lsb(k);

               end if;

            end if;

         end if;

      end process P_sqm_data_sc_mux;

      G_k: if k = 0 generate
         sqm_data_sc_rdy_and(k)  <= sqm_data_sc_rdy_ena(k);
         sqm_data_sc_fst_and(k)  <= sqm_data_sc_fst_ena(k);
         sqm_data_sc_lst_and(k)  <= sqm_data_sc_lst_ena(k);

      else generate
         sqm_data_sc_rdy_and(k)  <= sqm_data_sc_rdy_ena(k) and sqm_data_sc_rdy_and(k-1);
         sqm_data_sc_fst_and(k)  <= sqm_data_sc_fst_ena(k) and sqm_data_sc_fst_and(k-1);
         sqm_data_sc_lst_and(k)  <= sqm_data_sc_lst_ena(k) and sqm_data_sc_lst_and(k-1);

      end generate;

   end generate G_column_mgt;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science signals for all columns
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_dta_sc_all : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_sc_fst_all  <= '0';
         sqm_data_sc_lst_all  <= '0';
         sqm_dta_sc_rdy_all_r <= (others => '0');
         sqm_dta_sc_fst_all_r <= (others => '0');
         sqm_dta_sc_lst_all_r <= '0';

      elsif rising_edge(i_clk) then
         if sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high) = '1' then
            sqm_data_sc_fst_all <= sqm_data_sc_fst_and(sqm_data_sc_fst_and'high);
            sqm_data_sc_lst_all <= sqm_data_sc_lst_and(sqm_data_sc_lst_and'high);

         end if;

         sqm_dta_sc_rdy_all_r <= sqm_dta_sc_rdy_all_r(sqm_dta_sc_rdy_all_r'high-1 downto 0) & sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high);
         sqm_dta_sc_fst_all_r <= sqm_dta_sc_fst_all_r(sqm_dta_sc_fst_all_r'high-1 downto 0) & sqm_data_sc_fst_all;
         sqm_dta_sc_lst_all_r <= sqm_data_sc_lst_all;

      end if;

   end process P_sqm_dta_sc_all;

   -- ------------------------------------------------------------------------------------------------------
   --!   Telemetry mode, synchronized on pixel sequence
   -- ------------------------------------------------------------------------------------------------------
   P_aqmde_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         aqmde_r           <= c_EP_CMD_DEF_AQMDE;
         tst_pat_end_r     <= '1';

         aqmde_sync        <= c_EP_CMD_DEF_AQMDE;
         tst_pat_end_sync  <= '1';

      elsif rising_edge(i_clk) then
         aqmde_r           <= i_aqmde;
         tst_pat_end_r     <= i_tst_pat_end;

         if (sqm_data_sc_fst_and(sqm_data_sc_fst_and'high) and sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high)) = '1' then
            aqmde_sync        <= aqmde_r;
            tst_pat_end_sync  <= tst_pat_end_r;

         end if;

      end if;

   end process P_aqmde_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dump counter
   -- ------------------------------------------------------------------------------------------------------
   P_dmp_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         dmp_cnt_msb_r        <= (others => '1');
         dmp_cnt              <= (others => '1');

         o_aqmde_dmp_tx_end <= '0';

      elsif rising_edge(i_clk) then
         dmp_cnt_msb_r <= dmp_cnt_msb_r(dmp_cnt_msb_r'high-1 downto 0) & dmp_cnt(dmp_cnt'high);

         if aqmde_sync = c_DST_AQMDE_DUMP then

            if (dmp_cnt(dmp_cnt'high) and i_sqm_mem_dump_bsy) = '1' then
               dmp_cnt <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, dmp_cnt'length));

            elsif not(dmp_cnt(dmp_cnt'high)) = '1' and ser_bit_cnt = std_logic_vector(to_unsigned(c_SC_DATA_SER_W_S-2, ser_bit_cnt'length)) then
               dmp_cnt <= std_logic_vector(signed(dmp_cnt) - 1);

            end if;

         end if;

         o_aqmde_dmp_tx_end <= not(dmp_cnt_msb_r(dmp_cnt_msb_r'high)) and dmp_cnt_msb_r(dmp_cnt_msb_r'high-1);

      end if;

   end process P_dmp_cnt;

   o_sqm_mem_dump_add   <= dmp_cnt(o_sqm_mem_dump_add'high downto 0);

   -- ------------------------------------------------------------------------------------------------------
   --!   Control packet value
   -- ------------------------------------------------------------------------------------------------------
   ctrl_first_pkt <= c_SC_CTRL_RAS_VLD when (aqmde_sync = c_DST_AQMDE_SCIE and ras_data_valid_ltc = '1') else
                     c_SC_CTRL_SC_DTA  when aqmde_sync = c_DST_AQMDE_SCIE else
                     c_SC_CTRL_ERRS    when aqmde_sync = c_DST_AQMDE_ERRS else
                     c_SC_CTRL_ADC_DMP when aqmde_sync = c_DST_AQMDE_DUMP else
                     c_SC_CTRL_TST_PAT when aqmde_sync = c_DST_AQMDE_TEST else
                     c_SC_CTRL_IDLE;

   P_ctrl_pkt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         science_data(science_data'high) <= c_SC_CTRL_IDLE;

      elsif rising_edge(i_clk) then
         if aqmde_sync = c_DST_AQMDE_IDLE or (aqmde_sync = c_DST_AQMDE_TEST and tst_pat_end_sync = '1') then
            science_data(science_data'high) <= c_SC_CTRL_IDLE;

         elsif  ((aqmde_sync = c_DST_AQMDE_DUMP) and (dmp_cnt_msb_r(dmp_cnt_msb_r'high) and i_sqm_mem_dump_bsy) = '1') or
               (((aqmde_sync = c_DST_AQMDE_SCIE) or  (aqmde_sync = c_DST_AQMDE_ERRS) or
                ((aqmde_sync = c_DST_AQMDE_TEST) and (tst_pat_end_sync = '0')))      and sqm_dta_sc_fst_all_r(0) = '1') then
            science_data(science_data'high) <= ctrl_first_pkt;

         elsif  ((aqmde_sync = c_DST_AQMDE_DUMP) and dmp_cnt = std_logic_vector(to_unsigned(0, dmp_cnt'length))) or
               (((aqmde_sync = c_DST_AQMDE_SCIE) or  (aqmde_sync = c_DST_AQMDE_ERRS) or
                ((aqmde_sync = c_DST_AQMDE_TEST) and (tst_pat_end_sync = '0')))      and sqm_dta_sc_lst_all_r = '1') then
            science_data(science_data'high) <= c_SC_CTRL_EOD;

         else
            science_data(science_data'high) <= c_SC_CTRL_DTA_W;

         end if;

      end if;

   end process P_ctrl_pkt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data management
   --    @Req : DRE-DMX-FW-REQ-0460
   --    @Req : DRE-DMX-FW-REQ-0580
   -- ------------------------------------------------------------------------------------------------------
   G_science_data : for k in 0 to c_NB_COL-1 generate
   begin

      P_science_data : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            science_data(2*k+1)  <= (others => '0');
            science_data(2*k)    <= (others => '0');

         elsif rising_edge(i_clk) then
            if    aqmde_sync = c_DST_AQMDE_DUMP then
               science_data(2*k+1)  <= std_logic_vector(resize(unsigned(i_sqm_mem_dump_data(k)(c_SQM_ADC_DATA_S+1 downto c_SC_DATA_SER_W_S)), c_SC_DATA_SER_W_S));
               science_data(2*k)    <= i_sqm_mem_dump_data(k)(c_SC_DATA_SER_W_S-1 downto 0);

            elsif (aqmde_sync = c_DST_AQMDE_SCIE) or (aqmde_sync = c_DST_AQMDE_ERRS) then
               science_data(2*k+1)  <= sqm_data_sc_msb_mux(k);
               science_data(2*k)    <= sqm_data_sc_lsb_mux(k);

            elsif aqmde_sync = c_DST_AQMDE_TEST and (not(tst_pat_end_sync) and sqm_dta_sc_fst_all_r(0)) = '1' then
               science_data(2*k+1)  <= i_test_pattern(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
               science_data(2*k)    <= i_test_pattern(  c_SC_DATA_SER_W_S-1 downto                 0);

            elsif aqmde_sync = c_DST_AQMDE_IDLE or (aqmde_sync = c_DST_AQMDE_TEST and tst_pat_end_sync = '1') then
               science_data(2*k+1)  <= c_SC_DATA_IDLE_VAL(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
               science_data(2*k)    <= c_SC_DATA_IDLE_VAL(  c_SC_DATA_SER_W_S-1 downto                 0);

            end if;

         end if;

      end process P_science_data;

   end generate G_science_data;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data transmit enable
   -- ------------------------------------------------------------------------------------------------------
   P_sc_data_tx_ena : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         science_data_tx_ena <= '0';

      elsif rising_edge(i_clk) then
         if    aqmde_sync = c_DST_AQMDE_DUMP then
            science_data_tx_ena <= not(dmp_cnt_msb_r(dmp_cnt_msb_r'high-1));

         elsif (aqmde_sync = c_DST_AQMDE_SCIE) or (aqmde_sync = c_DST_AQMDE_ERRS) or (aqmde_sync = c_DST_AQMDE_TEST) then
            science_data_tx_ena <= sqm_dta_sc_rdy_all_r(sqm_dta_sc_rdy_all_r'high);

         else
            science_data_tx_ena <= '0';

         end if;

      end if;

   end process P_sc_data_tx_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Transmit
   --    @Req : DRE-DMX-FW-REQ-0590
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_tx: entity work.science_data_tx port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_science_data_tx_ena=> science_data_tx_ena  , -- in     std_logic                                 ; --! Science Data transmit enable
         i_science_data       => science_data         , -- in     t_slv_arr c_NB_COL*c_SC_DATA_SER_NB       ; --! Science Data word
         o_ser_bit_cnt        => ser_bit_cnt          , -- out    slv log2_ceil(c_SC_DATA_SER_W_S-1)        ; --! Serial bit counter
         o_science_data_ser   => o_science_data_ser     -- out    slv       c_NB_COL*c_SC_DATA_SER_NB         --! Science Data: Serial Data
   );

end architecture RTL;
