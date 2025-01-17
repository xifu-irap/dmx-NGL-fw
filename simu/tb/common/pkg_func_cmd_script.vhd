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
--!   @file                   pkg_func_cmd_script.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package function command script
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;
use     work.pkg_str_fld_assoc.all;
use     work.pkg_func_cmd_spi.all;

library std;
use std.textio.all;

package pkg_func_cmd_script is

type     t_wait_cmd_end         is (none, wait_cmd_end_tx, wait_rcmd_end_rx)                                ; --! Wait command end type

   -- ------------------------------------------------------------------------------------------------------
   --! Compare time and write result in file output
   -- ------------------------------------------------------------------------------------------------------
   procedure cmp_time (
         i_ope                : in     string(1 to c_OPE_CMP_S)                                             ; --  Operator
         i_time_left          : in     time                                                                 ; --  Time left  operator
         i_time_right         : in     time                                                                 ; --  Time right operator
         i_mess_header        : in     string                                                               ; --  Message header
         i_mess_header_assert : in     string                                                               ; --  Message header assaert
         b_err_chk_time       : inout  std_logic                                                            ; --  Error check time
         file file_out        : text                                                                          --  File output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Check simulation end reached
   -- ------------------------------------------------------------------------------------------------------
   procedure chk_sim_end (
         i_sim_time           : in     time                                                                 ; --  Simulation time
         i_wait_time          : in     time                                                                 ; --  Waiting time
         i_mess_event         : in     string                                                               ; --  Message Event
         o_err_sim_time       : out    std_logic                                                            ; --  Error simulation time
         file file_out        : text                                                                          --  File output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCPE [report]: enable the display in result file of the report
   --!  about the check parameters
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccpe (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ce             : out    line                                                                 ; --  Field check clock parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S-1                                            --  Field check clock parameters enable index (equal to c_CE_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CLDC [channel] [value]: check level SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cldc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_value          : out    real                                                                   --  Field value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CSCP [science_ctrl_pos] [science_packet] : check the science packet type
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cscp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_sc_ctrl_pos    : out    integer range 0 to c_SC_PKT_W_NB-1                                   ; --  Field science control position
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector                                                       --  Field science packet type value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTDC [channel] [ope] [time]: check time between the current time
   --!  and last event SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLE [discrete_r] [ope] [time]: check time between the current time
   --!  and discrete input last event
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctle (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctlr (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wait (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WCMD [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WCMS [size]: write EP command word size or
   --! Get parameters command WNBD [number]: write board reference number
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcms_wnbd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_integer        : out    integer                                                                --  Field integer
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                            ; --  Field discrete output index (equal to c_DW_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WFMP [channel] [data]: write FPASIM "Make pulse" command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wfmp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_data           : out    std_logic_vector                                                       --  Field data
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WMDC [channel] [frame] [index] [data]:
   --!  Write in ADC dump/science memories for data compare
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wmdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_frame          : out    integer range 0 to c_MEM_SC_FRM_NB-1                                 ; --  Field frame number
         o_fld_index          : out    integer range 0 to c_MUX_FACT-1                                      ; --  Field memory index number
         o_fld_data           : out    std_logic_vector                                                       --  Field data
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WPFC [channel] [frequency]: write pulse shaping cut frequency for verification
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wpfc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_frequency      : out    integer                                                                --  Field frequency cut (Hz)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wudi (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : inout  line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_value          : out    std_logic                                                            ; --  Field value
         o_fld_data           : out    std_logic_vector                                                     ; --  Field data
         o_fld_mask           : out    std_logic_vector                                                       --  Field mask
   );

end pkg_func_cmd_script;

package body pkg_func_cmd_script is

   -- ------------------------------------------------------------------------------------------------------
   --! Compare time and write result in file output
   -- ------------------------------------------------------------------------------------------------------
   procedure cmp_time (
         i_ope                : in     string(1 to c_OPE_CMP_S)                                             ; --  Operator
         i_time_left          : in     time                                                                 ; --  Time left  operator
         i_time_right         : in     time                                                                 ; --  Time right operator
         i_mess_header        : in     string                                                               ; --  Message header
         i_mess_header_assert : in     string                                                               ; --  Message header assert
         b_err_chk_time       : inout  std_logic                                                            ; --  Error check time
         file file_out        : text                                                                          --  File output
   ) is
   begin

      -- [ope] analysis
      case i_ope is
         when "=="   =>
            if i_time_left = i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when "/="   =>
            if i_time_left /= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when "<<"   =>
            if i_time_left < i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " strictly less than expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not strictly less than expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when "<="   =>
            if i_time_left <= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " less than or equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not less than or equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when ">>"   =>
            if i_time_left > i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " strictly greater than expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not strictly greater than expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when ">="   =>
            if i_time_left >= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " greater than or equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not greater than or equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               b_err_chk_time := c_HGH_LEV;

            end if;

         when others =>
            assert i_ope = "==" report i_mess_header_assert & c_MESS_ERR_UNKNOWN severity failure;

      end case;

   end cmp_time;

   -- ------------------------------------------------------------------------------------------------------
   --! Check simulation end reached
   -- ------------------------------------------------------------------------------------------------------
   procedure chk_sim_end (
         i_sim_time           : in     time                                                                 ; --  Simulation time
         i_wait_time          : in     time                                                                 ; --  Waiting time
         i_mess_event         : in     string                                                               ; --  Message Event
         o_err_sim_time       : out    std_logic                                                            ; --  Error simulation time
         file file_out        : text                                                                          --  File output
   ) is
   begin

      if now = i_sim_time then
         fprintf(error, i_mess_event & " not reached. Simulation time not long enough.", file_out);
         o_err_sim_time := c_HGH_LEV;

      else
         fprintf(note, "Waiting " & i_mess_event & " for " & time'image(i_wait_time), file_out);
         o_err_sim_time := c_LOW_LEV;

      end if;

   end chk_sim_end;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   ) is
   variable v_fld_end         : line                                                                        ; --! Field end
   begin

      -- Get spi command field
      parse_spi_cmd(b_cmd_file_line, i_mess_header, o_mess_spi_cmd, o_fld_spi_cmd);

      -- Get [end] field
      rfield(b_cmd_file_line, i_mess_header & "[end]", c_ONE_INT, v_fld_end);

      o_wait_end := none;

      case v_fld_end(1 to 1) is

         -- Wait the command end
         when "W"|"w"   =>
            o_wait_end := wait_cmd_end_tx;

         -- To do nothing
         when "N"|"n"   =>
            null;

         when others    =>
            assert v_fld_end = null report i_mess_header & "[end]" & c_MESS_ERR_UNKNOWN severity failure;

      end case;

   end get_param_ccmd;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCPE [report]: enable the display in result file of the report
   --!  about the check parameters
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccpe (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ce             : out    line                                                                 ; --  Field check clock parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S-1                                            --  Field check clock parameters enable index (equal to c_CE_S if field not recognized)
   ) is
   begin

      -- Get [report]
      get_ce_index(b_cmd_file_line, o_fld_ce, o_fld_ce_ind);
      assert o_fld_ce_ind /= c_CE_S report i_mess_header & "[report]" & c_MESS_ERR_UNKNOWN severity failure;

   end get_param_ccpe;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   ) is
   begin

      -- Get [discrete_r]
      get_dr_index(b_cmd_file_line, o_fld_dr, o_fld_dr_ind);
      assert o_fld_dr_ind /= c_DR_S report i_mess_header & "[discrete_r]" & c_MESS_ERR_UNKNOWN severity failure;

      -- Get [value], binary format
      brfield(b_cmd_file_line, i_mess_header & "[value]", o_fld_value);

   end get_param_cdis;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CLDC [channel] [value]: check level SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cldc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_value          : out    real                                                                   --  Field value
   ) is
   begin

      -- Get [channel]
      rfield(b_cmd_file_line, i_mess_header & "[channel]", o_fld_channel);
      assert o_fld_channel < c_NB_COL report i_mess_header & "[channel]" & c_MESS_ERR_SIZE severity failure;

      -- Get [value], real format
      rfield(b_cmd_file_line, i_mess_header & "[value]", o_fld_value);

   end get_param_cldc;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CSCP [science_ctrl_pos] [science_packet] : check the science packet type
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cscp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_sc_ctrl_pos    : out    integer range 0 to c_SC_PKT_W_NB-1                                   ; --  Field science control position
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector                                                       --  Field science packet type value
   ) is
   begin

      -- Get [science_ctrl_pos]
      rfield(b_cmd_file_line, i_mess_header & "[science_ctrl_pos]", o_fld_sc_ctrl_pos);
      assert o_fld_sc_ctrl_pos < c_SC_PKT_W_NB report i_mess_header & "[science_ctrl_pos]" & c_MESS_ERR_SIZE severity failure;

      -- Get [science_packet]
      get_sc_pkt_type(b_cmd_file_line, o_fld_sc_pkt, o_fld_sc_pkt_val);
      assert o_fld_sc_pkt_val /= c_RET_UKWN(o_fld_sc_pkt_val'range) report i_mess_header & "[science_packet]" & c_MESS_ERR_UNKNOWN severity failure;

   end get_param_cscp;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTDC [channel] [ope] [time]: check time between the current time
   --!  and last event SQUID MUX ADC input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Get [channel]
      rfield(b_cmd_file_line, i_mess_header & "[channel]", o_fld_channel);
      assert o_fld_channel < c_NB_COL report i_mess_header & "[channel]" & c_MESS_ERR_SIZE severity failure;

      -- Get [ope] and [time]
      rfield(b_cmd_file_line, i_mess_header & "[ope]", c_ZERO_INT, o_fld_ope);
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_ctdc;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLE [discrete_r] [ope] [time]: check time between the current time
   --!  and discrete input last event
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctle (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Get [discrete_r]
      get_dr_index(b_cmd_file_line, o_fld_dr, o_fld_dr_ind);
      assert o_fld_dr_ind /= c_DR_S report i_mess_header & "[discrete_r]" & c_MESS_ERR_UNKNOWN severity failure;

      -- Get [ope] and [time]
      rfield(b_cmd_file_line, i_mess_header & "[ope]", c_ZERO_INT, o_fld_ope);
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_ctle;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctlr (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Get [ope] and [time]
      rfield(b_cmd_file_line, i_mess_header & "[ope]", c_ZERO_INT, o_fld_ope);
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_ctlr;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wait (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Get [time]
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_wait;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WCMD [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcmd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   ) is
   variable v_fld_end         : line                                                                        ; --! Field end
   begin

      -- Get spi command field
      parse_spi_cmd(b_cmd_file_line, i_mess_header, o_mess_spi_cmd, o_fld_spi_cmd);

      -- Get [end] field
      rfield(b_cmd_file_line, i_mess_header & "[end]", c_ONE_INT, v_fld_end);

      o_wait_end := none;

      -- [end] analysis
      case v_fld_end(1 to 1) is

         -- Wait the command end
         when "R"|"r"   =>
            o_wait_end := wait_rcmd_end_rx;

         -- Wait the command end
         when "W"|"w"   =>
            o_wait_end := wait_cmd_end_tx;

         -- To do nothing
         when "N"|"n"   =>
            null;

         when others =>
            assert v_fld_end = null report i_mess_header & "[end]" & c_MESS_ERR_UNKNOWN severity failure;

      end case;

   end get_param_wcmd;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WCMS [size]: write EP command word size or
   --! Get parameters command WNBD [number]: write board reference number
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcms_wnbd (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_integer        : out    integer                                                                --  Field integer
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [size]/[number], hex format
      rfield(b_cmd_file_line, i_mess_header & "[size]/[number]", o_fld_integer);

   end get_param_wcms_wnbd;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wdis (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                            ; --  Field discrete output index (equal to c_DW_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   ) is
   begin

      -- Get [discrete_w]
      get_dw_index(b_cmd_file_line, o_fld_dw, o_fld_dw_ind);
      assert o_fld_dw_ind /= c_DW_S report i_mess_header & "[discrete_w]" & c_MESS_ERR_UNKNOWN severity failure;

      -- Get [value], binary format
      brfield(b_cmd_file_line, i_mess_header & "[value]", o_fld_value);

   end get_param_wdis;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WFMP [channel] [data]: write FPASIM "Make pulse" command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wfmp (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_data           : out    std_logic_vector                                                       --  Field data
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [channel]
      rfield(b_cmd_file_line, i_mess_header & "[channel]", o_fld_channel);
      assert o_fld_channel < c_NB_COL report i_mess_header & "[channel]" & c_MESS_ERR_SIZE severity failure;

      -- Get [data], hex format
      drop_line_char(b_cmd_file_line, ' ', b_cmd_file_line);
      hrfield(b_cmd_file_line, i_mess_header & "[data]", o_fld_data);

   end get_param_wfmp;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WMDC [channel] [index] [data]:
   --!  Write in ADC dump/science memories for data compare
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wmdc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_frame          : out    integer range 0 to c_MEM_SC_FRM_NB-1                                 ; --  Field frame number
         o_fld_index          : out    integer range 0 to c_MUX_FACT-1                                      ; --  Field memory index number
         o_fld_data           : out    std_logic_vector                                                       --  Field data
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [channel]
      rfield(b_cmd_file_line, i_mess_header & "[channel]", o_fld_channel);
      assert o_fld_channel < c_NB_COL report i_mess_header & "[channel]" & c_MESS_ERR_SIZE severity failure;

      -- Get [frame]
      rfield(b_cmd_file_line, i_mess_header & "[frame]", o_fld_frame);
      assert o_fld_frame < c_MEM_SC_FRM_NB report i_mess_header & "[frame]" & c_MESS_ERR_SIZE severity failure;

      -- Get [index]
      rfield(b_cmd_file_line, i_mess_header & "[index]", o_fld_index);
      assert o_fld_index < c_MUX_FACT report i_mess_header & "[index]" & c_MESS_ERR_SIZE severity failure;

      -- Get [data], hex format
      drop_line_char(b_cmd_file_line, ' ', b_cmd_file_line);
      hrfield(b_cmd_file_line, i_mess_header & "[data]", o_fld_data);

   end get_param_wmdc;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WPFC [channel] [frequency]: write pulse shaping cut frequency for verification
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wpfc (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_channel        : out    integer range 0 to c_NB_COL-1                                        ; --  Field channel number
         o_fld_frequency      : out    integer                                                                --  Field frequency cut (Hz)
   ) is
   begin

      -- Get [channel]
      rfield(b_cmd_file_line, i_mess_header & "[channel]", o_fld_channel);
      assert o_fld_channel < c_NB_COL report i_mess_header & "[channel]" & c_MESS_ERR_SIZE severity failure;

      -- Get [frequency]
      rfield(b_cmd_file_line, i_mess_header & "[frequency]", o_fld_frequency);

   end get_param_wpfc;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WUDI [discrete_r] [value] or WUDI [mask] [data]: wait until event on discrete(s)
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wudi (
         b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : inout  line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_value          : out    std_logic                                                            ; --  Field value
         o_fld_data           : out    std_logic_vector                                                     ; --  Field data
         o_fld_mask           : out    std_logic_vector                                                       --  Field mask
   ) is
   begin

      -- Get [discrete_r]
      get_dr_index(b_cmd_file_line, o_fld_dr, o_fld_dr_ind);

      -- Check if the last field is a discrete
      if o_fld_dr_ind /= c_DR_S then

         -- Get [value], binary format
         brfield(b_cmd_file_line, i_mess_header & "[value]", o_fld_value);

      else
         -- Drop underscore included in the fields and get [mask], hex format
         drop_line_char(o_fld_dr, '_', o_fld_dr);
         hrfield(o_fld_dr, i_mess_header & "[mask]", o_fld_mask);

         -- Drop underscore included in the fields and get [data], hex format
         drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);
         hrfield(b_cmd_file_line, i_mess_header & "[data]", o_fld_data);

      end if;

   end get_param_wudi;

end package body pkg_func_cmd_script;
