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
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_mess.all;
use     work.pkg_model.all;
use     work.pkg_func_cmd_script.all;

library std;
use std.textio.all;

entity parser is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     o_arst_n             : out    std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_err_chk_rpt        : in     t_err_n_clk_chk_arr(0 to c_CE_S-1)                                   ; --! Clock check error reports

         i_c0_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 0 – Power Down ('0' = Inactive, '1' = Active)
         i_c1_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 1 – Power Down ('0' = Inactive, '1' = Active)
         i_c2_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 2 – Power Down ('0' = Inactive, '1' = Active)
         i_c3_sq1_adc_pwdn	   : in     std_logic                                                            ; --! SQUID1 ADC, col. 3 – Power Down ('0' = Inactive, '1' = Active)

         i_c0_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 0 - Data
         i_c1_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 1 - Data
         i_c2_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 2 - Data
         i_c3_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 3 - Data

         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_adc      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq1_dac      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_rst_sq2_mux      : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion

         i_d_clk              : in     std_logic                                                            ; --! Internal design: System Clock
         i_d_clk_sq1_adc_acq  : in     std_logic                                                            ; --! Internal design: SQUID1 ADC acquisition Clock
         i_d_clk_sq1_pls_shap : in     std_logic                                                            ; --! Internal design: SQUID1 pulse shaping Clock

         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Receipted data
         i_ep_data_rx_rdy     : in     std_logic                                                            ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Command to send
         o_ep_cmd_start       : out    std_logic                                                            ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      : in     std_logic                                                            ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)               ; --! EP - Serial word size

         o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                           ; --! Board reference
         o_brd_model          : out    std_logic_vector(c_BRD_MODEL_S-1 downto 0)                             --! Board model

   );
end entity parser;

architecture Simulation of parser is
constant c_SIM_NAME           : string    := c_CMD_FILE_ROOT & g_TST_NUM                                    ; --! Simulation name

signal   discrete_w           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete write
signal   discrete_r           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete read

file     cmd_file             : text                                                                        ; --! Command file
file     res_file             : text                                                                        ; --! Result file

   -- ------------------------------------------------------------------------------------------------------
   --! Return the last event time of the signal indexed in discrete read bus
   -- ------------------------------------------------------------------------------------------------------
   function dis_read_last_event (
         discrete_r_index     : integer                                                                       -- Discrete read index
   ) return time is
   begin

      case discrete_r_index is
         when  c_DR_D_RST              => return i_d_rst'last_event;
         when  c_DR_CLK_REF            => return i_clk_ref'last_event;
         when  c_DR_D_CLK              => return i_d_clk'last_event;
         when  c_DR_D_CLK_SQ1_ADC      => return i_d_clk_sq1_adc_acq'last_event;
         when  c_DR_D_CLK_SQ1_PLS_SH   => return i_d_clk_sq1_pls_shap'last_event;
         when  c_DR_EP_CMD_BUSY_N      => return i_ep_cmd_busy_n'last_event;
         when  c_DR_EP_DATA_RX_RDY     => return i_ep_data_rx_rdy'last_event;
         when  c_DR_D_RST_SQ1_ADC_0    => return i_d_rst_sq1_adc'last_event;
         when  c_DR_D_RST_SQ1_ADC_1    => return i_d_rst_sq1_adc'last_event;
         when  c_DR_D_RST_SQ1_ADC_2    => return i_d_rst_sq1_adc'last_event;
         when  c_DR_D_RST_SQ1_ADC_3    => return i_d_rst_sq1_adc'last_event;
         when  c_DR_D_RST_SQ1_DAC_0    => return i_d_rst_sq1_dac'last_event;
         when  c_DR_D_RST_SQ1_DAC_1    => return i_d_rst_sq1_dac'last_event;
         when  c_DR_D_RST_SQ1_DAC_2    => return i_d_rst_sq1_dac'last_event;
         when  c_DR_D_RST_SQ1_DAC_3    => return i_d_rst_sq1_dac'last_event;
         when  c_DR_D_RST_SQ2_MUX_0    => return i_d_rst_sq2_mux'last_event;
         when  c_DR_D_RST_SQ2_MUX_1    => return i_d_rst_sq2_mux'last_event;
         when  c_DR_D_RST_SQ2_MUX_2    => return i_d_rst_sq2_mux'last_event;
         when  c_DR_D_RST_SQ2_MUX_3    => return i_d_rst_sq2_mux'last_event;
         when  c_DR_SYNC               => return i_sync'last_event;
         when  c_DR_SQ1_ADC_PWDN_0     => return i_c0_sq1_adc_pwdn'last_event;
         when  c_DR_SQ1_ADC_PWDN_1     => return i_c1_sq1_adc_pwdn'last_event;
         when  c_DR_SQ1_ADC_PWDN_2     => return i_c2_sq1_adc_pwdn'last_event;
         when  c_DR_SQ1_ADC_PWDN_3     => return i_c3_sq1_adc_pwdn'last_event;
         when  c_DR_SQ1_DAC_SLEEP_0    => return i_c0_sq1_dac_sleep'last_event;
         when  c_DR_SQ1_DAC_SLEEP_1    => return i_c1_sq1_dac_sleep'last_event;
         when  c_DR_SQ1_DAC_SLEEP_2    => return i_c2_sq1_dac_sleep'last_event;
         when  c_DR_SQ1_DAC_SLEEP_3    => return i_c3_sq1_dac_sleep'last_event;
         when others                   => return time'low;

      end case;

   end function;

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete write signals association
   -- ------------------------------------------------------------------------------------------------------
   o_arst_n             <= discrete_w(c_DW_ARST_N);
   o_brd_model(0)       <= discrete_w(c_DW_BRD_MODEL_0);
   o_brd_model(1)       <= discrete_w(c_DW_BRD_MODEL_1);

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete read signals association
   -- ------------------------------------------------------------------------------------------------------
   discrete_r(c_DR_D_RST)           <= i_d_rst;
   discrete_r(c_DR_CLK_REF)         <= i_clk_ref;
   discrete_r(c_DR_D_CLK)           <= i_d_clk;
   discrete_r(c_DR_D_CLK_SQ1_ADC)   <= i_d_clk_sq1_adc_acq;
   discrete_r(c_DR_D_CLK_SQ1_PLS_SH)<= i_d_clk_sq1_pls_shap;
   discrete_r(c_DR_EP_CMD_BUSY_N)   <= i_ep_cmd_busy_n;
   discrete_r(c_DR_EP_DATA_RX_RDY)  <= i_ep_data_rx_rdy;
   discrete_r(c_DR_D_RST_SQ1_ADC_0) <= i_d_rst_sq1_adc(0);
   discrete_r(c_DR_D_RST_SQ1_ADC_1) <= i_d_rst_sq1_adc(1);
   discrete_r(c_DR_D_RST_SQ1_ADC_2) <= i_d_rst_sq1_adc(2);
   discrete_r(c_DR_D_RST_SQ1_ADC_3) <= i_d_rst_sq1_adc(3);
   discrete_r(c_DR_D_RST_SQ1_DAC_0) <= i_d_rst_sq1_dac(0);
   discrete_r(c_DR_D_RST_SQ1_DAC_1) <= i_d_rst_sq1_dac(1);
   discrete_r(c_DR_D_RST_SQ1_DAC_2) <= i_d_rst_sq1_dac(2);
   discrete_r(c_DR_D_RST_SQ1_DAC_3) <= i_d_rst_sq1_dac(3);
   discrete_r(c_DR_D_RST_SQ2_MUX_0) <= i_d_rst_sq2_mux(0);
   discrete_r(c_DR_D_RST_SQ2_MUX_1) <= i_d_rst_sq2_mux(1);
   discrete_r(c_DR_D_RST_SQ2_MUX_2) <= i_d_rst_sq2_mux(2);
   discrete_r(c_DR_D_RST_SQ2_MUX_3) <= i_d_rst_sq2_mux(3);
   discrete_r(c_DR_SYNC)            <= i_sync;
   discrete_r(c_DR_SQ1_ADC_PWDN_0)  <= i_c0_sq1_adc_pwdn;
   discrete_r(c_DR_SQ1_ADC_PWDN_1)  <= i_c1_sq1_adc_pwdn;
   discrete_r(c_DR_SQ1_ADC_PWDN_2)  <= i_c2_sq1_adc_pwdn;
   discrete_r(c_DR_SQ1_ADC_PWDN_3)  <= i_c3_sq1_adc_pwdn;
   discrete_r(c_DR_SQ1_DAC_SLEEP_0) <= i_c0_sq1_dac_sleep;
   discrete_r(c_DR_SQ1_DAC_SLEEP_1) <= i_c1_sq1_dac_sleep;
   discrete_r(c_DR_SQ1_DAC_SLEEP_2) <= i_c2_sq1_dac_sleep;
   discrete_r(c_DR_SQ1_DAC_SLEEP_3) <= i_c3_sq1_dac_sleep;

   discrete_r(discrete_r'high downto c_DR_S) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser sequence: read command file and write result file
   -- ------------------------------------------------------------------------------------------------------
   P_parser_seq: process
   constant c_ERROR_CAT_NB    : integer   := 5                                                              ; --! Error category number
   variable v_error_cat       : std_logic_vector(c_ERROR_CAT_NB-1 downto 0)                                 ; --! Error category
   alias    v_err_sim_time    : std_logic is v_error_cat(0)                                                 ; --! Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   alias    v_err_chk_dis_r   : std_logic is v_error_cat(1)                                                 ; --! Error check discrete read  ('0' = No error, '1' = Error)
   alias    v_err_chk_cmd_r   : std_logic is v_error_cat(2)                                                 ; --! Error check command return ('0' = No error, '1' = Error)
   alias    v_err_chk_time    : std_logic is v_error_cat(3)                                                 ; --! Error check time           ('0' = No error, '1' = Error)
   alias    v_err_chk_clk_prm : std_logic is v_error_cat(4)                                                 ; --! Error check clocks parameters ('0' = No error, '1' = Error)
   variable v_chk_clk_prm_ena : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Check clock parameters enable

   variable v_line_cnt        : integer                                                                     ; --! Command file line counter
   variable v_head_mess_stdout: line                                                                        ; --! Header message output stream stdout
   variable v_cmd_file_line   : line                                                                        ; --! Command file line
   variable v_fld_cmd         : line                                                                        ; --! Field script command
   variable v_mess_spi_cmd    : line                                                                        ; --! Message SPI command
   variable v_fld_spi_cmd     : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! Field SPI command
   variable v_wait_end        : t_wait_cmd_end                                                              ; --! Wait end
   variable v_fld_dis         : line                                                                        ; --! Field discrete
   variable v_fld_dis_ind     : integer                                                                     ; --! Field discrete index
   variable v_fld_value       : std_logic                                                                   ; --! Field value
   variable v_fld_ope         : line                                                                        ; --! Field operation
   variable v_fld_data        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field data
   variable v_fld_mask        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field mask
   variable v_record_time     : time                                                                        ; --! Record time
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Open Command and Result files
      file_open(cmd_file, c_DIR_CMD_FILE & c_SIM_NAME & c_CMD_FILE_SFX, READ_MODE );
      file_open(res_file, c_DIR_RES_FILE & c_SIM_NAME & c_RES_FILE_SFX, WRITE_MODE);

      -- Result file header
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation " & c_SIM_NAME, res_file);
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

      -- Default value initialization
      discrete_w        <= (others => '0');
      o_brd_ref         <= (others => '0');
      o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(c_EP_CMD_S, o_ep_cmd_ser_wd_s'length));
      o_ep_cmd          <= (others => '0');
      o_ep_cmd_start    <= '0';
      v_error_cat       := (others => '0');
      v_chk_clk_prm_ena := (others => '0');
      v_line_cnt        := 1;
      v_record_time     := 0 ns;

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

                  -- Get parameters
                  get_param_ccmd(v_cmd_file_line, v_head_mess_stdout.all, v_mess_spi_cmd, v_fld_spi_cmd, v_wait_end);

                  wait for c_EP_CLK_PER_DEF;

                  -- Check command return
                  if i_ep_data_rx = v_fld_spi_cmd then
                     fprintf(note , "Check command return: PASS", res_file);

                  else
                     fprintf(error, "Check command return: FAIL", res_file);

                     -- Activate error flag
                     v_err_chk_cmd_r  := '1';

                  end if;

                  -- Display result
                  fprintf(note , " * Read " & hfield_format(i_ep_data_rx).all & ", expected " & v_mess_spi_cmd.all , res_file);

                  if v_wait_end = wait_cmd_end_tx then
                     v_fld_time := now;
                     wait until i_ep_cmd_busy_n = '1' for g_SIM_TIME-now;

                     -- Check the simulation end
                     chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command end", v_err_sim_time, res_file);

                  else
                     null;

                  end if;

               -- ------------------------------------------------------------------------------------------------------
               -- Command CCPE [clock_report]: Enable the display in result file of the report about the check clock parameters
               -- ------------------------------------------------------------------------------------------------------
               when "CCPE" =>

                  -- Get parameters
                  get_param_ccpe(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis, v_fld_dis_ind);

                  -- Update discrete write signal
                  v_chk_clk_prm_ena(v_fld_dis_ind) := '1';

                  -- Display command
                  fprintf(note , "Clock report display activated: " & v_fld_dis.all , res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CDIS [discrete_r] [value]: check discrete input
               -- ------------------------------------------------------------------------------------------------------
               when "CDIS" =>

                  -- Get parameters
                  get_param_cdis(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis, v_fld_dis_ind, v_fld_value);

                  -- Check result
                  if discrete_r(v_fld_dis_ind) = v_fld_value then
                     fprintf(note , "Check discrete level: PASS", res_file);

                  else
                     fprintf(error, "Check discrete level: FAIL", res_file);

                     -- Activate error flag
                     v_err_chk_dis_r := '1';

                  end if;

                  -- Display result
                  fprintf(note , " * Read discrete: " & v_fld_dis.all & ", value " & std_logic'image(discrete_r(v_fld_dis_ind)) & ", expected " & std_logic'image(v_fld_value), res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLE [mask] [ope] [time]: check time between the current time and discrete input(s) last event
               -- ------------------------------------------------------------------------------------------------------
               when "CTLE" =>

                  -- Get parameters
                  get_param_ctle(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis, v_fld_dis_ind, v_fld_ope, v_fld_time);

                  -- Compare time between the current time and discrete input(s) last event
                  cmp_time(v_fld_ope(1 to 2), dis_read_last_event(v_fld_dis_ind), v_fld_time, v_fld_dis.all & " last event" , v_head_mess_stdout.all & "[ope]", v_err_chk_time, res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLR [ope] [time]: check time from the last record time
               -- ------------------------------------------------------------------------------------------------------
               when "CTLR" =>

                  -- Get parameters
                  get_param_ctlr(v_cmd_file_line, v_head_mess_stdout.all, v_fld_ope, v_fld_time);

                  -- Compare time between the current and record time with expected time
                  cmp_time(v_fld_ope(1 to 2), now - v_record_time, v_fld_time, "record time", v_head_mess_stdout.all & "[ope]", v_err_chk_time, res_file);

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

                  -- Get parameters
                  get_param_wait(v_cmd_file_line, v_head_mess_stdout.all, v_fld_time);

                  -- Check the simulation end
                  if v_fld_time > (g_SIM_TIME - now) then
                     wait for (g_SIM_TIME - now);

                  else
                     wait for v_fld_time;

                  end if;

                  -- Check the simulation end
                  chk_sim_end(g_SIM_TIME, v_fld_time, "time", v_err_sim_time, res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMD [cmd] [end]: transmit EP command
               -- ------------------------------------------------------------------------------------------------------
               when "WCMD" =>

                  -- Get parameters
                  get_param_wcmd(v_cmd_file_line, v_head_mess_stdout.all, v_mess_spi_cmd, v_fld_spi_cmd, v_wait_end);

                  -- Display command
                  fprintf(note , "Send SPI command " & v_mess_spi_cmd.all, res_file);

                  -- Send command
                  o_ep_cmd       <= v_fld_spi_cmd;
                  o_ep_cmd_start <= '1';
                  wait for 2 * c_EP_CLK_PER_DEF;
                  o_ep_cmd_start <= '0';

                  -- [end] analysis
                  case v_wait_end is

                     -- Wait the return command end receipt
                     when wait_rcmd_end_rx   =>

                        v_fld_time := now;
                        wait until i_ep_data_rx_rdy = '1' for g_SIM_TIME-now;

                        -- Check the simulation end
                        chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command return end", v_err_sim_time, res_file);

                     -- Wait the command end transmit
                     when wait_cmd_end_tx    =>

                        v_fld_time := now;
                        wait until i_ep_cmd_busy_n = '1' for g_SIM_TIME-now;

                        -- Check the simulation end
                        chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command end", v_err_sim_time, res_file);

                     when others =>
                        null;

                  end case;

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMS [size]: write EP command word size
               -- ------------------------------------------------------------------------------------------------------
               when "WCMS" =>

                  -- Get parameters
                  get_param_wcms_wnbd(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis_ind);

                  -- Update EP command serial word size
                  o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(v_fld_dis_ind, o_ep_cmd_ser_wd_s'length));

                  -- Display command
                  fprintf(note, "Configure SPI command to " & integer'image(v_fld_dis_ind) & " bits size", res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WDIS [discrete_w] [value]: write discrete output
               -- ------------------------------------------------------------------------------------------------------
               when "WDIS" =>

                  -- Get parameters
                  get_param_wdis(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis, v_fld_dis_ind, v_fld_value);

                  -- Update discrete write signal
                  discrete_w(v_fld_dis_ind) <= v_fld_value;

                  -- Display command
                  fprintf(note , "Write discrete: " & v_fld_dis.all & " = " & std_logic'image(v_fld_value), res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WNBD [number]: write board reference number
               -- ------------------------------------------------------------------------------------------------------
               when "WNBD" =>

                  -- Get parameters
                  get_param_wcms_wnbd(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis_ind);

                  -- Update EP command serial word size
                  o_brd_ref <= std_logic_vector(to_unsigned(v_fld_dis_ind, o_brd_ref'length));

                  -- Display command
                  fprintf(note, "Configure board reference number to " & integer'image(v_fld_dis_ind), res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
               -- ------------------------------------------------------------------------------------------------------
               when "WUDI" =>

                  -- Get parameters
                  get_param_wudi(v_cmd_file_line, v_head_mess_stdout.all, v_fld_dis, v_fld_dis_ind, v_fld_value, v_fld_data, v_fld_mask);

                  v_fld_time := now;

                  -- Check if the last field is a discrete
                  if v_fld_dis_ind /= c_DR_S then
                     wait until discrete_r(v_fld_dis_ind) = v_fld_value for g_SIM_TIME-now;

                     -- Check the simulation end
                     chk_sim_end(g_SIM_TIME, now-v_fld_time, "event " & v_fld_dis.all & " = " & std_logic'image(v_fld_value), v_err_sim_time, res_file);

                  else
                     wait until (discrete_r and v_fld_mask) = (v_fld_data and v_fld_mask) for g_SIM_TIME-now;

                     -- Check the simulation end
                     chk_sim_end(g_SIM_TIME, now-v_fld_time, "event, mask " & hfield_format(v_fld_mask).all & ", data " & hfield_format(v_fld_data).all, v_err_sim_time, res_file);

                  end if;

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
         wait for 0 ps;

      end loop;

      -- Wait the simulation end
      if now <= g_SIM_TIME then
         wait for g_SIM_TIME - now;
      end if;

      -- Clocks parameters results
      for k in 0 to c_CE_S-1 loop

         -- Check if clock parameters check is enabled
         if v_chk_clk_prm_ena(k) = '1' then

            -- Write clock parameters check results
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);
            fprintf(none, "Parameters check, clock " & c_CCHK(k).clk_name , res_file);
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);

            -- Check if oscillation on clock when enable inactive parameter is disable
            if c_CCHK(k).chk_osc_en = c_CHK_OSC_DIS then
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(0)) &
               ", inactive parameter (no check)", res_file);

            else
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(0))
               , res_file);

            end if;

            fprintf(none, "Error number of high level clock period timing :            " & integer'image(i_err_chk_rpt(k)(1)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_h), res_file);

            fprintf(none, "Error number of low  level clock period timing :            " & integer'image(i_err_chk_rpt(k)(2)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_l), res_file);

            fprintf(none, "Error number of clock state when enable goes to inactive :  " & integer'image(i_err_chk_rpt(k)(3)) &
            ", expected state:  " & std_logic'image(c_CCHK(k).clk_st_ena), res_file);

            fprintf(none, "Error number of clock state when enable goes to active   :  " & integer'image(i_err_chk_rpt(k)(4)) &
            ", expected state:  " & std_logic'image(not(c_CCHK(k).clk_st_ena)), res_file);

            -- Set possible error
            for j in 0 to c_ERR_N_CLK_CHK_S-1 loop
               if i_err_chk_rpt(k)(j) /= 0 then
                  v_err_chk_clk_prm := '1';
               end if;
            end loop;

         end if;
      end loop;

      -- Result file end
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Error simulation time         : " & std_logic'image(v_err_sim_time),   res_file);
      fprintf(none, "Error check discrete level    : " & std_logic'image(v_err_chk_dis_r),  res_file);
      fprintf(none, "Error check command return    : " & std_logic'image(v_err_chk_cmd_r),  res_file);
      fprintf(none, "Error check time              : " & std_logic'image(v_err_chk_time),   res_file);
      fprintf(none, "Error check clocks parameters : " & std_logic'image(v_err_chk_clk_prm),res_file);

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation time               : " & time'image(now), res_file);

      -- Final test status
      if v_error_cat = std_logic_vector(to_unsigned(0, v_error_cat'length)) then
         fprintf(none, "Simulation status             : PASS", res_file);

      else
         fprintf(none, "Simulation status             : FAIL", res_file);

      end if;

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

      -- Close files
      file_close(cmd_file);
      file_close(res_file);

      wait;

   end process;

end architecture Simulation;
