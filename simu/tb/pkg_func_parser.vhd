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
--!   @file                   pkg_func_parser.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package function command parser
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;
use     work.pkg_str_fld_assoc.all;
use     work.pkg_func_cmd_script.all;

library std;
use std.textio.all;

package pkg_func_parser is

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ccmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_ep_cmd_busy_n      : in     std_logic                                                            ; --  EP Command transmit busy ('0' = Busy, '1' = Not Busy)
         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --  EP Receipted data
         i_sim_time           : in     time                                                                 ; --  Simulation time
         b_err_chk_cmd_r      : inout  std_logic                                                            ; --  Error check command return ('0' = No error, '1' = Error)
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CCPE [report]: enable the display in result file of the report
   --!  about the check parameters
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ccpe (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         b_chk_rpt_prm_ena    : inout  std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                     --  Check report parameters enable
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_discrete_r         : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --  Discrete read
         b_err_chk_dis_r      : inout  std_logic                                                              --  Error check discrete read  ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CLDC [channel] [value]: check level SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cldc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sqm_adc_ana        : in     real_vector(0 to c_NB_COL-1)                                         ; --  SQUID MUX ADC: Analog
         b_err_chk_dis_r      : inout  std_logic                                                              --  Error check discrete read  ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CSCP [science_packet] : check the science packet type
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cscp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sc_pkt_type        : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science packet type
         b_err_chk_sc_pkt     : inout  std_logic                                                              --  Error check science packet ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTDC [channel] [ope] [time]: check time between the current time
   --!  and last event SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_sqm_adc_ana_lst_ev : in     time_vector(0 to c_NB_COL-1)                                         ; --  SQUID MUX ADC: Analog last event time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTLE [discrete_r] [ope] [time]: check time between the current time
   --!  and discrete input last event
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctle (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_discrete_r_lst_ev  : time_vector(0 to c_CMD_FILE_FLD_DATA_S-1)                                   ; --  Discrete read last event time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctlr (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_record_time        : in     time                                                                 ; --  Record time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wait (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WCMD [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wcmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_ep_data_rx_rdy     : in     std_logic                                                            ; --  EP Receipted data ready ('0' = Not ready, '1' = Ready)
signal   o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --  EP Command to send
signal   o_ep_cmd_start       : out    std_logic                                                            ; --  EP Start command transmit ('0' = Inactive, '1' = Active)
signal   i_ep_cmd_busy_n      : in     std_logic                                                            ; --  EP Command transmit busy ('0' = Busy, '1' = Not Busy)
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WCMS [size]: write EP command word size or
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wcms (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(c_SER_WD_MAX_S+1)-1 downto 0)               --  EP Serial word size
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_discrete_w         : out    std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                     --  Discrete write
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WFMP [channel] [data]: write FPASIM "Make pulse" command
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wfmp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_fpa_cmd_rdy        : in     std_logic_vector(        c_NB_COL-1 downto 0)                        ; --! FPASIM command ready ('0' = No, '1' = Yes)
signal   o_fpa_cmd            : out    t_slv_arr(0 to c_NB_COL-1)(c_FPA_CMD_S-1 downto 0)                   ; --! FPASIM command
signal   o_fpa_cmd_valid      : out    std_logic_vector(        c_NB_COL-1 downto 0)                          --! FPASIM command valid ('0' = No, '1' = Yes)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WMDC [channel] [frame] [index] [data]:
   --!  Write in ADC dump/science memories for data compare
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wmdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_adc_dmp_mem_add    : out    std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                        ; --  ADC Dump memory for data compare: address
signal   o_adc_dmp_mem_data   : out    std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --  ADC Dump memory for data compare: data
signal   o_science_mem_data   : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --  Science  memory for data compare: data
signal   o_adc_dmp_mem_cs     : out    std_logic_vector(        c_NB_COL-1 downto 0)                          --  ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WNBD [number]: write board reference number
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wnbd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                             --  Board reference
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser WPFC [channel] [frequency]: write pulse shaping cut frequency for verification
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wpfc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_pls_shp_fc         : out    integer_vector(0 to c_NB_COL-1)                                        --  Pulse shaping cut frequency (Hz)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wudi (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_discrete_r         : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --  Discrete read
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   );

end pkg_func_parser;

package body pkg_func_parser is

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ccmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_ep_cmd_busy_n      : in     std_logic                                                            ; --  EP Command transmit busy ('0' = Busy, '1' = Not Busy)
         i_ep_data_rx         : in     std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --  EP Receipted data
         i_sim_time           : in     time                                                                 ; --  Simulation time
         b_err_chk_cmd_r      : inout  std_logic                                                            ; --  Error check command return ('0' = No error, '1' = Error)
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   ) is
   variable v_mess_spi_cmd    : line                                                                        ; --! Message SPI command
   variable v_fld_spi_cmd     : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! Field SPI command
   variable v_wait_end        : t_wait_cmd_end                                                              ; --! Wait end
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Parser command
      get_param_ccmd(b_cmd_file_line, i_mess_header, v_mess_spi_cmd, v_fld_spi_cmd, v_wait_end);

      wait for c_EP_CLK_PER_DEF;

      -- Check command return
      if i_ep_data_rx = v_fld_spi_cmd then
         fprintf(note , "Check command return: PASS", res_file);

      else
         fprintf(error, "Check command return: FAIL", res_file);

         -- Activate error flag
         b_err_chk_cmd_r  := c_HGH_LEV;

      end if;

      -- Display result
      fprintf(note , " * Read " & hfield_format(i_ep_data_rx).all & ", expected " & v_mess_spi_cmd.all , res_file);

      if v_wait_end = wait_cmd_end_tx then
         v_fld_time := now;
         wait until i_ep_cmd_busy_n = c_HGH_LEV for i_sim_time-now;

         -- Check the simulation end
         chk_sim_end(i_sim_time, now-v_fld_time, "SPI command end", b_err_sim_time, res_file);

      else
         null;

      end if;

   end parser_cmd_ccmd;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CCPE [report]: enable the display in result file of the report
   --!  about the check parameters
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ccpe (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         b_chk_rpt_prm_ena    : inout  std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                     --  Check report parameters enable
   ) is
   variable v_fld_ce          : line                                                                        ; --! Field check clock parameters enable
   variable v_fld_ce_ind      : integer range 0 to c_CE_S-1                                                 ; --! Field check clock parameters enable index (equal to c_CE_S if field not recognized)
   begin

      -- Get parameters
      get_param_ccpe(b_cmd_file_line, i_mess_header, v_fld_ce, v_fld_ce_ind);

      -- Update discrete write signal
      b_chk_rpt_prm_ena(v_fld_ce_ind) := c_HGH_LEV;

      -- Display command
      fprintf(note , "Report display activated: " & v_fld_ce.all , res_file);

   end parser_cmd_ccpe;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_discrete_r         : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --  Discrete read
         b_err_chk_dis_r      : inout  std_logic                                                              --  Error check discrete read  ('0' = No error, '1' = Error)
   ) is
   variable v_fld_dr          : line                                                                        ; --! Field discrete input
   variable v_fld_dr_ind      : integer range 0 to c_DR_S                                                   ; --! Field discrete input index (equal to c_DR_S if field not recognized)
   variable v_fld_value       : std_logic                                                                   ; --! Field value
   begin

      -- Get parameters
      get_param_cdis(b_cmd_file_line, i_mess_header, v_fld_dr, v_fld_dr_ind, v_fld_value);

      -- Check result
      if i_discrete_r(v_fld_dr_ind) = v_fld_value then
         fprintf(note , "Check discrete level: PASS", res_file);

      else
         fprintf(error, "Check discrete level: FAIL", res_file);

         -- Activate error flag
         b_err_chk_dis_r := c_HGH_LEV;

      end if;

      -- Display result
      fprintf(note , " * Read discrete: " & v_fld_dr.all & ", value " & std_logic'image(i_discrete_r(v_fld_dr_ind)) & ", expected " & std_logic'image(v_fld_value), res_file);

   end parser_cmd_cdis;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CLDC [channel] [value]: check level SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cldc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sqm_adc_ana        : in     real_vector(0 to c_NB_COL-1)                                         ; --  SQUID MUX ADC: Analog
         b_err_chk_dis_r      : inout  std_logic                                                              --  Error check discrete read  ('0' = No error, '1' = Error)
   ) is
   variable v_fld_channel     : integer range 0 to c_NB_COL-1                                               ; --! Field channel number
   variable v_fld_value       : real                                                                        ; --! Field value
   begin

      -- Get parameters
      get_param_cldc(b_cmd_file_line, i_mess_header, v_fld_channel, v_fld_value);

      -- Check result
      if ((i_sqm_adc_ana(v_fld_channel) - v_fld_value) <= c_SQM_ADC_ERR_VAL) and ((i_sqm_adc_ana(v_fld_channel) - v_fld_value) >= - c_SQM_ADC_ERR_VAL) then
         fprintf(note , "Check ADC level: PASS", res_file);

      else
         fprintf(error, "Check ADC level: FAIL", res_file);

         -- Activate error flag
         b_err_chk_dis_r := c_HGH_LEV;

      end if;

      -- Display result
      fprintf(note , " * Read ADC channel " & integer'image(v_fld_channel) & ", value " & real'image(i_sqm_adc_ana(v_fld_channel)) & ", expected " & real'image(v_fld_value), res_file);

   end parser_cmd_cldc;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CSCP [science_packet] : check the science packet type
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_cscp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sc_pkt_type        : in     std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --  Science packet type
         b_err_chk_sc_pkt     : inout  std_logic                                                              --  Error check science packet ('0' = No error, '1' = Error)
   ) is
   variable v_fld_sc_pkt      : line                                                                        ; --! Field science packet type
   variable v_fld_sc_pkt_val  : std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                              ; --! Field science packet type value
   begin

      -- Get parameters
      get_param_cscp(b_cmd_file_line, i_mess_header, v_fld_sc_pkt, v_fld_sc_pkt_val);

      -- Check result
      if v_fld_sc_pkt_val = i_sc_pkt_type then
         fprintf(note , "Check science packet type: PASS", res_file);

      else
         fprintf(error, "Check science packet type: FAIL", res_file);

         -- Activate error flag
         b_err_chk_sc_pkt := c_HGH_LEV;

      end if;

      -- Display result
      fprintf(note , " * Science packet type: " & v_fld_sc_pkt.all & ", value " & to_string(i_sc_pkt_type) & ", expected " & to_string(v_fld_sc_pkt_val), res_file);

   end parser_cmd_cscp;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTDC [channel] [ope] [time]: check time between the current time
   --!  and last event SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_sqm_adc_ana_lst_ev : in     time_vector(0 to c_NB_COL-1)                                         ; --  SQUID MUX ADC: Analog last event time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   ) is
   variable v_fld_channel     : integer range 0 to c_NB_COL-1                                               ; --! Field channel number
   variable v_fld_ope         : line                                                                        ; --! Field operation
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_ctdc(b_cmd_file_line, i_mess_header, v_fld_channel, v_fld_ope, v_fld_time);

      -- Compare time between the current time and SQUID MUX ADC output last event
      cmp_time(v_fld_ope(c_ONE_INT to c_OPE_CMP_S), now - i_sqm_adc_ana_lst_ev(v_fld_channel), v_fld_time, "ADC channel " & integer'image(v_fld_channel) & " last event" ,
               i_mess_header & "[ope]", b_err_chk_time, res_file);

   end parser_cmd_ctdc;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTLE [discrete_r] [ope] [time]: check time between the current time
   --!  and discrete input last event
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctle (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   i_discrete_r_lst_ev  : time_vector(0 to c_CMD_FILE_FLD_DATA_S-1)                                   ; --  Discrete read last event time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   ) is
   variable v_fld_dr          : line                                                                        ; --! Field discrete input
   variable v_fld_dr_ind      : integer range 0 to c_DR_S                                                   ; --! Field discrete input index (equal to c_DR_S if field not recognized)
   variable v_fld_ope         : line                                                                        ; --! Field operation
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_ctle(b_cmd_file_line, i_mess_header, v_fld_dr, v_fld_dr_ind, v_fld_ope, v_fld_time);

      -- Compare time between the current time and discrete input(s) last event
      cmp_time(v_fld_ope(c_ONE_INT to c_OPE_CMP_S), now - i_discrete_r_lst_ev(v_fld_dr_ind), v_fld_time, v_fld_dr.all & " last event" , i_mess_header & "[ope]", b_err_chk_time, res_file);

   end parser_cmd_ctle;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_ctlr (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_record_time        : in     time                                                                 ; --  Record time
         b_err_chk_time       : inout  std_logic                                                              --  Error check time           ('0' = No error, '1' = Error)
   ) is
   variable v_fld_ope         : line                                                                        ; --! Field operation
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_ctlr(b_cmd_file_line, i_mess_header, v_fld_ope, v_fld_time);

      -- Compare time between the current and record time with expected time
      cmp_time(v_fld_ope(c_ONE_INT to c_OPE_CMP_S), now - i_record_time, v_fld_time, "record time", i_mess_header & "[ope]", b_err_chk_time, res_file);

   end parser_cmd_ctlr;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wait (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   ) is
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_wait(b_cmd_file_line, i_mess_header, v_fld_time);

      -- Check the simulation end
      if v_fld_time > (i_sim_time - now) then
         wait for (i_sim_time - now);

      else
         wait for v_fld_time;

      end if;

      -- Check the simulation end
      chk_sim_end(i_sim_time, v_fld_time, "time", b_err_sim_time, res_file);

   end parser_cmd_wait;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WCMD [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wcmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_ep_data_rx_rdy     : in     std_logic                                                            ; --  EP Receipted data ready ('0' = Not ready, '1' = Ready)
signal   o_ep_cmd             : out    std_logic_vector(c_EP_CMD_S-1 downto 0)                              ; --  EP Command to send
signal   o_ep_cmd_start       : out    std_logic                                                            ; --  EP Start command transmit ('0' = Inactive, '1' = Active)
signal   i_ep_cmd_busy_n      : in     std_logic                                                            ; --  EP Command transmit busy ('0' = Busy, '1' = Not Busy)
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   ) is
   constant c_EP_START_DEL    : time := 2 * c_EP_CLK_PER_DEF                                                ; --! EP start delay

   variable v_mess_spi_cmd    : line                                                                        ; --! Message SPI command
   variable v_fld_spi_cmd     : std_logic_vector(c_EP_CMD_S-1 downto 0)                                     ; --! Field SPI command
   variable v_wait_end        : t_wait_cmd_end                                                              ; --! Wait command end
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_wcmd(b_cmd_file_line, i_mess_header, v_mess_spi_cmd, v_fld_spi_cmd, v_wait_end);

      -- Display command
      fprintf(note , "Send SPI command " & v_mess_spi_cmd.all, res_file);

      -- Send command
      o_ep_cmd       <= v_fld_spi_cmd;
      o_ep_cmd_start <= c_HGH_LEV;
      wait for c_EP_START_DEL;
      o_ep_cmd_start <= c_LOW_LEV;

      -- [end] analysis
      case v_wait_end is

         -- Wait the return command end receipt
         when wait_rcmd_end_rx   =>

            v_fld_time := now;
            wait until i_ep_data_rx_rdy = c_HGH_LEV for i_sim_time-now;

            -- Check the simulation end
            chk_sim_end(i_sim_time, now-v_fld_time, "SPI command return end", b_err_sim_time, res_file);

         -- Wait the command end transmit
         when wait_cmd_end_tx    =>

            v_fld_time := now;
            wait until i_ep_cmd_busy_n = c_HGH_LEV for i_sim_time-now;

            -- Check the simulation end
            chk_sim_end(i_sim_time, now-v_fld_time, "SPI command end", b_err_sim_time, res_file);

         when others =>
            null;

      end case;

   end parser_cmd_wcmd;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WCMS [size]: write EP command word size or
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wcms (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_ep_cmd_ser_wd_s    : out    std_logic_vector(log2_ceil(c_SER_WD_MAX_S+1)-1 downto 0)               --  EP Serial word size
   ) is
   variable v_fld_integer     : integer                                                                     ; --! Field integer
   begin

      -- Get parameters
      get_param_wcms_wnbd(b_cmd_file_line, i_mess_header, v_fld_integer);

      -- Update EP command serial word size
      o_ep_cmd_ser_wd_s <= std_logic_vector(to_unsigned(v_fld_integer, o_ep_cmd_ser_wd_s'length));

      -- Display command
      fprintf(note, "Configure SPI command to " & integer'image(v_fld_integer) & " bits size", res_file);

   end parser_cmd_wcms;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_discrete_w         : out    std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                     --  Discrete write
   ) is
   variable v_fld_dw          : line                                                                        ; --! Field discrete output
   variable v_fld_dw_ind      : integer range 0 to c_DW_S                                                   ; --! Field discrete output index (equal to c_DW_S if field not recognized)
   variable v_fld_value       : std_logic                                                                   ; --! Field value
   begin

      -- Get parameters
      get_param_wdis(b_cmd_file_line, i_mess_header, v_fld_dw, v_fld_dw_ind, v_fld_value);

      -- Update discrete write signal
      o_discrete_w(v_fld_dw_ind) <= v_fld_value;

      -- Display command
      fprintf(note , "Write discrete: " & v_fld_dw.all & " = " & std_logic'image(v_fld_value), res_file);

   end parser_cmd_wdis;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WFMP [channel] [data]: write FPASIM "Make pulse" command
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wfmp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_fpa_cmd_rdy        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --! FPASIM command ready ('0' = No, '1' = Yes)
signal   o_fpa_cmd            : out    t_slv_arr(0 to c_NB_COL-1)(c_FPA_CMD_S-1 downto 0)                   ; --! FPASIM command
signal   o_fpa_cmd_valid      : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! FPASIM command valid ('0' = No, '1' = Yes)
   ) is
   constant c_FPA_CMD_VLD_DEL : time := 2 * c_CLK_FPA_PER_DEF                                               ; --! FPASIM command valid delay

   variable v_fld_channel     : integer range 0 to c_NB_COL-1                                               ; --! Field channel number
   variable v_fld_data        : std_logic_vector(c_FPA_CMD_S-1 downto 0)                                    ; --! Field data
   begin

      -- Get parameters
      get_param_wfmp(b_cmd_file_line, i_mess_header, v_fld_channel, v_fld_data);

      -- Display command
      fprintf(note , "Send FPASIM Make pulse command, data: " & hfield_format(v_fld_data).all, res_file);

      -- Send command
      if i_fpa_cmd_rdy(v_fld_channel) /= c_HGH_LEV then
         wait until i_fpa_cmd_rdy(v_fld_channel) = c_HGH_LEV for i_sim_time-now;

      end if;

      o_fpa_cmd(v_fld_channel)       <= v_fld_data;
      o_fpa_cmd_valid(v_fld_channel) <= c_HGH_LEV;
      wait for c_FPA_CMD_VLD_DEL;
      o_fpa_cmd_valid(v_fld_channel) <= c_LOW_LEV;

   end parser_cmd_wfmp;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WMDC [channel] [index] [data]:
   --!  Write in ADC dump/science memories for data compare
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wmdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_adc_dmp_mem_add    : out    std_logic_vector(  c_MEM_SC_ADD_S-1 downto 0)                        ; --  ADC Dump memory for data compare: address
signal   o_adc_dmp_mem_data   : out    std_logic_vector(c_SQM_ADC_DATA_S+1 downto 0)                        ; --  ADC Dump memory for data compare: data
signal   o_science_mem_data   : out    std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)      ; --  Science  memory for data compare: data
signal   o_adc_dmp_mem_cs     : out    std_logic_vector(        c_NB_COL-1 downto 0)                          --  ADC Dump memory for data compare: chip select ('0' = Inactive, '1' = Active)
   ) is
   variable v_fld_channel     : integer range 0 to c_NB_COL-1                                               ; --! Field channel number
   variable v_fld_frame       : integer range 0 to c_MEM_SC_FRM_NB-1                                        ; --! Field frame number
   variable v_fld_index       : integer range 0 to c_MUX_FACT-1                                             ; --! Field memory index number
   variable v_fld_data        : std_logic_vector(2*c_EP_SPI_WD_S-1 downto 0)                                ; --! Field data
   begin

      -- Get parameters
      get_param_wmdc(b_cmd_file_line, i_mess_header, v_fld_channel, v_fld_frame, v_fld_index, v_fld_data);

      -- Display command
      fprintf(note , "Write in ADC dump and science memories column " & integer'image(v_fld_channel) & ", frame number " & integer'image(v_fld_frame) &
                     ", adress index " & integer'image(v_fld_index) & ", ADC dump & Science value " & hfield_format(v_fld_data).all, res_file);

      -- Write in ADC dump/science memories
      o_adc_dmp_mem_add    <= std_logic_vector(to_unsigned(c_MUX_FACT * v_fld_frame + v_fld_index, o_adc_dmp_mem_add'length));
      o_adc_dmp_mem_data   <= std_logic_vector(resize(unsigned(v_fld_data(  c_EP_CMD_S   -1 downto c_EP_SPI_WD_S)), o_adc_dmp_mem_data'length));
      o_science_mem_data   <= std_logic_vector(resize(unsigned(v_fld_data(  c_EP_SPI_WD_S-1 downto 0)), o_science_mem_data'length));
      o_adc_dmp_mem_cs(v_fld_channel)  <= c_HGH_LEV;
      wait for c_CLK_REF_PER_DEF;
      o_adc_dmp_mem_cs(v_fld_channel)  <= c_LOW_LEV;

   end parser_cmd_wmdc;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser WNBD [number]: write board reference number
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wnbd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_brd_ref            : out    std_logic_vector(  c_BRD_REF_S-1 downto 0)                             --  Board reference
   ) is
   variable v_fld_integer     : integer                                                                     ; --! Field integer
   begin

      -- Get parameters
      get_param_wcms_wnbd(b_cmd_file_line, i_mess_header, v_fld_integer);

      -- Update EP command serial word size
      o_brd_ref <= std_logic_vector(to_unsigned(v_fld_integer, o_brd_ref'length));

      -- Display command
      fprintf(note, "Configure board reference number to " & integer'image(v_fld_integer), res_file);

   end parser_cmd_wnbd;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser WPFC [channel] [frequency]: write pulse shaping cut frequency for verification
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wpfc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

signal   o_pls_shp_fc         : out    integer_vector(0 to c_NB_COL-1)                                        --  Pulse shaping cut frequency (Hz)
   ) is
   variable v_fld_channel     : integer range 0 to c_NB_COL-1                                               ; --! Field channel number
   variable v_fld_frequency   : integer                                                                     ; --! Field frequency cut (Hz)
   begin

      -- Get parameters
      get_param_wpfc(b_cmd_file_line, i_mess_header, v_fld_channel, v_fld_frequency);

      -- Update pulse shaping cut frequency
      o_pls_shp_fc(v_fld_channel) <= v_fld_frequency;

      -- Display command
      fprintf(note, "Configure pulse shaping cut frequency channel " & integer'image(v_fld_channel) & " to " & integer'image(v_fld_frequency) & "Hz", res_file);

   end parser_cmd_wpfc;

   -- ------------------------------------------------------------------------------------------------------
   --! Parser command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
   -- ------------------------------------------------------------------------------------------------------
   procedure parser_cmd_wudi (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
file     res_file             :        text                                                                 ; --  Result file

         i_sim_time           : in     time                                                                 ; --  Simulation time
signal   i_discrete_r         : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --  Discrete read
         b_err_sim_time       : inout  std_logic                                                              --  Error simulation time ('0' = No error, '1' = Error: Simulation time not long enough)
   ) is
   variable v_fld_dr          : line                                                                        ; --! Field discrete input
   variable v_fld_dr_ind      : integer range 0 to c_DR_S                                                   ; --! Field discrete input index (equal to c_DR_S if field not recognized)
   variable v_fld_value       : std_logic                                                                   ; --! Field value
   variable v_fld_data        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field data
   variable v_fld_mask        : std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                          ; --! Field mask
   variable v_fld_time        : time                                                                        ; --! Field time
   begin

      -- Get parameters
      get_param_wudi(b_cmd_file_line, i_mess_header, v_fld_dr, v_fld_dr_ind, v_fld_value, v_fld_data, v_fld_mask);

      v_fld_time := now;

      -- Check if the last field is a discrete
      if v_fld_dr_ind /= c_DR_S then
         wait until i_discrete_r(v_fld_dr_ind) = v_fld_value for i_sim_time-now;

         -- Check the simulation end
         chk_sim_end(i_sim_time, now-v_fld_time, "event " & v_fld_dr.all & " = " & std_logic'image(v_fld_value), b_err_sim_time, res_file);

      else
         wait until (i_discrete_r and v_fld_mask) = (v_fld_data and v_fld_mask) for i_sim_time-now;

         -- Check the simulation end
         chk_sim_end(i_sim_time, now-v_fld_time, "event, mask " & hfield_format(v_fld_mask).all & ", data " & hfield_format(v_fld_data).all, b_err_sim_time, res_file);

      end if;

   end parser_cmd_wudi;

end package body pkg_func_parser;
