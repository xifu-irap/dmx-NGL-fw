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
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity science_data_mgt is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_re            : in     std_logic                                                            ; --! Pixel sequence synchronization, rising edge
         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode

         i_sqm_data_sc_msb    : in     t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science MSB
         i_sqm_data_sc_lsb    : in     t_slv_arr(0 to c_NB_COL-1)(c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science LSB
         i_sqm_data_sc_first  : in     std_logic                                                            ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_last   : in     std_logic                                                            ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         i_sqm_data_sc_rdy    : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         i_sqm_mem_dump_bsy   : in     std_logic                                                            ; --! SQUID MUX Memory Dump: data busy ('0' = no data dump, '1' = data dump in progress)
         o_sqm_mem_dump_add   : out    std_logic_vector( c_MEM_DUMP_ADD_S-1 downto 0)                       ; --! SQUID MUX Memory Dump: address
         i_sqm_mem_dump_data  : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --! SQUID MUX Memory Dump: data

         o_aqmde_dmp_tx_end   : out    std_logic                                                            ; --! Telemetry mode, dump transmit end ('0' = Inactive, '1' = Active)
         o_aqmde_tst_tx_end   : out    std_logic                                                            ; --! Telemetry mode, test pattern transmit end ('0' = Inactive, '1' = Active)

         o_science_data_ser   : out    std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB downto 0)                   --! Science Data: Serial Data
   );
end entity science_data_mgt;

architecture RTL of science_data_mgt is
constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Dump counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Dump counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_NB_VAL + 1) + 1                               ; --! Dump counter: size bus (signed)

signal   sqm_data_sc_fst_dct  : std_logic                                                                   ; --! SQUID MUX Data science first pixel detected ('0' = No, '1' = Yes)
signal   sqm_data_sc_rdy_ena  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready enable ('0' = No, '1' = Yes)
signal   sqm_data_sc_rdy_and  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID MUX Data science ready "and-ed"
signal   sqm_dta_sc_rdy_and_r : std_logic                                                                   ; --! SQUID MUX Data science ready "and-ed" MSB register

signal   aqmde_idle_sync      : std_logic                                                                   ; --! Telemetry mode "Idle", sync on pixel sequence ('0' = Inactive, '1' = Active)
signal   aqmde_scie_sync      : std_logic                                                                   ; --! Telemetry mode "Science", sync on pixel sequence ('0' = Inactive, '1' = Active)
signal   aqmde_errs_sync      : std_logic                                                                   ; --! Telemetry mode "Error Signal", sync on pixel sequence ('0' = Inactive, '1' = Active)
signal   aqmde_dump_sync      : std_logic                                                                   ; --! Telemetry mode "Dump", sync on pixel sequence ('0' = Inactive, '1' = Active)
signal   aqmde_test_sync      : std_logic                                                                   ; --! Telemetry mode "Test Pattern", sync on pixel sequence ('0' = Inactive, '1' = Active)
signal   dmp_cnt              : std_logic_vector(c_DMP_CNT_S-1 downto 0)                                    ; --! Dump counter
signal   dmp_cnt_msb_r        : std_logic_vector(c_MEM_RD_DATA_NPER downto 0)                               ; --! Dump counter msb register

signal   ctrl_first_pkt       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Control first packet value

signal   acq_test_pat_data    : std_logic_vector(c_SC_DATA_SER_W_S*c_SC_DATA_SER_NB-1 downto 0)             ; --! Data acquisition test pattern data

signal   science_data_tx_ena  : std_logic                                                                   ; --! Science Data transmit enable
signal   science_data         : t_slv_arr(0 to c_NB_COL*c_SC_DATA_SER_NB)(c_SC_DATA_SER_W_S-1 downto 0)     ; --! Science Data word
signal   ser_bit_cnt          : std_logic_vector(log2_ceil(c_SC_DATA_SER_W_S-1) downto 0)                   ; --! Serial bit counter

--TODO
signal   test_cnt             : std_logic_vector(2 downto 0)                                                ; --! test counter

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science ready signals
   -- ------------------------------------------------------------------------------------------------------
   sqm_data_sc_rdy_and(0) <= sqm_data_sc_rdy_ena(0);

   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin

      P_sqm_dta_sc_rdy_ena : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            sqm_data_sc_rdy_ena(k) <= '0';

         elsif rising_edge(i_clk) then
            if i_sqm_data_sc_rdy(k) = '1' then
               sqm_data_sc_rdy_ena(k) <= '1';

            elsif sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high) = '1' then
               sqm_data_sc_rdy_ena(k) <= '0';

            end if;

         end if;

      end process P_sqm_dta_sc_rdy_ena;

      G_dta_sc_rdy_and_0: if k /= 0 generate
         sqm_data_sc_rdy_and(k) <= sqm_data_sc_rdy_ena(k) and sqm_data_sc_rdy_and(k-1);

      end generate G_dta_sc_rdy_and_0;

   end generate G_column_mgt;

   P_dta_sc_rdy_and_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_dta_sc_rdy_and_r <= '0';

      elsif rising_edge(i_clk) then
         sqm_dta_sc_rdy_and_r <= sqm_data_sc_rdy_and(sqm_data_sc_rdy_and'high);

      end if;

   end process P_dta_sc_rdy_and_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Telemetry mode, synchronized on pixel sequence
   -- ------------------------------------------------------------------------------------------------------
   P_aqmde_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         aqmde_idle_sync <= '0';
         aqmde_scie_sync <= '0';
         aqmde_errs_sync <= '0';
         aqmde_dump_sync <= '0';
         aqmde_test_sync <= '0';

      elsif rising_edge(i_clk) then
         if i_sync_re = '1' then
            if i_aqmde = c_DST_AQMDE_IDLE then
               aqmde_idle_sync <= '1';

            else
               aqmde_idle_sync <= '0';

            end if;

            if i_aqmde = c_DST_AQMDE_SCIE then
               aqmde_scie_sync <= '1';

            else
               aqmde_scie_sync <= '0';

            end if;

            if i_aqmde = c_DST_AQMDE_ERRS then
               aqmde_errs_sync <= '1';

            else
               aqmde_errs_sync <= '0';

            end if;

            if i_aqmde = c_DST_AQMDE_DUMP then
               aqmde_dump_sync <= '1';

            else
               aqmde_dump_sync <= '0';

            end if;

            if i_aqmde = c_DST_AQMDE_TEST then
               aqmde_test_sync <= '1';

            else
               aqmde_test_sync <= '0';

            end if;

         end if;

      end if;

   end process P_aqmde_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science first pixel detected
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_dta_sc_fst_dct : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_sc_fst_dct <= '0';

      elsif rising_edge(i_clk) then
         if i_sqm_data_sc_first = '1' then
            sqm_data_sc_fst_dct <= aqmde_scie_sync;

         end if;

      end if;

   end process P_sqm_dta_sc_fst_dct;

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

         if aqmde_dump_sync = '1' then

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
   --!   Control first packet value
   -- ------------------------------------------------------------------------------------------------------
   ctrl_first_pkt <= c_SC_CTRL_ADC_DMP when aqmde_dump_sync = '1' else
                     c_SC_CTRL_SC_DTA  when aqmde_scie_sync = '1' else
                     c_SC_CTRL_TST_PAT when aqmde_test_sync = '1' else
                     c_SC_CTRL_IDLE;

   -- ------------------------------------------------------------------------------------------------------
   --!   Control packet value
   -- ------------------------------------------------------------------------------------------------------
   P_ctrl_pkt : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         science_data(science_data'high) <= c_SC_CTRL_IDLE;

      elsif rising_edge(i_clk) then
         if aqmde_idle_sync = '1' then
            science_data(science_data'high) <= c_SC_CTRL_IDLE;

         elsif ((aqmde_dump_sync and dmp_cnt_msb_r(dmp_cnt_msb_r'high) and i_sqm_mem_dump_bsy) or
                (aqmde_scie_sync and i_sqm_data_sc_first)) = '1' then
            science_data(science_data'high) <= ctrl_first_pkt;

         elsif (aqmde_dump_sync = '1' and dmp_cnt = std_logic_vector(to_unsigned(0, dmp_cnt'length))) or
               (aqmde_scie_sync and i_sqm_data_sc_last) = '1'   then
            science_data(science_data'high) <= c_SC_CTRL_EOD;

         else
            science_data(science_data'high) <= c_SC_CTRL_DTA_W;

         end if;

      end if;

   end process P_ctrl_pkt;

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
            if    aqmde_dump_sync = '1' then
               science_data(2*k+1)  <= std_logic_vector(resize(unsigned(i_sqm_mem_dump_data(k)(c_SQM_ADC_DATA_S+1 downto c_SC_DATA_SER_W_S)), c_SC_DATA_SER_W_S));
               science_data(2*k)    <= i_sqm_mem_dump_data(k)(c_SC_DATA_SER_W_S-1 downto 0);

            elsif aqmde_scie_sync = '1' then
               science_data(2*k+1)  <= i_sqm_data_sc_msb(k);
               science_data(2*k)    <= i_sqm_data_sc_lsb(k);

            elsif aqmde_test_sync = '1' then
               science_data(2*k+1)  <= acq_test_pat_data(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
               science_data(2*k)    <= acq_test_pat_data(  c_SC_DATA_SER_W_S-1 downto                 0);

            else
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
         if    aqmde_dump_sync = '1' then
            science_data_tx_ena <= not(dmp_cnt_msb_r(dmp_cnt_msb_r'high-1));

         elsif aqmde_scie_sync = '1' then
            science_data_tx_ena <= (sqm_dta_sc_rdy_and_r and sqm_data_sc_fst_dct);

         else
            science_data_tx_ena <= '0';

         end if;

      end if;

   end process P_sc_data_tx_ena;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data Transmit
   --    @Req : DRE-DMX-FW-REQ-0590
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_tx: entity work.science_data_tx port map
   (     i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! System Clock

         i_science_data_tx_ena=> science_data_tx_ena  , -- in     std_logic                                 ; --! Science Data transmit enable
         i_science_data       => science_data         , -- in     t_slv_arr c_NB_COL*c_SC_DATA_SER_NB       ; --! Science Data word
         o_ser_bit_cnt        => ser_bit_cnt          , -- out    slv log2_ceil(c_SC_DATA_SER_W_S-1)        ; --! Serial bit counter
         o_science_data_ser   => o_science_data_ser     -- out    slv         c_NB_COL*c_SC_DATA_SER_NB       --! Science Data: Serial Data
   );

   --TODO
   acq_test_pat_data <= (others => '1');

   P_todo : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         test_cnt           <= (others => '1');
         o_aqmde_tst_tx_end <= '0';

      elsif rising_edge(i_clk) then
         if (aqmde_test_sync and i_sync_re) = '1' then

            if test_cnt(test_cnt'high) = '1' then
               test_cnt <= std_logic_vector(to_unsigned(3 , test_cnt'length));

            else
               test_cnt <= std_logic_vector(signed(test_cnt) - 1);

            end if;

            o_aqmde_tst_tx_end <= test_cnt(test_cnt'high);

         end if;

      end if;

   end process P_todo;

end architecture rtl;