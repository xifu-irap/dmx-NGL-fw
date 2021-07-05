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
use     work.pkg_model.all;
use     work.pkg_mess.all;
use     work.pkg_str_fld_assoc.all;

library std;
use std.textio.all;

package pkg_func_cmd_script is

type     t_wait_cmd_end         is (none, wait_cmd_end_tx, wait_rcmd_end_rx)                                ; --! Wait command end type

   -- ------------------------------------------------------------------------------------------------------
   --! Compare time and write result in file output
   -- ------------------------------------------------------------------------------------------------------
   procedure cmp_time
   (     i_ope                : in     string(1 to 2)                                                       ; --  Operator
         i_time_left          : in     time                                                                 ; --  Time left  operator
         i_time_right         : in     time                                                                 ; --  Time right operator
         i_mess_header        : in     string                                                               ; --  Message header
         i_mess_header_assert : in     string                                                               ; --  Message header assaert
         o_err_chk_time       : out    std_logic                                                            ; --  Error check time
         file file_out        : text                                                                          --  File output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Check simulation end reached
   -- ------------------------------------------------------------------------------------------------------
   procedure chk_sim_end
   (     i_sim_time           : in     time                                                                 ; --  Simulation time
         i_wait_time          : in     time                                                                 ; --  Waiting time
         i_mess_event         : in     string                                                               ; --  Message Event
         o_err_sim_time       : out    std_logic                                                            ; --  Error simulation time
         file file_out        : text                                                                          --  File output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccmd
   (     b_cmd_file_line      : inout  line                                                                 ; --! Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --! Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cdis
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                            ; --  Field discrete input index (equal to c_DR_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLE [mask] [ope] [time]: check time between the current time and discrete input(s) last event
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctle
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_mask           : out    std_logic_vector                                                     ; --  Field mask
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctlr
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wait
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_time           : out    time                                                                   --  Field time
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcmd
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WCMS [size]: write EP command word size
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcms
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_integer        : out    integer                                                                --  Field integer
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wdis
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                            ; --  Field discrete output index (equal to c_DW_S if field not recognized)
         o_fld_value          : out    std_logic                                                              --  Field value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WUDI [mask] [data]: wait until event on discrete
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wudi
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_data           : out    std_logic_vector                                                     ; --  Field data
         o_fld_mask           : out    std_logic_vector                                                       --  Field mask
   );

end pkg_func_cmd_script;

package body pkg_func_cmd_script is

   -- ------------------------------------------------------------------------------------------------------
   --! Compare time and write result in file output
   -- ------------------------------------------------------------------------------------------------------
   procedure cmp_time
   (     i_ope                : in     string(1 to 2)                                                       ; --  Operator
         i_time_left          : in     time                                                                 ; --  Time left  operator
         i_time_right         : in     time                                                                 ; --  Time right operator
         i_mess_header        : in     string                                                               ; --  Message header
         i_mess_header_assert : in     string                                                               ; --  Message header assert
         o_err_chk_time       : out    std_logic                                                            ; --  Error check time
         file file_out        : text                                                                          --  File output
   ) is
   begin

      -- Initialize error flagreached
      o_err_chk_time := '0';

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
               o_err_chk_time := '1';

            end if;

         when "/="   =>
            if i_time_left /= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               o_err_chk_time := '1';

            end if;

         when "<<"   =>
            if i_time_left < i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " strictly less than expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not strictly less than expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               o_err_chk_time := '1';

            end if;

         when "<="   =>
            if i_time_left <= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " less than or equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not less than or equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               o_err_chk_time := '1';

            end if;

         when ">>"   =>
            if i_time_left > i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " strictly greater than expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not strictly greater than expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               o_err_chk_time := '1';

            end if;

         when ">="   =>
            if i_time_left >= i_time_right then
               fprintf(note , "Check time, " & i_mess_header & ": PASS", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " greater than or equal to expected value " & time'image(i_time_right), file_out);

            else
               fprintf(error, "Check time, " & i_mess_header & ": FAIL", file_out);
               fprintf(note , " * " & i_mess_header & " " & time'image(i_time_left) & " not greater than or equal to expected value " & time'image(i_time_right), file_out);

               -- Activate error flag
               o_err_chk_time := '1';

            end if;

         when others =>
            assert i_ope = "==" report i_mess_header_assert & c_MESS_ERR_UNKNOWN severity failure;

      end case;

   end cmp_time;

   -- ------------------------------------------------------------------------------------------------------
   --! Check simulation end reached
   -- ------------------------------------------------------------------------------------------------------
   procedure chk_sim_end
   (     i_sim_time           : in     time                                                                 ; --  Simulation time
         i_wait_time          : in     time                                                                 ; --  Waiting time
         i_mess_event         : in     string                                                               ; --  Message Event
         o_err_sim_time       : out    std_logic                                                            ; --  Error simulation time
         file file_out        : text                                                                          --  File output
   ) is
   begin

      if now = i_sim_time then
         fprintf(error, i_mess_event & " not reached. Simulation time not long enough.", file_out);
         o_err_sim_time := '1';

      else
         fprintf(note, "Waiting " & i_mess_event & " for " & time'image(i_wait_time), file_out);
         o_err_sim_time := '0';

      end if;

   end chk_sim_end;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CCMD [cmd] [end]: check the EP command return
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ccmd
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   ) is
   variable v_fld_end         : line                                                                        ; --! Field end
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [cmd], hex format
      hrfield(b_cmd_file_line, i_mess_header & "[cmd]", o_fld_spi_cmd);

      -- Get [end] field
      rfield(b_cmd_file_line, i_mess_header & "[end]", 1, v_fld_end);

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
   --! Get parameters command CDIS [discrete_r] [value]: check discrete input
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_cdis
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
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
   --! Get parameters command CTLE [mask] [ope] [time]: check time between the current time and discrete input(s) last event
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctle
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_mask           : out    std_logic_vector                                                     ; --  Field mask
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [mask], hex format
      hrfield(b_cmd_file_line, i_mess_header & "[mask]", o_fld_mask);

      -- Get [ope] and [time]
      rfield(b_cmd_file_line, i_mess_header & "[ope]", 0, o_fld_ope);
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_ctle;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command CTLR [ope] [time]: check time from the last record time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_ctlr
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_ope            : out    line                                                                 ; --  Field operation
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [ope] and [time]
      rfield(b_cmd_file_line, i_mess_header & "[ope]", 0, o_fld_ope);
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_ctlr;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WAIT [time]: wait for time
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wait
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_time           : out    time                                                                   --  Field time
   ) is
   begin

      -- Get [time]
      rfield(b_cmd_file_line, i_mess_header & "[time]", o_fld_time);

   end get_param_wait;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command [cmd] [end]: transmit EP command
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcmd
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_spi_cmd        : out    std_logic_vector                                                     ; --  Field SPI command
         o_wait_end           : out    t_wait_cmd_end                                                         --  Wait command end
   ) is
   variable v_fld_end         : line                                                                        ; --! Field end
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [cmd], hex format
      hrfield(b_cmd_file_line, i_mess_header & "[cmd]", o_fld_spi_cmd);
      rfield(b_cmd_file_line, i_mess_header & "[end]", 1, v_fld_end);

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
   --! Get parameters command WCMS [size]: write EP command word size
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wcms
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_integer        : out    integer                                                                --  Field integer
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [size], hex format
      rfield(b_cmd_file_line, i_mess_header & "[size]", o_fld_integer);

   end get_param_wcms;

   -- ------------------------------------------------------------------------------------------------------
   --! Get parameters command WDIS [discrete_w] [value]: write discrete output
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wdis
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
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
   --! Get parameters command WUDI [mask] [data]: wait until event on discrete
   -- ------------------------------------------------------------------------------------------------------
   procedure get_param_wudi
   (     b_cmd_file_line      : inout  line                                                                 ; --  Command file line
         i_mess_header        : in     string                                                               ; --  Message header
         o_fld_data           : out    std_logic_vector                                                     ; --  Field data
         o_fld_mask           : out    std_logic_vector                                                       --  Field mask
   ) is
   begin

      -- Drop underscore included in the fields
      drop_line_char(b_cmd_file_line, '_', b_cmd_file_line);

      -- Get [mask] and [data], hex format
      hrfield(b_cmd_file_line, i_mess_header & "[mask]", o_fld_mask);
      hrfield(b_cmd_file_line, i_mess_header & "[data]", o_fld_data);

   end get_param_wudi;

end package body;
