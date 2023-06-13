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
--!   @file                   pkg_func_cmd_spi.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package function command SPI
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;
use     work.pkg_str_fld_assoc.all;

library std;
use std.textio.all;

package pkg_func_cmd_spi is

   -- ------------------------------------------------------------------------------------------------------
   --! Parse spi command [access] [address] [data]
   -- ------------------------------------------------------------------------------------------------------
   procedure parse_spi_cmd (
         b_cmd                : inout  line                                                                 ; --  Command
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                       --  Field SPI command
   );

end pkg_func_cmd_spi;

package body pkg_func_cmd_spi is
constant c_CMD_DEL            : character := '-'                                                            ; --  Command delimiter character

   -- ------------------------------------------------------------------------------------------------------
   --! Parse spi command [access] [address] [data]
   -- ------------------------------------------------------------------------------------------------------
   procedure parse_spi_cmd (
         b_cmd                : inout  line                                                                 ; --  Command
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                       --  Field SPI command
   ) is
   variable v_cmd_field       : line                                                                        ; --  Command field
   variable v_cmd_field_s     : integer                                                                     ; --  Command field size
   variable v_fld_access      : line                                                                        ; --  Field access
   variable v_fld_add         : line                                                                        ; --  Field address
   variable v_fld_add_basis   : line                                                                        ; --  Field address basis
   variable v_fld_add_basis_s : integer                                                                     ; --  Field address basis size
   variable v_fld_add_index   : integer                                                                     ; --  Field address index
   variable v_fld_add_val     : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --  Field address value
   variable v_fld_data        : line                                                                        ; --  Field data
   variable v_fld_data_val    : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --  Field data value
   begin

      -- Get [access]
      get_field_line(b_cmd, c_CMD_DEL, v_cmd_field, v_cmd_field_s);

      -- Check the [access] size
      assert v_cmd_field_s = 1 report i_mess_header & "[access]" & c_MESS_ERR_SIZE & c_MESS_READ & integer'image(v_cmd_field_s) & c_MESS_EXP & "1" severity failure;

      -- [access] analysis
      case v_cmd_field(1 to 1) is

         -- Wait the command end
         when "R"|"r"   =>
            o_fld_spi_cmd(c_EP_SPI_WD_S + c_EP_CMD_ADD_RW_POS) := c_EP_CMD_ADD_RW_R;
            write(v_fld_access, string'("Read"));

         -- Wait the command end
         when "W"|"w"   =>
            o_fld_spi_cmd(c_EP_SPI_WD_S + c_EP_CMD_ADD_RW_POS) := c_EP_CMD_ADD_RW_W;
            write(v_fld_access, string'("Write"));

         when others =>
            assert v_cmd_field = null report i_mess_header & "[access]" & c_MESS_ERR_UNKNOWN severity failure;

      end case;

      -- Get [address]
      get_field_line(b_cmd, c_CMD_DEL, v_cmd_field, v_cmd_field_s);

      -- Get address basis part
      get_field_line(v_cmd_field, '(', v_fld_add_basis, v_fld_add_basis_s);
      get_cmd_add(v_fld_add_basis, v_fld_add, v_fld_add_val);

      if v_fld_add_val = c_RET_UKWN then

         -- Drop underscore included in the fields
         drop_line_char(v_fld_add, '_', v_fld_add);

         -- Get address basis part, hex format
         hrfield(v_fld_add, i_mess_header & "[address]", v_fld_add_val);

      end if;

      v_fld_add_index := 0;

      -- Get address index part
      if v_cmd_field_s /= v_fld_add_basis_s then

         -- Drop index end
         drop_line_char(v_cmd_field, ')', v_cmd_field);

         -- Get address index part, integer format
         rfield(v_cmd_field, i_mess_header & "[address]", v_fld_add_index);

      end if;

      if c_EP_CMD_ADD_RW_POS = 0 then
         o_fld_spi_cmd(o_fld_spi_cmd'high     downto c_EP_SPI_WD_S + 1) := std_logic_vector(unsigned(v_fld_add_val(v_fld_add_val'high-1 downto 0)) + to_unsigned(v_fld_add_index, v_fld_add_val'high));

      else
         o_fld_spi_cmd(o_fld_spi_cmd'high - 1 downto c_EP_SPI_WD_S    ) := std_logic_vector(unsigned(v_fld_add_val(v_fld_add_val'high-1 downto 0)) + to_unsigned(v_fld_add_index, v_fld_add_val'high));

      end if;

      -- Get [data]
      rfield(b_cmd, i_mess_header & "[data]", 0, v_cmd_field);
      get_field_line(v_cmd_field, c_CMD_DEL, v_fld_data, v_cmd_field_s);
      get_cmd_data(v_fld_data, v_fld_data, v_fld_data_val);

      if v_fld_data_val /= c_RET_UKWN then

         -- Case Version
         o_fld_spi_cmd(c_EP_SPI_WD_S-1 downto 0):= v_fld_data_val;

      else

         -- Drop underscore included in the fields
         drop_line_char(v_fld_data, '_', v_fld_data);

         -- Get [data], hex format
         hrfield(v_fld_data, i_mess_header & "[data]", o_fld_spi_cmd(c_EP_SPI_WD_S - 1 downto 0));

      end if;

      -- Elaborate message SPI command
      write(o_mess_spi_cmd, "value " & hfield_format(o_fld_spi_cmd).all &
                            " (" & v_fld_add.all & ", mode " & v_fld_access.all & ", data " & hfield_format(o_fld_spi_cmd(c_EP_SPI_WD_S - 1 downto 0)).all & ")");

   end parse_spi_cmd;

end package body pkg_func_cmd_spi;
