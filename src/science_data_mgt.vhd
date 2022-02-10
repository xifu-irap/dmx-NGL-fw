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
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity science_data_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_tm_mode            : in     t_rg_tm_mode(        0 to c_NB_COL-1)                                ; --! Telemetry mode

         i_sq1_data_sc_msb    : in     t_sc_data_w(         0 to c_NB_COL-1)                                ; --! SQUID1 Data science MSB
         i_sq1_data_sc_lsb    : in     t_sc_data_w(         0 to c_NB_COL-1)                                ; --! SQUID1 Data science LSB
         i_sq1_data_sc_first  : in     std_logic_vector(         c_NB_COL-1 downto 0)                       ; --! SQUID1 Data science first pixel ('0' = No, '1' = Yes)
         i_sq1_data_sc_last   : in     std_logic_vector(         c_NB_COL-1 downto 0)                       ; --! SQUID1 Data science last pixel ('0' = No, '1' = Yes)
         i_sq1_data_sc_rdy    : in     std_logic_vector(         c_NB_COL-1 downto 0)                       ; --! SQUID1 Data science ready ('0' = Not ready, '1' = Ready)

         i_sq1_mem_dump_bsy   : in     std_logic_vector(         c_NB_COL-1 downto 0)                       ; --! SQUID1 Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sq1_mem_dump_add   : out    std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                       ; --! SQUID1 Memory Dump: address
         o_sq1_mem_dump_cs    : out    std_logic                                                            ; --! SQUID1 Memory Dump: chip select ('0' = Inactive, '1' = Active)
         i_sq1_mem_dump_data  : in     t_sq1_mem_dump_dta_v(0 to c_NB_COL-1)                                ; --! SQUID1 Memory Dump: data

         o_science_data_ser   : out    std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                   --! Science Data – Serial Data
   );
end entity science_data_mgt;

architecture RTL of science_data_mgt is
constant c_LD_DMP_CNT_NB_VAL  : integer:= c_SC_DATA_SER_W_S+2                                               ; --! Pre-load ADC words in dump mode counter: number of value
constant c_LD_DMP_CNT_MAX_VAL : integer:= c_LD_DMP_CNT_NB_VAL-1                                             ; --! Pre-load ADC words in dump mode counter: maximal value
constant c_LD_DMP_CNT_S       : integer:= log2_ceil(c_LD_DMP_CNT_MAX_VAL + 1) + 1                           ; --! Pre-load ADC words in dump mode counter: size bus (signed)

constant c_SC_W_CNT_NB_VAL    : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Science data word for dump counter: number of value
constant c_SC_W_CNT_MAX_VAL   : integer:= c_SC_W_CNT_NB_VAL-1                                               ; --! Science data word for dump counter: maximal value
constant c_SC_W_CNT_S         : integer:= log2_ceil(c_SC_W_CNT_MAX_VAL + 1) + 1                             ; --! Science data word for dump counter: size bus (signed)

signal   adc_dump_ena         : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! ADC dump enable ('0' = Inactive, '1' = Active)
signal   sq1_data_sc_fst_mm   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science first pixel memorized
signal   sq1_data_sc_lst_mm   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science last pixel memorized
signal   sq1_data_sc_rdy_mm   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science ready memorized

signal   tm_mode_nrm_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Normal" compared
signal   tm_mode_tst_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Test pattern" compared
signal   ctrl_adc_fst_pkt_cmp : t_sc_data_w(         0 to c_NB_COL-1)                                       ; --! Control adc first packet, status "Dump" compared
signal   adc_dump_data_sel    : t_sq1_mem_dump_dta_v(0 to c_NB_COL)                                         ; --! ADC dump data word select

signal   tm_mode_nrm_or       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Normal" column select "or-ed"
signal   tm_mode_tst_or       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Test pattern" column select "or-ed"
signal   sq1_mem_dump_bsy_or  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Memory Dump, data busy "or-ed"
signal   adc_dump_ena_or      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! ADC dump enable "or-ed"
signal   ctrl_adc_fst_pkt_or  : t_sc_data_w(0 to c_NB_COL-1)                                                ; --! Control adc first packet, status "Dump" column select "or-ed"
signal   adc_dump_data_or     : t_sq1_mem_dump_dta_v(0 to c_NB_COL-1)                                       ; --! ADC dump data word "or-ed"
signal   sq1_data_sc_fst_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science first pixel memorized "or-ed"
signal   sq1_data_sc_lst_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science last pixel memorized "or-ed"
signal   sq1_data_sc_rdy_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 Data science ready memorized "or-ed"
signal   sq1_data_sc_rdy_all  : std_logic                                                                   ; --! SQUID1 Data science ready for all columns

signal   ld_dmp_cnt           : std_logic_vector(c_LD_DMP_CNT_S-1 downto 0)                                 ; --! Pre-load ADC words in dump mode counter
signal   sc_w_cnt             : std_logic_vector(c_SC_W_CNT_S  -1 downto 0)                                 ; --! Science data word for dump counter
signal   sc_w_cnt_msb_r       : std_logic_vector(c_LD_DMP_CNT_NB_VAL-1 downto 0)                            ; --! Science data word for dump counter msb register

signal   ctrl_first_pkt       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Control first packet value
signal   ctrl_pkt             : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Control packet value

signal   tm_test_pat_data     : std_logic_vector(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0)             ; --! Telemetry test pattern data

signal   sc_data_nrm_tst_ena  : std_logic                                                                   ; --! Science Data transmit in normal test pattern mode enable
signal   science_data_tx_ena  : std_logic                                                                   ; --! Science Data transmit enable
signal   science_data         : t_sc_data_w(0 to c_NB_COL*c_SC_DATA_SER_NB)                                 ; --! Science Data word
signal   ser_bit_cnt          : std_logic_vector(log2_ceil(c_SC_DATA_SER_W_S-1) downto 0)                   ; --! Serial bit counter

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC dump enable
   -- ------------------------------------------------------------------------------------------------------
   G_adc_dump_ena : for k in 0 to c_NB_COL-1 generate
   begin

      P_adc_dump_ena : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            adc_dump_ena(k) <= '0';

         elsif rising_edge(i_clk) then
            if i_sq1_mem_dump_bsy(k) = '1' then
               adc_dump_ena(k) <= '1';

            elsif sc_w_cnt_msb_r(0) = '1' then
               adc_dump_ena(k) <= '0';

            end if;
         end if;

      end process P_adc_dump_ena;

   end generate G_adc_dump_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID1 Data science signals memorized
   -- ------------------------------------------------------------------------------------------------------
   G_sq1_data_sc_mm : for k in 0 to c_NB_COL-1 generate
   begin

      P_sq1_data_sc_mm : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sq1_data_sc_fst_mm(k) <= '0';
            sq1_data_sc_lst_mm(k) <= '0';
            sq1_data_sc_rdy_mm(k) <= '0';

         elsif rising_edge(i_clk) then
            if (i_sq1_data_sc_first(k) and i_sq1_data_sc_rdy(k)) = '1' then
               sq1_data_sc_fst_mm(k) <= '1';

            elsif sq1_data_sc_fst_or(sq1_data_sc_fst_or'high) = '1' then
               sq1_data_sc_fst_mm(k) <= '0';

            end if;

            if (i_sq1_data_sc_last(k) and i_sq1_data_sc_rdy(k)) = '1' then
               sq1_data_sc_lst_mm(k) <= '1';

            elsif sq1_data_sc_lst_or(sq1_data_sc_lst_or'high) = '1' then
               sq1_data_sc_lst_mm(k) <= '0';

            end if;

            if i_sq1_data_sc_rdy(k) = '1' then
               sq1_data_sc_rdy_mm(k) <= '1';

            elsif sq1_data_sc_rdy_or(sq1_data_sc_rdy_or'high) = '1' then
               sq1_data_sc_rdy_mm(k) <= '0';

            end if;

         end if;

      end process P_sq1_data_sc_mm;

   end generate G_sq1_data_sc_mm;

   -- ------------------------------------------------------------------------------------------------------
   --!   Compare and "or-ed" column signals
   -- ------------------------------------------------------------------------------------------------------
   tm_mode_nrm_or(0)       <= tm_mode_nrm_cmp(0);
   tm_mode_tst_or(0)       <= tm_mode_tst_cmp(0);
   sq1_mem_dump_bsy_or(0)  <= i_sq1_mem_dump_bsy(0);
   adc_dump_ena_or(0)      <= adc_dump_ena(0);

   ctrl_adc_fst_pkt_or(0)  <= ctrl_adc_fst_pkt_cmp(0);
   adc_dump_data_or(0)     <= adc_dump_data_sel(0);
   sq1_data_sc_fst_or(0)   <= sq1_data_sc_fst_mm(0);
   sq1_data_sc_lst_or(0)   <= sq1_data_sc_lst_mm(0);
   sq1_data_sc_rdy_or(0)   <= sq1_data_sc_rdy_mm(0);

   G_sig_cmp_or : for k in 0 to c_NB_COL-1 generate
   begin

      tm_mode_nrm_cmp(k)      <= '1'                    when i_tm_mode(k)    = c_DST_TM_MODE_NORM else '0';
      tm_mode_tst_cmp(k)      <= '1'                    when i_tm_mode(k)    = c_DST_TM_MODE_TEST else '0';

      ctrl_adc_fst_pkt_cmp(k) <= c_SC_CTRL_ADC_DMP(k)   when i_tm_mode(k)    = c_DST_TM_MODE_DUMP else (others => '0');
      adc_dump_data_sel(k)    <= i_sq1_mem_dump_data(k) when adc_dump_ena(k) = '1'                else (others => '0');

      G_sig_or: if k /= 0 generate
         tm_mode_nrm_or(k)       <= tm_mode_nrm_cmp(k)      or tm_mode_nrm_or(k-1);
         tm_mode_tst_or(k)       <= tm_mode_tst_cmp(k)      or tm_mode_tst_or(k-1);
         sq1_mem_dump_bsy_or(k)  <= i_sq1_mem_dump_bsy(k)   or sq1_mem_dump_bsy_or(k-1);
         adc_dump_ena_or(k)      <= adc_dump_ena(k)         or adc_dump_ena_or(k-1);
         sq1_data_sc_fst_or(k)   <= sq1_data_sc_fst_mm(k)   or sq1_data_sc_fst_or(k-1);
         sq1_data_sc_lst_or(k)   <= sq1_data_sc_lst_mm(k)   or sq1_data_sc_lst_or(k-1);
         sq1_data_sc_rdy_or(k)   <= sq1_data_sc_rdy_mm(k)   or sq1_data_sc_rdy_or(k-1);

         ctrl_adc_fst_pkt_or(k)  <= ctrl_adc_fst_pkt_cmp(k) or ctrl_adc_fst_pkt_or(k-1);
         adc_dump_data_or(k)     <= adc_dump_data_sel(k)    or adc_dump_data_or(k-1);

      end generate G_sig_or;

   end generate G_sig_cmp_or;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pre-load ADC words in dump mode counter
   -- ------------------------------------------------------------------------------------------------------
   P_ld_dmp_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ld_dmp_cnt <= (others => '1');

      elsif rising_edge(i_clk) then
         if (sc_w_cnt(sc_w_cnt'high) and ser_bit_cnt(ser_bit_cnt'high) and ld_dmp_cnt(ld_dmp_cnt'high) and sq1_mem_dump_bsy_or(sq1_mem_dump_bsy_or'high)) = '1' then
            ld_dmp_cnt <= std_logic_vector(to_unsigned(c_LD_DMP_CNT_MAX_VAL, ld_dmp_cnt'length));

         elsif ld_dmp_cnt(ld_dmp_cnt'high) = '0' then
            ld_dmp_cnt <= std_logic_vector(signed(ld_dmp_cnt) - 1);

         end if;
      end if;

   end process P_ld_dmp_cnt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data word for dump counter
   -- ------------------------------------------------------------------------------------------------------
   P_sc_w_cnt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sc_w_cnt <= (others => '1');

      elsif rising_edge(i_clk) then
         if (sc_w_cnt(sc_w_cnt'high) and ser_bit_cnt(ser_bit_cnt'high) and ld_dmp_cnt(ld_dmp_cnt'high) and sq1_mem_dump_bsy_or(sq1_mem_dump_bsy_or'high)) = '1' then
               sc_w_cnt <= std_logic_vector(to_unsigned(c_SC_W_CNT_MAX_VAL, sc_w_cnt'length));

         elsif (not(sc_w_cnt(sc_w_cnt'high)) and adc_dump_ena_or(adc_dump_ena_or'high) and (
               (not(ld_dmp_cnt(ld_dmp_cnt'high)) and not(ld_dmp_cnt(0))) or
               (    ld_dmp_cnt(ld_dmp_cnt'high)  and not(ser_bit_cnt(0))) )) = '1' then
            sc_w_cnt <= std_logic_vector(signed(sc_w_cnt) - 1);

         end if;
      end if;

   end process P_sc_w_cnt;

   o_sq1_mem_dump_add   <= sc_w_cnt(o_sq1_mem_dump_add'high downto 0);
   o_sq1_mem_dump_cs    <= not(sc_w_cnt(sc_w_cnt'high));

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
        sc_w_cnt_msb_r        <= (others => '1');
        sc_data_nrm_tst_ena   <= '0';
        sq1_data_sc_rdy_all   <= '0';

      elsif rising_edge(i_clk) then
         sc_w_cnt_msb_r       <= sc_w_cnt_msb_r(sc_w_cnt_msb_r'high-1 downto 0) & sc_w_cnt(sc_w_cnt'high);

         if sq1_data_sc_lst_or(sq1_data_sc_lst_or'high) = '1' then
            sc_data_nrm_tst_ena <= tm_mode_nrm_or(tm_mode_nrm_or'high) or tm_mode_tst_or(tm_mode_tst_or'high);

         end if;

         sq1_data_sc_rdy_all  <= sq1_data_sc_rdy_or(sq1_data_sc_rdy_or'high) and sc_data_nrm_tst_ena;

      end if;

   end process P_reg;

   science_data_tx_ena  <= not(sc_w_cnt_msb_r(sc_w_cnt_msb_r'high)) or sq1_data_sc_rdy_all;

   -- ------------------------------------------------------------------------------------------------------
   --!   Control first packet value
   -- ------------------------------------------------------------------------------------------------------
   ctrl_first_pkt <= ctrl_adc_fst_pkt_or(ctrl_adc_fst_pkt_or'high) when adc_dump_ena_or(adc_dump_ena_or'high) = '1' else
                     c_SC_CTRL_SC_DTA                              when tm_mode_nrm_or(tm_mode_nrm_or'high) = '1' else
                     c_SC_CTRL_TST_PAT                             when tm_mode_tst_or(tm_mode_tst_or'high) = '1' else
                     (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Control packet value
   -- ------------------------------------------------------------------------------------------------------
   P_ctrl_pkt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         ctrl_pkt <= (others => '0');

      elsif rising_edge(i_clk) then
         if ((    adc_dump_ena_or(adc_dump_ena_or'high)  and not(science_data_tx_ena)) or
             (not(adc_dump_ena_or(adc_dump_ena_or'high)) and sq1_data_sc_fst_or(sq1_data_sc_fst_or'high))) = '1' then
            ctrl_pkt <= ctrl_first_pkt;

         elsif adc_dump_ena_or(adc_dump_ena_or'high) = '1' and sc_w_cnt(sc_w_cnt'high) = '1' then
            ctrl_pkt <= c_SC_CTRL_EOD;

         elsif (not(adc_dump_ena_or(adc_dump_ena_or'high)) and sq1_data_sc_lst_or(sq1_data_sc_lst_or'high)) = '1' then
            ctrl_pkt <= c_SC_CTRL_EOD;

         else
            ctrl_pkt <= c_SC_CTRL_DTA_W;

         end if;

      end if;

   end process P_ctrl_pkt;

   science_data(science_data'high) <= ctrl_pkt;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data management
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
            if adc_dump_ena_or(adc_dump_ena_or'high) = '1' then
               if ld_dmp_cnt   = std_logic_vector(to_signed(c_SC_DATA_SER_W_S-2*k-2, ld_dmp_cnt'length)) or
                  ser_bit_cnt  = std_logic_vector(to_signed(c_SC_DATA_SER_W_S-2*k-2, ser_bit_cnt'length)) then
                  science_data(2*k+1)  <= std_logic_vector(resize(unsigned(adc_dump_data_or(adc_dump_data_or'high)(c_SQ1_ADC_DATA_S+1 downto c_SC_DATA_SER_W_S)), c_SC_DATA_SER_W_S));
                  science_data(2*k)    <= adc_dump_data_or(adc_dump_data_or'high)(c_SC_DATA_SER_W_S-1 downto 0);

               end if;

            elsif i_tm_mode(k) = c_DST_TM_MODE_NORM then
               science_data(2*k+1)  <= i_sq1_data_sc_msb(k);
               science_data(2*k)    <= i_sq1_data_sc_lsb(k);

            elsif i_tm_mode(k) = c_DST_TM_MODE_TEST then
               science_data(2*k+1)  <= tm_test_pat_data(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
               science_data(2*k)    <= tm_test_pat_data(  c_SC_DATA_SER_W_S-1 downto                 0);

            elsif i_tm_mode(k) = c_DST_TM_MODE_IDLE then
               science_data(2*k+1)  <= c_SC_DATA_IDLE_VAL(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
               science_data(2*k)    <= c_SC_DATA_IDLE_VAL(  c_SC_DATA_SER_W_S-1 downto                 0);

            end if;
         end if;

      end process P_science_data;

   end generate G_science_data;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Transmit
   --    @Req : DRE-DMX-FW-REQ-0590
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_tx: entity work.science_data_tx port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_science_data_tx_ena=> science_data_tx_ena  , -- in     std_logic                                 ; --! Science Data transmit enable
         i_science_data       => science_data         , -- in     t_sc_data_w c_NB_COL*c_SC_DATA_SER_NB     ; --! Science Data word
         o_ser_bit_cnt        => ser_bit_cnt          , -- out    slv log2_ceil(c_SC_DATA_SER_W_S-1)        ; --! Serial bit counter
         o_science_data_ser   => o_science_data_ser     -- out    slv         c_NB_COL*c_SC_DATA_SER_NB       --! Science Data – Serial Data
   );

   --TODO
   tm_test_pat_data <= (others => '1');

end architecture rtl;