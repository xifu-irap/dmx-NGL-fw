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
--!   @file                   parser.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Parse the unitary test script, monitor signals requested by the script and write result into file output
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_mess.all;
use     work.pkg_model.all;
use     work.pkg_func_parser.all;

library std;
use std.textio.all;

entity parser is generic (
         g_SIM_TIME           : time      := c_SIM_TIME_DEF                                                 ; --! Simulation time
         g_SIM_TYPE           : std_logic := c_SIM_TYPE_DEF                                                 ; --! Simulation type ('0': No regression, '1': Coupled simulation)
         g_TST_NUM            : string    := c_TST_NUM_DEF                                                    --! Test number
   ); port (
         o_arst_n             : out    std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        : in     t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)     ; --! Clock check error reports
         i_err_n_spi_chk      : in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)      ; --! SPI check error number:
         i_err_num_pls_shp    : in     integer_vector(0 to c_NB_COL-1)                                      ; --! Pulse shaping error number

         i_sqm_adc_pwdn       : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)
         i_sqm_adc_ana        : in     real_vector(0 to c_NB_COL-1)                                         ; --! SQUID MUX ADC: Analog
         i_sqm_dac_sleep      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_adc      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqm_dac      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sqa_mux      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              : in     std_logic                                                            ; --! Internal design: System Clock
         i_d_clk_sqm_adc_acq  : in     std_logic                                                            ; --! Internal design: SQUID MUX ADC acquisition Clock
         i_d_clk_sqm_pls_shap : in     std_logic                                                            ; --! Internal design: SQUID MUX pulse shaping Clock

         i_clk_sqm_adc        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX ADC: Clock
         i_clk_sqm_dac        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID MUX DAC: Clock

         i_sc_pkt_type        : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! Science packet type
         i_sc_pkt_err         : in     std_logic                                                            ; --! Science packet error ('0' = No error, '1' = Error)

         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP: Receipted data
         i_ep_data_rx_rdy     : in     std_logic                                                            ; --! EP: Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP: Command to send
         o_ep_cmd_start       : out    std_logic                                                            ; --! EP: Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      : in     std_logic                                                            ; --! EP: Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP: Serial word size

         o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         o_brd_model          : out    std_logic_vector(c_BRD_MODEL_S-1 downto 0)                           ; --! Board model
         o_ras_data_valid     : out    std_logic                                                            ; --! RAS Data valid ('0' = No, '1' = Yes)

         o_pls_shp_fc         : out    integer_vector(0 to c_NB_COL-1)                                      ; --! Pulse shaping cut frequency (Hz)
         o_sw_adc_vin         : out    std_logic_vector(c_SW_ADC_VIN_S-1 downto 0)                          ; --! Switch ADC Voltage input

         o_frm_cnt_sc_rst     : out    std_logic                                                            ; --! Frame counter science reset ('0' = Inactive, '1' = Active)
         o_adc_dmp_mem_add    : out    std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                        ; --! ADC Dump memory for data compare: address
         o_adc_dmp_mem_data   : out    std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --! ADC Dump memory for data compare: data
         o_science_mem_data   : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --! Science  memory for data compare: data
         o_adc_dmp_mem_cs     : out    std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)

         i_fpa_conf_busy      : in     std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! FPASIM configuration ('0' = conf. over, '1' = conf. in progress)
         i_fpa_cmd_rdy        : in     std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! FPASIM command ready ('0' = No, '1' = Yes)
         o_fpa_cmd            : out    t_slv_arr(0 to c_NB_COL-1)(c_FPA_CMD_S-1 downto 0)                   ; --! FPASIM command
         o_fpa_cmd_valid      : out    std_logic_vector(        c_NB_COL-1 downto 0)                          --! FPASIM command valid ('0' = No, '1' = Yes)
   );
end entity parser;

architecture Simulation of parser is
constant c_SIM_NAME           : string    := c_CMD_FILE_ROOT & g_TST_NUM                                    ; --! Simulation name

signal   discrete_w           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete write
signal   discrete_r           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete read
signal   discrete_r_lst_ev    : time_vector(0 to c_CMD_FILE_FLD_DATA_S-1)                                   ; --! Discrete read last event time

signal   sqm_adc_ana_lst_ev   : time_vector(0 to c_NB_COL-1)                                                ; --! SQUID MUX ADC: Analog last event time

file     cmd_file             : text                                                                        ; --! Command file
file     res_file             : text                                                                        ; --! Result file

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete write signals association
   -- ------------------------------------------------------------------------------------------------------
   o_arst_n             <= discrete_w(c_DW_ARST_N);
   o_brd_model          <= discrete_w(c_DW_BRD_MODEL_2  downto c_DW_BRD_MODEL_0);
   o_sw_adc_vin         <= discrete_w(c_DW_SW_ADC_VIN_1 downto c_DW_SW_ADC_VIN_0);
   o_frm_cnt_sc_rst     <= discrete_w(c_DW_FRM_CNT_SC_RST);
   o_ras_data_valid     <= discrete_w(c_DW_RAS_DATA_VALID);

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete read signals association
   -- ------------------------------------------------------------------------------------------------------
   discrete_r(c_DR_D_RST)           <= i_d_rst;
   discrete_r(c_DR_CLK_REF)         <= i_clk_ref;
   discrete_r(c_DR_D_CLK)           <= i_d_clk;
   discrete_r(c_DR_D_CLK_SQM_ADC)   <= i_d_clk_sqm_adc_acq;
   discrete_r(c_DR_D_CLK_SQM_PLS_SH)<= i_d_clk_sqm_pls_shap;
   discrete_r(c_DR_EP_CMD_BUSY_N)   <= i_ep_cmd_busy_n;
   discrete_r(c_DR_EP_DATA_RX_RDY)  <= i_ep_data_rx_rdy;
   discrete_r(c_DR_D_RST_SQM_ADC_0) <= i_d_rst_sqm_adc(c_COL0);
   discrete_r(c_DR_D_RST_SQM_ADC_1) <= i_d_rst_sqm_adc(c_COL1);
   discrete_r(c_DR_D_RST_SQM_ADC_2) <= i_d_rst_sqm_adc(c_COL2);
   discrete_r(c_DR_D_RST_SQM_ADC_3) <= i_d_rst_sqm_adc(c_COL3);
   discrete_r(c_DR_D_RST_SQM_DAC_0) <= i_d_rst_sqm_dac(c_COL0);
   discrete_r(c_DR_D_RST_SQM_DAC_1) <= i_d_rst_sqm_dac(c_COL1);
   discrete_r(c_DR_D_RST_SQM_DAC_2) <= i_d_rst_sqm_dac(c_COL2);
   discrete_r(c_DR_D_RST_SQM_DAC_3) <= i_d_rst_sqm_dac(c_COL3);
   discrete_r(c_DR_D_RST_SQA_MUX_0) <= i_d_rst_sqa_mux(c_COL0);
   discrete_r(c_DR_D_RST_SQA_MUX_1) <= i_d_rst_sqa_mux(c_COL1);
   discrete_r(c_DR_D_RST_SQA_MUX_2) <= i_d_rst_sqa_mux(c_COL2);
   discrete_r(c_DR_D_RST_SQA_MUX_3) <= i_d_rst_sqa_mux(c_COL3);
   discrete_r(c_DR_SYNC)            <= i_sync;
   discrete_r(c_DR_SQM_ADC_PWDN_0)  <= i_sqm_adc_pwdn(c_COL0);
   discrete_r(c_DR_SQM_ADC_PWDN_1)  <= i_sqm_adc_pwdn(c_COL1);
   discrete_r(c_DR_SQM_ADC_PWDN_2)  <= i_sqm_adc_pwdn(c_COL2);
   discrete_r(c_DR_SQM_ADC_PWDN_3)  <= i_sqm_adc_pwdn(c_COL3);
   discrete_r(c_DR_SQM_DAC_SLEEP_0) <= i_sqm_dac_sleep(c_COL0);
   discrete_r(c_DR_SQM_DAC_SLEEP_1) <= i_sqm_dac_sleep(c_COL1);
   discrete_r(c_DR_SQM_DAC_SLEEP_2) <= i_sqm_dac_sleep(c_COL2);
   discrete_r(c_DR_SQM_DAC_SLEEP_3) <= i_sqm_dac_sleep(c_COL3);
   discrete_r(c_DR_CLK_SQM_ADC_0)   <= i_clk_sqm_adc(c_COL0);
   discrete_r(c_DR_CLK_SQM_ADC_1)   <= i_clk_sqm_adc(c_COL1);
   discrete_r(c_DR_CLK_SQM_ADC_2)   <= i_clk_sqm_adc(c_COL2);
   discrete_r(c_DR_CLK_SQM_ADC_3)   <= i_clk_sqm_adc(c_COL3);
   discrete_r(c_DR_CLK_SQM_DAC_0)   <= i_clk_sqm_dac(c_COL0);
   discrete_r(c_DR_CLK_SQM_DAC_1)   <= i_clk_sqm_dac(c_COL1);
   discrete_r(c_DR_CLK_SQM_DAC_2)   <= i_clk_sqm_dac(c_COL2);
   discrete_r(c_DR_CLK_SQM_DAC_3)   <= i_clk_sqm_dac(c_COL3);
   discrete_r(c_DR_FPA_CONF_BUSY_0) <= i_fpa_conf_busy(c_COL0);
   discrete_r(c_DR_FPA_CONF_BUSY_1) <= i_fpa_conf_busy(c_COL1);
   discrete_r(c_DR_FPA_CONF_BUSY_2) <= i_fpa_conf_busy(c_COL2);
   discrete_r(c_DR_FPA_CONF_BUSY_3) <= i_fpa_conf_busy(c_COL3);

   discrete_r(discrete_r'high downto c_DR_S) <= (others => c_LOW_LEV);

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX ADC: Analog last event time
   -- ------------------------------------------------------------------------------------------------------
   G_sqm_adc_ana_lst_ev: for k in 0 to c_NB_COL-1 generate
   begin

      --! SQUID MUX ADC: Analog last event time
      P_sqm_adc_ana_lst_ev: process
      begin
            sqm_adc_ana_lst_ev(k) <= c_ZERO_TIME;

         loop
            wait until i_sqm_adc_ana(k)'event;
               sqm_adc_ana_lst_ev(k) <= now;

         end loop;

      end process P_sqm_adc_ana_lst_ev;

   end generate G_sqm_adc_ana_lst_ev;

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete read last event time
   -- ------------------------------------------------------------------------------------------------------
   G_discrete_r_lst_ev: for k in 0 to c_DR_S-1 generate
   begin

      --! Discrete read last event time
      P_discrete_r_lst_ev: process
      begin
            discrete_r_lst_ev(k) <= c_ZERO_TIME;

         loop
            wait until discrete_r(k)'event;
               discrete_r_lst_ev(k) <= now;

         end loop;

      end process P_discrete_r_lst_ev;

   end generate G_discrete_r_lst_ev;

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser sequence: read command file and write result file
   -- ------------------------------------------------------------------------------------------------------
   P_parser_seq: process
   variable v_error_cat       : std_logic_vector(c_ERROR_CAT_NB-1 downto 0)                                 ; --! Error category
   alias    v_err_sim_time    : std_logic is v_error_cat(c_ERR_SIM_TIME)                                    ; --! Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   alias    v_err_chk_dis_r   : std_logic is v_error_cat(c_ERR_CHK_DIS_R)                                   ; --! Error check discrete read  ('0' = No error, '1' = Error)
   alias    v_err_chk_cmd_r   : std_logic is v_error_cat(c_ERR_CHK_CMD_R)                                   ; --! Error check command return ('0' = No error, '1' = Error)
   alias    v_err_chk_time    : std_logic is v_error_cat(c_ERR_CHK_TIME)                                    ; --! Error check time           ('0' = No error, '1' = Error)
   alias    v_err_chk_clk_prm : std_logic is v_error_cat(c_ERR_CHK_CLK_PRM)                                 ; --! Error check clocks parameters ('0' = No error, '1' = Error)
   alias    v_err_chk_spi_prm : std_logic is v_error_cat(c_ERR_CHK_SPI_PRM)                                 ; --! Error check SPI parameters ('0' = No error, '1' = Error)
   alias    v_err_chk_sc_pkt  : std_logic is v_error_cat(c_ERR_CHK_SC_PKT)                                  ; --! Error check science packet ('0' = No error, '1' = Error)
   alias    v_err_chk_pls_shp : std_logic is v_error_cat(c_ERR_CHK_PLS_SHP)                                 ; --! Error check pulse shaping ('0' = No error, '1' = Error)
   variable v_chk_rpt_prm_ena : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Check report parameters enable

   variable v_line_cnt        : integer                                                                     ; --! Command file line counter
   variable v_head_mess_stdout: line                                                                        ; --! Header message output stream stdout
   variable v_cmd_file_line   : line                                                                        ; --! Command file line
   variable v_fld_cmd         : line                                                                        ; --! Field script command
   variable v_record_time     : time                                                                        ; --! Record time
   begin

      -- Open Command and Result files
      if g_SIM_TYPE = '0' then
         file_open(cmd_file, c_DIR_ROOT_SIMU & c_DIR_CMD_FILE & c_SIM_NAME & c_CMD_FILE_SFX, READ_MODE );
         file_open(res_file, c_DIR_ROOT_SIMU & c_DIR_RES_FILE & c_SIM_NAME & c_RES_FILE_SFX, WRITE_MODE);

      else
         file_open(cmd_file, c_DIR_ROOT_COSIM & c_DIR_CMD_FILE & c_SIM_NAME & c_CMD_FILE_SFX, READ_MODE );
         file_open(res_file, c_DIR_ROOT_COSIM & c_DIR_RES_FILE & c_SIM_NAME & c_RES_FILE_SFX, WRITE_MODE);

      end if;

      -- Result file header
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation " & c_SIM_NAME, res_file);
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

      -- Default value initialization
      discrete_w        <= (others => c_LOW_LEV);
      o_brd_ref         <= (others => c_LOW_LEV);
      o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(c_EP_CMD_S, o_ep_cmd_ser_wd_s'length));
      o_ep_cmd          <= (others => c_LOW_LEV);
      o_ep_cmd_start    <= c_LOW_LEV;
      o_adc_dmp_mem_cs  <= (others => c_LOW_LEV);
      o_fpa_cmd         <= (others => (others => c_LOW_LEV));
      o_fpa_cmd_valid   <= (others => c_LOW_LEV);
      v_error_cat       := (others => c_LOW_LEV);
      v_chk_rpt_prm_ena := (others => c_LOW_LEV);
      v_line_cnt        := 1;
      v_record_time     := c_ZERO_TIME;

      for k in 0 to c_NB_COL-1 loop
         o_pls_shp_fc(k) <= c_PLS_CUT_FREQ_DEF;

      end loop;

      -- Command file parser
      while not(endfile(cmd_file)) loop
         readline(cmd_file, v_cmd_file_line);

         -- Header message output stream stdout
         v_head_mess_stdout := null;
         write(v_head_mess_stdout, "File " & c_SIM_NAME & ", line " & integer'image(v_line_cnt) & ": ");

         -- Do nothing for empty line
         if v_cmd_file_line'length /= 0 then

            -- Get [cmd]
            rfield(v_cmd_file_line, v_head_mess_stdout.all & "[cmd]", c_CMD_FILE_CMD_S, v_fld_cmd);

            -- [cmd] analysis
            case v_fld_cmd(1 to c_CMD_FILE_CMD_S) is

               -- ------------------------------------------------------------------------------------------------------
               -- Command CCMD [cmd] [end]: check the EP command return
               -- ------------------------------------------------------------------------------------------------------
               when "CCMD" =>
                  parser_cmd_ccmd(v_cmd_file_line, v_head_mess_stdout.all, res_file, i_ep_cmd_busy_n, i_ep_data_rx, g_SIM_TIME, v_err_chk_cmd_r, v_err_sim_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CCPE [report]: Enable the display in result file of the report about the check parameters
               -- ------------------------------------------------------------------------------------------------------
               when "CCPE" =>
                  parser_cmd_ccpe(v_cmd_file_line, v_head_mess_stdout.all, res_file, v_chk_rpt_prm_ena);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CDIS [discrete_r] [value]: check discrete input
               -- ------------------------------------------------------------------------------------------------------
               when "CDIS" =>
                  parser_cmd_cdis(v_cmd_file_line, v_head_mess_stdout.all, res_file, discrete_r, v_err_chk_dis_r);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CLDC [channel] [value]: check level SQUID MUX ADC input
               -- ------------------------------------------------------------------------------------------------------
               when "CLDC" =>
                  parser_cmd_cldc(v_cmd_file_line, v_head_mess_stdout.all, res_file, i_sqm_adc_ana, v_err_chk_dis_r);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CSCP [science_packet] : check the science packet type
               -- ------------------------------------------------------------------------------------------------------
               when "CSCP" =>
                  parser_cmd_cscp(v_cmd_file_line, v_head_mess_stdout.all, res_file, i_sc_pkt_type, v_err_chk_sc_pkt);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTDC [channel] [ope] [time]: check time between the current time
               --   and last event SQUID MUX ADC input
               -- ------------------------------------------------------------------------------------------------------
               when "CTDC" =>
                  parser_cmd_ctdc(v_cmd_file_line, v_head_mess_stdout.all, res_file, sqm_adc_ana_lst_ev, v_err_chk_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLE [mask] [ope] [time]: check time between the current time and discrete input(s) last event
               -- ------------------------------------------------------------------------------------------------------
               when "CTLE" =>
                  parser_cmd_ctle(v_cmd_file_line, v_head_mess_stdout.all, res_file, discrete_r_lst_ev, v_err_chk_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLR [ope] [time]: check time from the last record time
               -- ------------------------------------------------------------------------------------------------------
               when "CTLR" =>
                  parser_cmd_ctlr(v_cmd_file_line, v_head_mess_stdout.all, res_file, v_record_time, v_err_chk_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command COMM: add comment in result file
               -- ------------------------------------------------------------------------------------------------------
               when "COMM" =>
                  fprintf(info, v_cmd_file_line(v_cmd_file_line'range), res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command RTIM: record current time
               -- ------------------------------------------------------------------------------------------------------
               when "RTIM" =>
                  v_record_time := now;
                  fprintf(note, "Record current time", res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WAIT [time]: wait for time
               -- ------------------------------------------------------------------------------------------------------
               when "WAIT" =>
                  parser_cmd_wait(v_cmd_file_line, v_head_mess_stdout.all, res_file, g_SIM_TIME, v_err_sim_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMD [cmd] [end]: transmit EP command
               -- ------------------------------------------------------------------------------------------------------
               when "WCMD" =>
                  parser_cmd_wcmd(v_cmd_file_line, v_head_mess_stdout.all, res_file, g_SIM_TIME, i_ep_data_rx_rdy, o_ep_cmd, o_ep_cmd_start, i_ep_cmd_busy_n, v_err_sim_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMS [size]: write EP command word size
               -- ------------------------------------------------------------------------------------------------------
               when "WCMS" =>
                  parser_cmd_wcms(v_cmd_file_line, v_head_mess_stdout.all, res_file, o_ep_cmd_ser_wd_s);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WDIS [discrete_w] [value]: write discrete output
               -- ------------------------------------------------------------------------------------------------------
               when "WDIS" =>
                  parser_cmd_wdis(v_cmd_file_line, v_head_mess_stdout.all, res_file, discrete_w);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WFMP [channel] [data]: write FPASIM "Make pulse" command
               -- ------------------------------------------------------------------------------------------------------
               when "WFMP" =>
                  parser_cmd_wfmp(v_cmd_file_line, v_head_mess_stdout.all, res_file, g_SIM_TIME, i_fpa_cmd_rdy, o_fpa_cmd, o_fpa_cmd_valid);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WMDC [channel] [index] [data]:
               --  Write in ADC dump/science memories for data compare
               -- ------------------------------------------------------------------------------------------------------
               when "WMDC" =>
                  parser_cmd_wmdc(v_cmd_file_line, v_head_mess_stdout.all, res_file, o_adc_dmp_mem_add, o_adc_dmp_mem_data, o_science_mem_data, o_adc_dmp_mem_cs);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WNBD [number]: write board reference number
               -- ------------------------------------------------------------------------------------------------------
               when "WNBD" =>
                  parser_cmd_wnbd(v_cmd_file_line, v_head_mess_stdout.all, res_file, o_brd_ref);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WPFC [channel] [frequency]: write pulse shaping cut frequency for verification
               -- ------------------------------------------------------------------------------------------------------
               when "WPFC" =>
                  parser_cmd_wpfc(v_cmd_file_line, v_head_mess_stdout.all, res_file, o_pls_shp_fc);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
               -- ------------------------------------------------------------------------------------------------------
               when "WUDI" =>
                  parser_cmd_wudi(v_cmd_file_line, v_head_mess_stdout.all, res_file, g_SIM_TIME, discrete_r, v_err_sim_time);

               -- ------------------------------------------------------------------------------------------------------
               -- Command unknown
               -- ------------------------------------------------------------------------------------------------------
               when others =>
                  assert v_fld_cmd = null report v_head_mess_stdout.all & "[cmd]" & c_MESS_ERR_UNKNOWN severity failure;

            end case;

         end if;

         -- Exit loop in case of error simulation time
         if v_err_sim_time = '1' then
            exit;
         end if;

         -- Update line counter
         v_line_cnt := v_line_cnt + 1;

         -- Wait end of delta cycles before new command handling
         wait for c_ZERO_TIME;

      end loop;

      -- Wait the simulation end
      if now <= g_SIM_TIME then
         wait for g_SIM_TIME - now;
      end if;

      -- Clocks parameters results
      for k in 0 to c_CHK_ENA_CLK_NB-1 loop

         -- Check if clock parameters check is enabled
         if v_chk_rpt_prm_ena(k) = '1' then

            -- Write clock parameters check results
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);
            fprintf(none, "Parameters check, clock " & c_CCHK(k).clk_name , res_file);
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);

            -- Check if oscillation on clock when enable inactive parameter is disable
            if c_CCHK(k).chk_osc_en = c_CHK_OSC_DIS then
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_OSC_EN_L)) &
               ", inactive parameter (no check)", res_file);

            else
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_OSC_EN_L))
               , res_file);

            end if;

            fprintf(none, "Error number of high level clock period timing :            " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_PER_H)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_h), res_file);

            fprintf(none, "Error number of low  level clock period timing :            " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_PER_L)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_l), res_file);

            fprintf(none, "Error number of clock state when enable goes to inactive :  " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_ST_EN_L)) &
            ", expected state:  " & std_logic'image(c_CCHK(k).clk_st_ena), res_file);

            fprintf(none, "Error number of clock state when enable goes to active   :  " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_ST_EN_H)) &
            ", expected state:  " & std_logic'image(c_CCHK(k).clk_st_dis), res_file);

            -- Set possible error
            for j in 0 to c_ERR_N_CLK_CHK_S-1 loop
               if i_err_chk_rpt(k)(j) /= 0 then
                  v_err_chk_clk_prm := '1';
               end if;
            end loop;

         end if;
      end loop;

      -- SPI parameters results
      for k in 0 to c_CHK_ENA_SPI_NB-1 loop

         -- Check if SPI parameters check is enabled
         if v_chk_rpt_prm_ena(k+c_CHK_ENA_CLK_NB) = '1' then

            -- Write SPI parameters check results
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);
            fprintf(none, "Parameters check, SPI " & c_SCHK(k).spi_name , res_file);
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);

            fprintf(none, "Error number of low level sclk timing  :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TL)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TL)), res_file);

            fprintf(none, "Error number of high level sclk timing :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TH)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TH)), res_file);

            fprintf(none, "Error number of sclk minimum period    :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TSCMIN)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TSCMIN)), res_file);

            fprintf(none, "Error number of sclk maximum period    :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TSCMAX)) &
            ", expected timing <= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TSCMAX)), res_file);

            fprintf(none, "Error number of high level cs timing   :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TCSH)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TCSH)), res_file);

            fprintf(none, "Error number of sclk edge to cs rising edge timing :        " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TS2CSR)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TS2CSR)), res_file);

            fprintf(none, "Error number of data edge to sclk edge timing :             " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TD2S)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TD2S)), res_file);

            fprintf(none, "Error number of sclk edge to data edge timing :             " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TS2D)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TS2D)), res_file);

            fprintf(none, "Error number of sclk state when cs goes to active   :       " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_STSCA)), res_file);
            fprintf(none, "Error number of sclk state when cs goes to inactive :       " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_STSCI)), res_file);

            -- Set possible error
            for j in 0 to c_SPI_ERR_CHK_NB-1 loop
               if i_err_n_spi_chk(k)(j) /= 0 then
                  v_err_chk_spi_prm := '1';
               end if;
            end loop;

         end if;
      end loop;

      -- Pulse shaping error report
      if v_chk_rpt_prm_ena(c_E_PLS_SHP) = '1' then
         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

         for k in 0 to c_NB_COL-1 loop

            fprintf(none, "Error number pulse shaping channel " & integer'image(k) & ": " & integer'image(i_err_num_pls_shp(k)),   res_file);

            if i_err_num_pls_shp(k) /= 0 then
               v_err_chk_pls_shp := '1';
            end if;

         end loop;

      end if;

      -- Result file end
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Error simulation time         : " & std_logic'image(v_err_sim_time),   res_file);
      fprintf(none, "Error check discrete level    : " & std_logic'image(v_err_chk_dis_r),  res_file);
      fprintf(none, "Error check command return    : " & std_logic'image(v_err_chk_cmd_r),  res_file);
      fprintf(none, "Error check time              : " & std_logic'image(v_err_chk_time),   res_file);
      fprintf(none, "Error check clocks parameters : " & std_logic'image(v_err_chk_clk_prm),res_file);
      fprintf(none, "Error check spi parameters    : " & std_logic'image(v_err_chk_spi_prm),res_file);
      fprintf(none, "Error check science packets   : " & std_logic'image(v_err_chk_sc_pkt or i_sc_pkt_err), res_file);
      fprintf(none, "Error check pulse shaping     : " & std_logic'image(v_err_chk_pls_shp),res_file);

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation time               : " & time'image(now), res_file);

      -- Final test status
      if v_error_cat = c_ZERO(v_error_cat'range) and i_sc_pkt_err = '0' then
         fprintf(none, "Simulation status             : PASS", res_file);

      else
         fprintf(none, "Simulation status             : FAIL", res_file);

      end if;

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

      -- Close files
      file_close(cmd_file);
      file_close(res_file);

      wait;

   end process P_parser_seq;

end architecture Simulation;
