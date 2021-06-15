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

library std;
use std.textio.all;

entity parser is generic
   (     g_SIM_TIME           : time    := c_SIM_TIME_DEF                                                   ; --! Simulation time
         g_TST_NUM            : string  := c_TST_NUM_DEF                                                      --! Test number
   ); port
   (     o_arst_n             : out    std_logic                                                            ; --! Asynchronous reset ('0' = Active, '1' = Inactive)
         i_clk_ref            : in     std_logic                                                            ; --! Reference Clock
         i_sync               : in     std_logic                                                            ; --! Pixel sequence synchronization (R.E. detected = position sequence to the first pixel)

         i_c0_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 0 - Data
         i_c1_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 1 - Data
         i_c2_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 2 - Data
         i_c3_sq1_dac_data    : in     std_logic_vector(c_SQ1_DAC_DATA_S-1 downto 0)                        ; --! SQUID1 DAC, col. 3 - Data

         i_c0_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 0 - Sleep ('0' = Inactive, '1' = Active)
         i_c1_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 1 - Sleep ('0' = Inactive, '1' = Active)
         i_c2_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 2 - Sleep ('0' = Inactive, '1' = Active)
         i_c3_sq1_dac_sleep   : in     std_logic                                                            ; --! SQUID1 DAC, col. 3 - Sleep ('0' = Inactive, '1' = Active)

         i_d_rst              : in     std_logic                                                            ; --! Internal design: Reset asynchronous assertion, synchronous de-assertion
         i_d_clk              : in     std_logic                                                            ; --! Internal design: System Clock
         i_d_clk_sq1_adc      : in     std_logic                                                            ; --! Internal design: SQUID1 ADC Clock (MSB SQUID1 ADC Clocks vector)
         i_d_clk_sq1_pls_shape: in     std_logic                                                            ; --! Internal design: SQUID1 pulse shaping Clock

         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Receipted data
         i_ep_data_rx_rdy     : in     std_logic                                                            ; --! EP - Receipted data ready ('0' = Not ready, '1' = Ready)
         o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --! EP - Command to send
         o_ep_cmd_start       : out    std_logic                                                            ; --! EP - Start command transmit ('0' = Inactive, '1' = Active)
         i_ep_cmd_busy_n      : in     std_logic                                                            ; --! EP - Command transmit busy ('0' = Busy, '1' = Not Busy)
         o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(2*c_EP_CMD_S+1)-1 downto 0)                 --! EP - Serial word size
   );
end entity parser;

architecture Simulation of parser is
constant c_SIM_NAME           : string    := c_CMD_FILE_ROOT & g_TST_NUM                                    ; --! Simulation name
constant c_ERROR_CAT_NB       : integer   := 4                                                              ; --! Error category number

signal   discrete_r           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete read
signal   discrete_w           : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Discrete write

signal   error_cat            : std_logic_vector(c_ERROR_CAT_NB-1 downto 0)                                 ; --! Error category
alias    err_sim_time         : std_logic is error_cat(0)                                                   ; --! Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
alias    err_chk_dis_r        : std_logic is error_cat(1)                                                   ; --! Error check discrete read  ('0' = No error, '1' = Error)
alias    err_chk_cmd_r        : std_logic is error_cat(2)                                                   ; --! Error check command return ('0' = No error, '1' = Error)
alias    err_chk_time         : std_logic is error_cat(3)                                                   ; --! Error check time           ('0' = No error, '1' = Error)

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
         when  0     => return i_d_rst'last_event;
         when  1     => return i_clk_ref'last_event;
         when  2     => return i_d_clk'last_event;
         when  3     => return i_d_clk_sq1_adc'last_event;
         when  4     => return i_d_clk_sq1_pls_shape'last_event;
         when  5     => return i_ep_cmd_busy_n'last_event;
         when  6     => return i_ep_data_rx_rdy'last_event;
         when others => return i_d_rst'last_event;
      end case;

   end function;

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete read signals association
   -- ------------------------------------------------------------------------------------------------------
   discrete_r(0)        <= i_d_rst;
   discrete_r(1)        <= i_clk_ref;
   discrete_r(2)        <= i_d_clk;
   discrete_r(3)        <= i_d_clk_sq1_adc;
   discrete_r(4)        <= i_d_clk_sq1_pls_shape;
   discrete_r(5)        <= i_ep_cmd_busy_n;
   discrete_r(6)        <= i_ep_data_rx_rdy;

   discrete_r(discrete_r'high downto 7) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Discrete write signals association
   -- ------------------------------------------------------------------------------------------------------
   o_arst_n             <= discrete_w(0);

   -- ------------------------------------------------------------------------------------------------------
   --!   Parser sequence: read command file and write result file
   -- ------------------------------------------------------------------------------------------------------
   P_parser_seq: process
   variable v_line_cnt        : integer   := 1                                                              ; --! Command file line counter
   variable v_head_mess_stdout: line                                                                        ; --! Header message output stream stdout
   variable v_cmd_file_line   : line                                                                        ; --! Command file line
   variable v_fld             : line                                                                        ; --! Field
   variable v_fld2            : line                                                                        ; --! Field 2
   variable v_fld_cmd         : line                                                                        ; --! Field command
   variable v_fld_data        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field data
   variable v_fld_mask        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field mask
   variable v_fld_spi_cmd     : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! Field SPI command
   variable v_fld_integer     : integer                                                                     ; --! Field integer
   variable v_fld_time        : time                                                                        ; --! Field time
   variable v_record_time     : time      := 0 ns                                                           ; --! Record time
   variable v_err_chk_time    : std_logic                                                                   ; --! Error check time ('0' = No error, '1' = Error)
   begin

      -- Open Command and Result files
      file_open(cmd_file, c_DIR_CMD_FILE & c_SIM_NAME & c_CMD_FILE_SFX, READ_MODE );
      file_open(res_file, c_DIR_RES_FILE & c_SIM_NAME & c_RES_FILE_SFX, WRITE_MODE);

      -- Result file header
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation " & c_SIM_NAME, res_file);
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

      -- Default value initialization
      o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(c_EP_CMD_S, o_ep_cmd_ser_wd_s'length));

      -- Errors initialization
      error_cat <= (others => '0');
      o_ep_cmd  <= (others => '0');
      o_ep_cmd_start <= '0';

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

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [cmd], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[cmd]", v_fld_spi_cmd);

                  wait for c_EP_CLK_PER_DEF;

                  -- Check command return
                  if i_ep_data_rx = v_fld_spi_cmd then
                     fprintf(note , "Check command return: PASS", res_file);

                  else
                     fprintf(error, "Check command return: FAIL", res_file);

                     -- Activate error flag
                     err_chk_cmd_r  <= '1';

                  end if;

                  -- Display result
                  hfield_format(i_ep_data_rx, v_fld);
                  hfield_format(v_fld_spi_cmd, v_fld2);
                  fprintf(note , " * Read " & v_fld.all & ", expected " & v_fld2.all , res_file);

                  -- Get [end] field
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[end]", 1, v_fld);

                  case v_fld(1 to 1) is

                     -- Wait the command end
                     when "W"|"w"   =>

                        v_fld_time := now;
                        wait until i_ep_cmd_busy_n = '1' for g_SIM_TIME-now;

                        -- Check the simulation end
                        chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command end", v_err_chk_time, res_file);

                        if v_err_chk_time = '1' then
                           err_sim_time <= '1';
                           exit;
                        end if;

                     -- To do nothing
                     when "N"|"n"   =>
                        null;

                     when others =>
                        assert v_fld = null report v_head_mess_stdout.all & "[end]" & c_MESS_ERR_UNKNOWN severity failure;

                  end case;

               -- ------------------------------------------------------------------------------------------------------
               -- Command CDIS [mask] [data]: check discrete inputs
               -- ------------------------------------------------------------------------------------------------------
               when "CDIS" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [mask] and [data], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[mask]", v_fld_mask);
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[data]", v_fld_data);

                  -- Check result
                  if (discrete_r and v_fld_mask) = (v_fld_data and v_fld_mask) then
                     fprintf(note , "Check discrete level: PASS", res_file);

                  else
                     fprintf(error, "Check discrete level: FAIL", res_file);

                     -- Activate error flag
                     err_chk_dis_r  <= '1';

                  end if;

                  -- Display result
                  hfield_format(discrete_r and v_fld_mask, v_fld);
                  hfield_format(v_fld_data and v_fld_mask, v_fld2);
                  fprintf(note , " * Read " & v_fld.all & ", expected " & v_fld2.all , res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLE [mask] [ope] [time]: check time between the current time and discrete input(s) last event
               -- ------------------------------------------------------------------------------------------------------
               when "CTLE" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [mask], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[mask]", v_fld_mask);

                  -- Get [ope] and [time]
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[ope]", 0, v_fld);
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[time]", v_fld_time);

                  -- Select discrete signals
                  for i in 0 to v_fld_mask'high loop
                     if v_fld_mask(i) = '1' then

                        -- Compare time between the current time and discrete input(s) last event
                        cmp_time(v_fld(1 to 2), dis_read_last_event(i), v_fld_time, "discrete read ("& integer'image(i) &") last event" , v_head_mess_stdout.all & "[ope]", v_err_chk_time, res_file);

                        -- Activate error flag
                        if v_err_chk_time = '1' then
                           err_chk_time <= '1';
                        end if;

                     end if;
                  end loop;

               -- ------------------------------------------------------------------------------------------------------
               -- Command CTLR [ope] [time]: check time from the last record time
               -- ------------------------------------------------------------------------------------------------------
               when "CTLR" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [ope] and [time]
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[ope]", 0, v_fld);
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[time]", v_fld_time);

                  -- Compare time between the current and record time with expected time
                  cmp_time(v_fld(1 to 2), now - v_record_time, v_fld_time, "record time", v_head_mess_stdout.all & "[ope]", v_err_chk_time, res_file);

                  -- Activate error flag
                  if v_err_chk_time = '1' then
                     err_chk_time <= '1';
                  end if;

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

                  -- Get [time]
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[time]", v_fld_time);

                  -- Check the simulation end
                  if v_fld_time > (g_SIM_TIME - now) then
                     wait for (g_SIM_TIME - now);

                  else
                     wait for v_fld_time;

                  end if;

                  -- Check the simulation end
                  chk_sim_end(g_SIM_TIME, v_fld_time, "time", v_err_chk_time, res_file);

                  if v_err_chk_time = '1' then
                     err_sim_time <= '1';
                     exit;
                  end if;

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMD [cmd] [end]: transmit EP command
               -- ------------------------------------------------------------------------------------------------------
               when "WCMD" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [cmd], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[cmd]", v_fld_spi_cmd);
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[end]", 1, v_fld);

                  -- Display command
                  hfield_format(v_fld_spi_cmd, v_fld2);
                  fprintf(note , "Send SPI command " & v_fld2.all, res_file);

                  -- Send command
                  o_ep_cmd       <= v_fld_spi_cmd;
                  o_ep_cmd_start <= '1';
                  wait for 2*c_EP_CLK_PER_DEF;
                  o_ep_cmd_start <= '0';

                  -- [end] analysis
                  case v_fld(1 to 1) is

                     -- Wait the command end
                     when "R"|"r"   =>

                        v_fld_time := now;
                        wait until i_ep_data_rx_rdy = '1' for g_SIM_TIME-now;

                        -- Check the simulation end
                        chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command return end", v_err_chk_time, res_file);

                        if v_err_chk_time = '1' then
                           err_sim_time <= '1';
                           exit;
                        end if;

                     -- Wait the command end
                     when "W"|"w"   =>

                        v_fld_time := now;
                        wait until i_ep_cmd_busy_n = '1' for g_SIM_TIME-now;

                        -- Check the simulation end
                        chk_sim_end(g_SIM_TIME, now-v_fld_time, "SPI command end", v_err_chk_time, res_file);

                        if v_err_chk_time = '1' then
                           err_sim_time <= '1';
                           exit;
                        end if;

                     -- To do nothing
                     when "N"|"n"   =>
                        null;

                     when others =>
                        assert v_fld = null report v_head_mess_stdout.all & "[end]" & c_MESS_ERR_UNKNOWN severity failure;

                  end case;

               -- ------------------------------------------------------------------------------------------------------
               -- Command WCMS [size]: write EP command word size
               -- ------------------------------------------------------------------------------------------------------
               when "WCMS" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [size], hex format
                  rfield(v_cmd_file_line, v_head_mess_stdout.all & "[size]", v_fld_integer);

                  -- Update EP command serial word size
                  o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(v_fld_integer, o_ep_cmd_ser_wd_s'length));

                  -- Display command
                  fprintf(note, "Configure SPI command to " & integer'image(v_fld_integer) & " bits size", res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WDIS [mask] [data]: write discrete output(s)
               -- ------------------------------------------------------------------------------------------------------
               when "WDIS" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [mask] and [data], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[mask]", v_fld_mask);
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[data]", v_fld_data);

                  -- Update discrete write signals
                  for i in v_fld_data'range loop
                     if v_fld_mask(i) = '1' then
                        discrete_w(i) <= v_fld_data(i);

                     end if;
                  end loop;

                  -- Display command
                  hfield_format(v_fld_mask, v_fld);
                  hfield_format(v_fld_data, v_fld2);
                  fprintf(note , "Write discrete : mask " & v_fld.all & ", data " & v_fld2.all, res_file);

               -- ------------------------------------------------------------------------------------------------------
               -- Command WUDI [mask] [data]: wait until event on discrete
               -- ------------------------------------------------------------------------------------------------------
               when "WUDI" =>

                  -- Drop underscore included in the fields
                  drop_line_char(v_cmd_file_line, '_', v_cmd_file_line);

                  -- Get [mask] and [data], hex format
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[mask]", v_fld_mask);
                  hrfield(v_cmd_file_line, v_head_mess_stdout.all & "[data]", v_fld_data);

                  v_fld_time := now;
                  wait until (discrete_r and v_fld_mask) = (v_fld_data and v_fld_mask) for g_SIM_TIME-now;

                  -- Check the simulation end
                  hfield_format(v_fld_mask, v_fld);
                  hfield_format(v_fld_data, v_fld2);
                  chk_sim_end(g_SIM_TIME, now-v_fld_time, "event, mask " & v_fld.all & ", data " & v_fld2.all, v_err_chk_time, res_file);

                  if v_err_chk_time = '1' then
                     err_sim_time <= '1';
                     exit;
                  end if;

               -- ------------------------------------------------------------------------------------------------------
               -- Command unknown
               -- ------------------------------------------------------------------------------------------------------
               when others =>
                  assert v_fld_cmd = null report v_head_mess_stdout.all & "[cmd]" & c_MESS_ERR_UNKNOWN severity failure;

            end case;

         end if;

         -- Update line counter
         v_line_cnt := v_line_cnt + 1;

      end loop;

      -- Wait the simulation end
      if now <= g_SIM_TIME then
         wait for g_SIM_TIME - now;
      end if;

      -- Result file end
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Error simulation time         : " & std_logic'image(err_sim_time),   res_file);
      fprintf(none, "Error check discrete level    : " & std_logic'image(err_chk_dis_r),  res_file);
      fprintf(none, "Error check command return    : " & std_logic'image(err_chk_cmd_r),  res_file);
      fprintf(none, "Error check time              : " & std_logic'image(err_chk_time),   res_file);

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation time               : " & time'image(now), res_file);

      -- Final test status
      if error_cat = std_logic_vector(to_unsigned(0, error_cat'length)) then
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
