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
--!   @file                   pkg_mess.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package message management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library std;
use std.textio.all;

package pkg_mess is

type     t_mess_level           is (none, info, note, warning, error, debug)                                ; --! Message level type

constant c_MESS_FORMAT_BIN    : string  := " binary"                                                        ; --! Message: format Binary
constant c_MESS_FORMAT_HEX    : string  := " hex"                                                           ; --! Message: format Hex
constant c_MESS_FORMAT_TIME   : string  := " time"                                                          ; --! Message: format Time
constant c_MESS_FORMAT_INT    : string  := " integer"                                                       ; --! Message: format Integer

constant c_MESS_ERR_SIZE      : string  := " size not expected"                                             ; --! Message: size error
constant c_MESS_ERR_FORMAT    : string  := " format not expected"                                           ; --! Message: format error
constant c_MESS_ERR_UNKNOWN   : string  := " unknown"                                                       ; --! Message: unknown error

constant c_MESS_READ          : string  := ", read: "                                                       ; --! Message: read
constant c_MESS_EXP           : string  := ", expected: "                                                   ; --! Message: expected

   -- ------------------------------------------------------------------------------------------------------
   --! Writes the message to the output stream file
   -- ------------------------------------------------------------------------------------------------------
   procedure fprintf
   (     i_mess_level         : in     t_mess_level                                                         ; --  Message level
         i_mess               : in     string                                                               ; --  Message
         file file_out        : text                                                                          --  File output
   );

   procedure fprintf
   (     i_mess_level         : in     t_mess_level                                                         ; --  Message level
         b_mess               : inout  line                                                                 ; --  Message
         file file_out        : text                                                                          --  File output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Drop a specific character included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure drop_line_char
   (     b_line               : inout  line                                                                 ; --  Line input
         i_char               : in     character                                                            ; --  Character to delete
         o_line               : out    line                                                                   --  Line output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Format a field in hex characters grouped 4 by 4 and separate by underscore
   -- ------------------------------------------------------------------------------------------------------
   procedure hfield_format
   (     i_field              : in     std_logic_vector                                                     ; --  Field (multiple of 16)
         o_line               : out    line                                                                   --  Line output
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get first field delimited by separator included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure get_field_line
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_delimiter          : in     character                                                            ; --  Separator
         o_field              : out    line                                                                 ; --  First field
         o_field_s            : out    integer                                                                --  Field size
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Read delimited by separator space included in line and complete it with padding character
   --!  to specified size
   -- ------------------------------------------------------------------------------------------------------
   procedure rfield_pad
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_delimiter          : in     character                                                            ; --  Delimiter
         i_size               : in     integer                                                              ; --  Size to get
         o_field              : out    line                                                                   --  Field found
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Read and check field delimited by delimiter space included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         i_size_check         : in     integer                                                              ; --  Size to check
         o_field              : out    line                                                                   --  Field found
   );

   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    time                                                                   --  Field found
   );

   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    integer                                                                --  Field found
   );

   procedure brfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (binary characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic_vector                                                       --  Field found
   );

   procedure brfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (binary characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic                                                              --  Field found
   );

   procedure hrfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (hex characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic_vector                                                       --  Field found
   );

end pkg_mess;

package body pkg_mess is

   -- ------------------------------------------------------------------------------------------------------
   --! Convert message level to line type
   -- ------------------------------------------------------------------------------------------------------
   procedure mess_level_line
   (     i_mess_level         : in     t_mess_level                                                         ; --  Message level
         o_header_line        : out    line                                                                   --  Header line
   ) is
   constant c_HEADER_START    : string := "# "                                                              ; --! Header start
   constant c_HEADER_END      : string := ") "                                                              ; --! Header end
   begin

      case i_mess_level is
         when info      =>
            write(o_header_line, c_HEADER_START & "            (" & time'image(now) & c_HEADER_END);          -- Information message

         when note      =>
            write(o_header_line, c_HEADER_START & "** Note   : (" & time'image(now) & c_HEADER_END);          -- Note message

         when warning   =>
            write(o_header_line, c_HEADER_START & "** Warning: (" & time'image(now) & c_HEADER_END);          -- Warning message

         when error     =>
            write(o_header_line, c_HEADER_START & "** Error  : (" & time'image(now) & c_HEADER_END);          -- Error message

         when debug     =>
            write(o_header_line, c_HEADER_START & "** Debug  : (" & time'image(now) & c_HEADER_END);          -- Debug message

         when others    =>
            write(o_header_line, c_HEADER_START );                                                            -- None message

      end case;

   end mess_level_line;

   -- ------------------------------------------------------------------------------------------------------
   --! Writes the message to the output stream file
   -- ------------------------------------------------------------------------------------------------------
   procedure fprintf
   (     i_mess_level         : in     t_mess_level                                                         ; --  Message level
         i_mess               : in     string                                                               ; --  Message
         file file_out        : text                                                                          --  File output
   ) is
   variable v_header_line     : line                                                                        ; --! Header line
   begin

      mess_level_line(i_mess_level, v_header_line);
      write(v_header_line, i_mess);
      writeline(file_out, v_header_line);

   end fprintf;

   procedure fprintf
   (     i_mess_level         : in     t_mess_level                                                         ; --  Message level
         b_mess               : inout  line                                                                 ; --  Message
         file file_out        : text                                                                          --  File output
   ) is
   variable v_header_line     : line                                                                        ; --! Header line
   variable v_cat_line        : line                                                                        ; --! Concatenated line
   begin

      mess_level_line(i_mess_level, v_header_line);
      v_cat_line.all := v_header_line.all & b_mess.all;
      writeline(file_out, v_cat_line);

   end fprintf;

   -- ------------------------------------------------------------------------------------------------------
   --! Drop a specific character included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure drop_line_char
   (     b_line               : inout  line                                                                 ; --  Line input
         i_char               : in     character                                                            ; --  Character to delete
         o_line               : out    line                                                                   --  Line output
   ) is
   variable v_line_char       : character                                                                   ; --! Line character
   begin

      -- Read line character by character
      for i in b_line'range loop
         read(b_line, v_line_char);

         -- Add character to the line
         if v_line_char /= i_char then
            write(o_line, v_line_char);
         end if;

      end loop;

   end drop_line_char;

   -- ------------------------------------------------------------------------------------------------------
   --! Format a field in hex characters grouped 4 by 4 and separate by underscore
   -- ------------------------------------------------------------------------------------------------------
   procedure hfield_format
   (     i_field              : in     std_logic_vector                                                     ; --  Field (multiple of 16)
         o_line               : out    line                                                                   --  Line output
   ) is
   variable v_line_temp       : line                                                                        ; --! Temporary line
   begin

      -- Convert data into line, hex format
      hwrite(v_line_temp, i_field);

      -- Group chain by packet of 4 characters
      for i in 0 to v_line_temp'length/4-1 loop

         write(o_line, v_line_temp(4*i+1 to 4*(i+1)));

         -- Insert underscore between each packet
         if i/= v_line_temp'length/4-1 then
            write(o_line, '_');

         end if;

      end loop;

   end hfield_format;

   -- ------------------------------------------------------------------------------------------------------
   --! Get first field delimited by delimiter included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure get_field_line
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_delimiter          : in     character                                                            ; --  Delimiter
         o_field              : out    line                                                                 ; --  First field
         o_field_s            : out    integer                                                                --  Field size
   ) is
   variable v_line_char       : character                                                                   ; --! Line character
   begin

      -- Initialize field size
      o_field_s := 0;

      -- Read line character by character
      for i in b_line'range loop
         read(b_line, v_line_char);

         -- Exit loop if separator or carriage return detected
         if v_line_char = i_delimiter or v_line_char = CR then
            exit;
         end if;

         -- Add character to field and update its size
         write(o_field, v_line_char);
         o_field_s := i;

      end loop;

   end get_field_line;

   -- ------------------------------------------------------------------------------------------------------
   --! Read delimited by separator space included in line and complete it with padding character
   --!  to specified size
   -- ------------------------------------------------------------------------------------------------------
   procedure rfield_pad
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_delimiter          : in     character                                                            ; --  Delimiter
         i_size               : in     integer                                                              ; --  Size to get
         o_field              : out    line                                                                   --  Field found
   ) is
   variable v_field_s         : integer                                                                     ; --! Field size
   begin

      -- Get field
      get_field_line(b_line, ' ', o_field, v_field_s);

      -- Add delimiter(s) to field
      while v_field_s < i_size loop

         write(o_field, i_delimiter);
         v_field_s := v_field_s + 1;

      end loop;

   end rfield_pad;

   -- ------------------------------------------------------------------------------------------------------
   --! Read and check field delimited by separator space included in line
   -- ------------------------------------------------------------------------------------------------------
   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         i_size_check         : in     integer                                                              ; --  Size to check
         o_field              : out    line                                                                   --  Field found
   ) is
   variable v_field_s         : integer                                                                     ; --! Field size
   begin

      -- Get field
      get_field_line(b_line, ' ', o_field, v_field_s);

      if i_size_check /= 0 then

         -- Check the field size
         assert v_field_s = i_size_check report i_mess_header & c_MESS_ERR_SIZE & c_MESS_READ & integer'image(v_field_s) & c_MESS_EXP & integer'image(i_size_check) severity failure;

      end if;

   end rfield;

   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    time                                                                   --  Field found
   ) is
   variable v_field_status    : boolean                                                                     ; --! Field status
   begin

      -- Get field
      read(b_line, o_field, v_field_status);

      -- Check the field format
      assert v_field_status = true report i_mess_header & c_MESS_FORMAT_TIME & c_MESS_ERR_FORMAT severity failure;

   end rfield;

   procedure rfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    integer                                                                --  Field found
   ) is
   variable v_field_status    : boolean                                                                     ; --! Field status
   begin

      -- Get field
      read(b_line, o_field, v_field_status);

      -- Check the field format
      assert v_field_status = true report i_mess_header & c_MESS_FORMAT_TIME & c_MESS_FORMAT_INT severity failure;

   end rfield;

   procedure brfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (binary characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic_vector                                                       --  Field found
   ) is
   variable v_field           : line                                                                        ; --! Field
   variable v_field_s         : integer                                                                     ; --! Field size
   variable v_field_status    : boolean                                                                     ; --! Field status
   begin

      -- Get field string
      get_field_line(b_line, ' ', v_field, v_field_s);

      -- Check the mask size
      assert v_field_s = o_field'length report i_mess_header & c_MESS_ERR_SIZE & c_MESS_READ & integer'image(v_field_s) & c_MESS_EXP & integer'image(o_field'length) severity failure;

      -- Get field output format, binary value
      read(v_field, o_field, v_field_status);

      -- Check the mask Hex value
      assert v_field_status = true report i_mess_header & c_MESS_FORMAT_BIN & c_MESS_ERR_FORMAT severity failure;

   end brfield;

   procedure brfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (binary characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic                                                              --  Field found
   ) is
   variable v_field           : line                                                                        ; --! Field
   variable v_field_s         : integer                                                                     ; --! Field size
   variable v_field_status    : boolean                                                                     ; --! Field status
   begin

      -- Get field string
      get_field_line(b_line, ' ', v_field, v_field_s);

      -- Check the mask size
      assert v_field_s = 1 report i_mess_header & c_MESS_ERR_SIZE & c_MESS_READ & integer'image(v_field_s) & c_MESS_EXP & "1" severity failure;

      -- Get field output format, binary value
      read(v_field, o_field, v_field_status);

      -- Check the mask Hex value
      assert v_field_status = true report i_mess_header & c_MESS_FORMAT_BIN & c_MESS_ERR_FORMAT severity failure;

   end brfield;

   procedure hrfield
   (     b_line               : inout  line                                                                 ; --  Line to analysis (hex characters)
         i_mess_header        : in     string                                                               ; --  Message header
         o_field              : out    std_logic_vector                                                       --  Field found
   ) is
   variable v_field           : line                                                                        ; --! Field
   variable v_field_s         : integer                                                                     ; --! Field size
   variable v_field_status    : boolean                                                                     ; --! Field status
   begin

      -- Get field string
      get_field_line(b_line, ' ', v_field, v_field_s);

      -- Check the mask size
      assert v_field_s = o_field'length/4 report i_mess_header & c_MESS_ERR_SIZE & c_MESS_READ & integer'image(v_field_s) & c_MESS_EXP & integer'image(o_field'length/4) severity failure;

      -- Get field output format, Hex value
      hread(v_field, o_field, v_field_status);

      -- Check the mask Hex value
      assert v_field_status = true report i_mess_header & c_MESS_FORMAT_HEX & c_MESS_ERR_FORMAT severity failure;

   end hrfield;

end package body;
