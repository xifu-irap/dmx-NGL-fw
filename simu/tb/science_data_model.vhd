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
--!   @file                   science_data_rx.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Science data model
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_mess.all;

library std;
use std.textio.all;

entity science_data_model is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     i_arst_n             : in     std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_sq1_adc_acq    : in     std_logic                                                            ; --! SQUID1 ADC acquisition Clock
         i_clk_science        : in     std_logic                                                            ; --! Science Clock

         i_science_ctrl_01    : in     std_logic                                                            ; --! Science Data – Control channel 0/1
         i_science_ctrl_23    : in     std_logic                                                            ; --! Science Data – Control channel 2/3
         i_c0_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 0 – Serial Data
         i_c1_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 1 – Serial Data
         i_c2_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 2 – Serial Data
         i_c3_science_data    : in     std_logic_vector(c_SC_DATA_SER_NB-1 downto 0)                        ; --! Science Data, col. 3 – Serial Data

         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)
         i_tm_mode            : in     t_rg_tm_mode(0 to c_NB_COL-1)                                        ; --! Telemetry mode

         i_sq1_adc_data       : in     t_sq1_adc_data_v(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC - Data buses
         i_sq1_adc_oor        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC - Out of range (‘0’ = No, ‘1’ = under/over range)

         o_sc_pkt_type        : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science packet type
         o_sc_pkt_err         : out    std_logic                                                              --! Science packet error ('0' = No error, '1' = Error)
   );
end entity science_data_model;

architecture RTL of science_data_model is
constant c_DMP_CNT_NB_VAL     : integer:= c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC                ; --! Memory Dump, ADC acquisition counter: number of value
constant c_DMP_CNT_MAX_VAL    : integer:= c_DMP_CNT_NB_VAL-1                                                ; --! Memory Dump, ADC acquisition counter: maximal value
constant c_DMP_CNT_S          : integer:= log2_ceil(c_DMP_CNT_MAX_VAL + 1) + 1                              ; --! Memory Dump, ADC acquisition counter: size bus (signed)

type     t_mem_dump             is array (2**(c_DMP_CNT_S)-1 downto 0) of
                                std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                               ; --! Dual port memory dump type
type     t_multi_mem_dump       is array (natural range <>) of t_mem_dump                                   ; --! Multi Dual port memory dump type
signal   mem_dump             : t_multi_mem_dump(0 to c_NB_COL-1)                                           ; --! Multi Dual port memory dump

signal   arst                 : std_logic                                                                   ; --! Asynchronous reset ('0' = Inactive, '1' = Active)
signal   sync_r               : std_logic_vector(c_ADC_DATA_NPER-2 downto 0)                                ; --! Pixel sequence sync. register (R.E. detected = position sequence to the first pixel)
signal   sync_re_adc_data     : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge, synchronized on ADC data first pixel

signal   tm_mode_dmp_cmp      : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active)
signal   tm_mode_dmp_cmp_last : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" compared last sync. ('0' = Inactive, '1' = Active)
signal   sq1_adc_data_dmp_cmp : t_sq1_adc_data_v(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Data buses, status "Dump" compared
signal   sq1_adc_oor_dmp_cmp  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Out of range, status "Dump" compared
signal   sc_data_ctrl_dmp_cmp : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Science Data – Control word, status "Dump" compared

signal   tm_mode_dmp_or       : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Telemetry mode, status "Dump" "or-ed"
signal   sq1_adc_data_dmp_or  : t_sq1_adc_data_v(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Data buses "or-ed"
signal   sq1_adc_oor_dmp_or   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC - Out of range "or-ed"
signal   sc_data_ctrl_dmp_or  : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! Science Data – Control word, status "Dump" "or-ed"

signal   mem_dump_adc_cnt_w   : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: counter words
signal   mem_dump_adc_add     : std_logic_vector(     c_DMP_CNT_S-1 downto 0)                               ; --! Memory Dump, ADC acquisition side: address
signal   mem_dump_adc_data_in : std_logic_vector(c_SQ1_ADC_DATA_S+1 downto 0)                               ; --! Memory Dump, ADC acquisition side: data in

signal   mem_dump_sc_add      : std_logic_vector(     c_DMP_CNT_S-2 downto 0)                               ; --! Memory Dump, science side: address
signal   mem_dump_sc_data_out : t_sq1_mem_dump_dta_v(0 to c_NB_COL-1)                                       ; --! Memory Dump, science side: data out

signal   science_data_ser     : std_logic_vector(c_NB_COL*c_SC_DATA_SER_NB+1 downto 0)                      ; --! Science Data – Serial Data
signal   science_data_ctrl    : t_sc_data_w(0 to 1)                                                         ; --! Science Data – Control word
signal   science_data         : t_sc_data(0 to c_NB_COL-1)                                                  ; --! Science Data – Data
signal   science_data_rdy     : std_logic                                                                   ; --! Science Data Ready ('0' = Inactive, '1' = Active)
signal   science_data_rdy_r   : std_logic                                                                   ; --! Science Data Ready register

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Reset generation
   -- ------------------------------------------------------------------------------------------------------
   arst <= not(i_arst_n);

   -- ------------------------------------------------------------------------------------------------------
   --!   Select adc data channel according to dump telemetry mode
   -- ------------------------------------------------------------------------------------------------------
   tm_mode_dmp_or(0)       <= tm_mode_dmp_cmp(0);
   sq1_adc_data_dmp_or(0)  <= sq1_adc_data_dmp_cmp(0);
   sq1_adc_oor_dmp_or(0)   <= sq1_adc_oor_dmp_cmp(0);
   sc_data_ctrl_dmp_or(0)  <= sc_data_ctrl_dmp_cmp(0);

   G_tm_mode_cmp : for k in 0 to c_NB_COL-1 generate
   begin

      tm_mode_dmp_cmp(k)      <= '1'               when i_tm_mode(k) = c_DST_TM_MODE_DUMP else '0';
      sq1_adc_data_dmp_cmp(k) <= i_sq1_adc_data(k) when i_tm_mode(k) = c_DST_TM_MODE_DUMP else (others => '0');
      sq1_adc_oor_dmp_cmp(k)  <= i_sq1_adc_oor(k)  when i_tm_mode(k) = c_DST_TM_MODE_DUMP else '0';
      sc_data_ctrl_dmp_cmp(k) <= '1'               when science_data_ctrl(0) = c_SC_CTRL_ADC_DMP(k) else '0';

      G_tm_mode_or: if k /= 0 generate
         tm_mode_dmp_or(k)      <= tm_mode_dmp_cmp(k)      or tm_mode_dmp_or(k-1);
         sq1_adc_data_dmp_or(k) <= sq1_adc_data_dmp_cmp(k) or sq1_adc_data_dmp_or(k-1);
         sq1_adc_oor_dmp_or(k)  <= sq1_adc_oor_dmp_cmp(k)  or sq1_adc_oor_dmp_or(k-1);
         sc_data_ctrl_dmp_or(k) <= sc_data_ctrl_dmp_cmp(k) or sc_data_ctrl_dmp_or(k-1);

      end generate;

   end generate G_tm_mode_cmp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Signals registered
   -- ------------------------------------------------------------------------------------------------------
   P_reg : process (arst, i_clk_sq1_adc_acq)
   begin

      if arst = '1' then
         sync_r               <= (others => c_I_SYNC_DEF);
         sync_re_adc_data     <= '0';
         tm_mode_dmp_cmp_last <= (others => '0');

      elsif rising_edge(i_clk_sq1_adc_acq) then
         sync_r               <= sync_r(sync_r'high-1 downto 0) & i_sync;
         sync_re_adc_data     <= not(sync_r(sync_r'high)) and sync_r(sync_r'high-1);

         if sync_re_adc_data = '1' then
            tm_mode_dmp_cmp_last <= tm_mode_dmp_cmp;

         end if;

      end if;

   end process P_reg;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC acquisition counter words
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_adc_cnt_w : process (arst, i_clk_sq1_adc_acq)
   begin

      if arst = '1' then
         mem_dump_adc_cnt_w   <= (others => '1');

      elsif rising_edge(i_clk_sq1_adc_acq) then
         if (mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) and tm_mode_dmp_or(tm_mode_dmp_or'high) and sync_re_adc_data) = '1' and (tm_mode_dmp_cmp_last /= tm_mode_dmp_cmp) then
            mem_dump_adc_cnt_w <= std_logic_vector(to_unsigned(c_DMP_CNT_MAX_VAL, mem_dump_adc_cnt_w'length));

         elsif mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = '0' then
            mem_dump_adc_cnt_w <= std_logic_vector(signed(mem_dump_adc_cnt_w) - 1);

         end if;

      end if;

   end process P_mem_dump_adc_cnt_w;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memories for Dump
   -- ------------------------------------------------------------------------------------------------------
   mem_dump_adc_add <= std_logic_vector(to_signed(c_DMP_CNT_MAX_VAL, mem_dump_adc_add'length) - signed(mem_dump_adc_cnt_w));

   mem_dump_adc_data_in(c_SQ1_ADC_DATA_S-1 downto 0) <= sq1_adc_data_dmp_or(sq1_adc_data_dmp_or'high);
   mem_dump_adc_data_in(c_SQ1_ADC_DATA_S)            <= sq1_adc_oor_dmp_or(sq1_adc_oor_dmp_or'high);
   mem_dump_adc_data_in(c_SQ1_ADC_DATA_S+1)          <= '0';

   G_mem_dump : for k in 0 to c_NB_COL-1 generate
   begin

      P_mem_dump_w : process(i_clk_sq1_adc_acq)
      begin
         if rising_edge(i_clk_sq1_adc_acq) then
            if mem_dump_adc_cnt_w(mem_dump_adc_cnt_w'high) = '0' and mem_dump_adc_add(log2_ceil(c_NB_COL)-1 downto 0) = std_logic_vector(to_unsigned(k, log2_ceil(c_NB_COL))) then
               mem_dump(k)(to_integer(unsigned(mem_dump_adc_add(mem_dump_adc_add'high-1 downto log2_ceil(c_NB_COL))))) <=  mem_dump_adc_data_in;

           end if;
         end if;
      end process P_mem_dump_w;

      P_mem_dump_r : process(i_clk_science)
      begin
         if rising_edge(i_clk_science) then
            if (science_data_rdy = '1') then
               mem_dump_sc_data_out(k) <= mem_dump(k)(to_integer(signed(mem_dump_sc_add)));

            end if;
         end if;
      end process P_mem_dump_r;

   end generate G_mem_dump;

   -- ------------------------------------------------------------------------------------------------------
   --!   Memory Dump, science side: address
   -- ------------------------------------------------------------------------------------------------------
   P_mem_dump_sc_add : process (arst, i_clk_science)
   begin

      if arst = '1' then
         science_data_rdy_r   <= '0';
         mem_dump_sc_add      <= (others => '0');

      elsif rising_edge(i_clk_science) then
         science_data_rdy_r   <= science_data_rdy;

         if science_data_ctrl(0) = c_SC_CTRL_EOD then
            mem_dump_sc_add <= (others => '0');

         elsif science_data_rdy = '1' then
            mem_dump_sc_add <= std_logic_vector(unsigned(mem_dump_sc_add) + 1);

         end if;

      end if;

   end process P_mem_dump_sc_add;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science Data – Serial Data
   -- ------------------------------------------------------------------------------------------------------
   science_data_ser(1*c_SC_DATA_SER_NB-1 downto 0*c_SC_DATA_SER_NB)  <= i_c0_science_data;
   science_data_ser(2*c_SC_DATA_SER_NB-1 downto 1*c_SC_DATA_SER_NB)  <= i_c1_science_data;
   science_data_ser(3*c_SC_DATA_SER_NB-1 downto 2*c_SC_DATA_SER_NB)  <= i_c2_science_data;
   science_data_ser(4*c_SC_DATA_SER_NB-1 downto 3*c_SC_DATA_SER_NB)  <= i_c3_science_data;
   science_data_ser(4*c_SC_DATA_SER_NB)                              <= i_science_ctrl_01;
   science_data_ser(4*c_SC_DATA_SER_NB+1)                            <= i_science_ctrl_23;

   -- ------------------------------------------------------------------------------------------------------
   --!   Science data receipt
   -- ------------------------------------------------------------------------------------------------------
   I_science_data_rx: entity work.science_data_rx port map
   (     i_rst                => arst                 , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk_science        => i_clk_science        , -- in     std_logic                                 ; --! Science Clock

         i_science_data_ser   => science_data_ser     , -- in     slv(c_NB_COL*c_SC_DATA_SER_NB+1 downto 0) ; --! Science Data – Serial Data
         o_science_data_ctrl  => science_data_ctrl    , -- out    t_sc_data(0 to 1)                         ; --! Science Data – Control word
         o_science_data       => science_data         , -- out    t_sc_data(0 to c_NB_COL-1)                ; --! Science Data – Data
         o_science_data_rdy   => science_data_rdy       -- out    std_logic                                   --! Science Data Ready ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science packet check
   -- ------------------------------------------------------------------------------------------------------
   P_sc_packet_chk : process
   constant c_SIM_NAME        : string    := c_CMD_FILE_ROOT & g_TST_NUM                                    ; --! Simulation name
   type     t_pkt_content       is array (natural range <>) of line                                         ; --! Science packet content type

   variable v_err_sc_ctrl_dif : std_logic                                                                   ; --! Error science data control similar ('0' = No error, '1' = Error)
   variable v_err_sc_ctrl_ukn : std_logic                                                                   ; --! Error science data control unknown ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_start: std_logic                                                                   ; --! Error science packet start missing ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_eod  : std_logic                                                                   ; --! Error science packet end of data missing ('0' = No error, '1' = Error)
   variable v_err_sc_pkt_size : std_logic                                                                   ; --! Error science packet size ('0' = No error, '1' = Error)
   variable v_err_sc_data     : std_logic                                                                   ; --! Error science data ('0' = No error, '1' = Error)

   variable v_ctrl_last       : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0) := c_SC_CTRL_EOD             ; --! Control word last
   variable v_ctrl_first_pkt  : std_logic := '0'                                                            ; --! Control word first packet detected ('0' = No, '1' = Yes)
   variable v_packet_tx_time  : time := 0 ps                                                                ; --! Science packet first word transmit time
   variable v_packet_type     : line := null                                                                ; --! Science packet type
   variable v_packet_dump     : std_logic := '0'                                                            ; --! Science packet dump ('0' = No, '1' = Yes)
   variable v_packet_size     : integer := 0                                                                ; --! Science packet size
   variable v_packet_size_exp : integer := c_MUX_FACT                                                       ; --! Science packet size expected
   variable v_packet_content  : t_pkt_content(0 to c_NB_COL-1) := (others => null)                          ; --! Science packet content
   file     scd_file          : text                                                                        ; --! Science Data Result file
   begin

      -- Variable initialization
      write(v_packet_type, 0);
      o_sc_pkt_err <= '0';

      -- Check if science data analysis is required for unitary test
      if g_TST_NUM /= c_TST_NUM_DEF then

         -- Open Science Data Result file
         file_open(scd_file, c_DIR_RES_FILE & c_SIM_NAME & c_SCD_FILE_SFX, WRITE_MODE);

         -- Check simulation time end
         while(now <= g_SIM_TIME) loop

            -- Wait a new science data
            wait until rising_edge(science_data_rdy_r) for g_SIM_TIME-now;

            -- Exit the loop in case of simulation end
            if now = g_SIM_TIME then
               exit;
            end if;

            -- Errors initialization
            v_err_sc_ctrl_dif := '0';
            v_err_sc_ctrl_ukn := '0';
            v_err_sc_pkt_start:= '0';
            v_err_sc_pkt_eod  := '0';
            v_err_sc_pkt_size := '0';
            v_err_sc_data     := '0';

            -- Increase science packet size
            v_packet_size := v_packet_size + 1;

            -- Check the science data controls are similar
            if science_data_ctrl(0) /= science_data_ctrl(1) then
               v_err_sc_ctrl_dif := '1';
            end if;

            -- Get packet content
            for k in 0 to c_NB_COL-1 loop
               if v_packet_dump = '1' then
                  hwrite(v_packet_content(0), science_data(k));
                  write(v_packet_content(0), ',');

               else
                  hwrite(v_packet_content(k), science_data(k));
                  write(v_packet_content(k), ',');

               end if;

            end loop;

            -- ------------------------------------------------------------------------------------------------------
            -- Science Data Control word analysis
            --    Case Start Dump packet
            -- ------------------------------------------------------------------------------------------------------
            if sc_data_ctrl_dmp_or(sc_data_ctrl_dmp_or'high) = '1' then
               v_ctrl_first_pkt  := '1';
               v_packet_tx_time  := now - (2*c_SC_DATA_SER_W_S+3)*c_CLK_SC_HPER;
               v_packet_dump     := '1';
               v_packet_size     := 1;
               v_packet_size_exp := div_ceil(c_DMP_SEQ_ACQ_NB * c_MUX_FACT * c_PIXEL_ADC_NB_CYC, c_NB_COL);
               o_sc_pkt_type     <= science_data_ctrl(0);

               v_packet_type     := null;
               hwrite(v_packet_type, science_data_ctrl(0));

               -- Reinitialize and get packet content
               v_packet_content := (others => null);

               for k in 0 to c_NB_COL-1 loop
                  hwrite(v_packet_content(0), science_data(k));
                  write(v_packet_content(0), ',');

               end loop;

               -- Check end of data control word was sent before acquiring a new packet
               if v_ctrl_last /= c_SC_CTRL_EOD then
                  v_err_sc_pkt_eod  := '1';
               end if;

            else
               case science_data_ctrl(0) is

                  -- ------------------------------------------------------------------------------------------------------
                  --    Case Start Science Data/Test pattern packet
                  -- ------------------------------------------------------------------------------------------------------
                  when c_SC_CTRL_SC_DTA | c_SC_CTRL_TST_PAT    =>
                     v_ctrl_first_pkt  := '1';
                     v_packet_tx_time  := now - (2*c_SC_DATA_SER_W_S+1)*c_CLK_SC_HPER;
                     v_packet_dump     := '0';
                     v_packet_size     := 1;
                     v_packet_size_exp := c_MUX_FACT;
                     o_sc_pkt_type     <= science_data_ctrl(0);

                     v_packet_type     := null;
                     hwrite(v_packet_type, science_data_ctrl(0));

                     -- Reinitialize and get packet content
                     v_packet_content := (others => null);

                     for k in 0 to c_NB_COL-1 loop
                        hwrite(v_packet_content(k), science_data(k));
                        write(v_packet_content(k), ',');

                     end loop;

                     -- Check end of data control word was sent before acquiring a new packet
                     if v_ctrl_last /= c_SC_CTRL_EOD then
                        v_err_sc_pkt_eod  := '1';
                     end if;

                  -- ------------------------------------------------------------------------------------------------------
                  --    Case data word
                  -- ------------------------------------------------------------------------------------------------------
                  when c_SC_CTRL_DTA_W       =>

                     -- Check start packet was sent before acquiring an another word
                     v_err_sc_pkt_start := not(v_ctrl_first_pkt);

                  -- ------------------------------------------------------------------------------------------------------
                  --    Case end of data packet
                  -- ------------------------------------------------------------------------------------------------------
                  when c_SC_CTRL_EOD         =>

                     -- Check start packet was sent before acquiring an another word
                     v_err_sc_pkt_start := not(v_ctrl_first_pkt);

                     -- Check science packet size
                     if v_packet_size /= v_packet_size_exp then
                        v_err_sc_pkt_size := '1';
                     end if;

                     -- Science Data Result file writing
                     fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);
                     fprintf(none, "Packet header transmit time   : " & time'image(v_packet_tx_time)  , scd_file);
                     fprintf(none, "Packet header                 : " & v_packet_type.all             , scd_file);

                     if v_packet_dump = '1' then
                        fprintf(none, "Packet size                   : " & integer'image(c_NB_COL*v_packet_size), scd_file);
                        fprintf(none, "Packet dump content           : " & v_packet_content(0).all, scd_file);

                     else
                        fprintf(none, "Packet size                   : " & integer'image(v_packet_size), scd_file);

                        for k in 0 to c_NB_COL-1 loop
                        fprintf(none, "Packet content column " & integer'image(k) & "       : " & v_packet_content(k).all, scd_file);

                        end loop;

                     end if;

                     -- Packet variables reinitialization
                     v_ctrl_first_pkt := '0';
                     v_packet_tx_time :=  0 ps;
                     write(v_packet_type, 0);
                     v_packet_dump    := '0';
                     v_packet_size    :=  0;
                     o_sc_pkt_type    <= (others => '0');

                  -- ------------------------------------------------------------------------------------------------------
                  --    Case control word unknown
                  -- ------------------------------------------------------------------------------------------------------
                  when others                =>
                     v_err_sc_ctrl_ukn := '1';

               end case;
            end if;

            -- Check science data
            -- TODO Check science data others cases
            if v_packet_dump = '1' then
               for k in 0 to c_NB_COL-1 loop
                  if science_data(k) /= std_logic_vector(resize(unsigned(mem_dump_sc_data_out(k)), c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S)) then
                     v_err_sc_data := '1';

                  end if;
               end loop;
            end if;

            -- Update Control word last
            v_ctrl_last := science_data_ctrl(0);

            -- Errors display
            if v_err_sc_ctrl_dif = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data Control different on the two lines", scd_file);
            end if;

            if v_err_sc_ctrl_ukn = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data Control unknown", scd_file);
            end if;

            if v_err_sc_pkt_start = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data packet header missing", scd_file);
            end if;

            if v_err_sc_pkt_eod = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data packet end of data missing", scd_file);
            end if;

            if v_err_sc_pkt_size = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data packet size not expected", scd_file);
            end if;

            if v_err_sc_data = '1' then
               o_sc_pkt_err <= '1';
               fprintf(error, "Science Data packet content not expected", scd_file);
            end if;

            wait until falling_edge(science_data_rdy_r) for g_SIM_TIME-now;

         end loop;

         -- Final test status
         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);
         if o_sc_pkt_err = '0' then
            fprintf(none, "Simulation status             : PASS", scd_file);

         else
            fprintf(none, "Simulation status             : FAIL", scd_file);

         end if;

         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, scd_file);

         -- Close file
         file_close(scd_file);

      end if;

      -- Wait simulation end
      wait;

   end process P_sc_packet_chk;

end architecture rtl;
