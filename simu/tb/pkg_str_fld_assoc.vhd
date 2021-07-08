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
--!   @file                   pkg_str_fld_assoc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package string field association
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_model.all;
use     work.pkg_mess.all;

library std;
use std.textio.all;

package pkg_str_fld_assoc is

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete output name) included in line and
   --!  get the associated discrete output index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dw_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                              --  Field discrete output index (equal to c_DW_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete input name) included in line and
   --!  get the associated discrete input index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dr_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                              --  Field discrete input index (equal to c_DR_S if field not recognized)
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command address) included in line and
   --!  get the associated address value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_add
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_add            : out    line                                                                 ; --  Field address
         o_fld_add_val        : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field address value
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Parse spi command [access] [address] [data]
   -- ------------------------------------------------------------------------------------------------------
   procedure parse_spi_cmd
   (     b_cmd                : inout  line                                                                 ; --  Command
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                       --  Field SPI command
   );

end pkg_str_fld_assoc;

package body pkg_str_fld_assoc is
constant c_RET_ADD_UKWN       : std_logic_vector(c_EP_SPI_WD_S-1 downto 0) := (others => '1')               ; --! Return address unknown value

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete output name) included in line and
   --!  get the associated discrete output index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dw_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                              --  Field discrete output index (equal to c_DW_S if field not recognized)
   ) is
   constant c_PAD             : character := ' '                                                            ; --  Padding character
   variable v_fld_dw_pad      : line                                                                        ; --  Field discrete output with padding
   begin

      -- Get the discrete output name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_dw_pad);

      -- Return field discrete output index
      case v_fld_dw_pad(1 to c_SIG_NAME_STR_MAX_S) is
         when "arst_n              "   =>
            o_fld_dw_ind := c_DW_ARST_N;

         when others                   =>
            o_fld_dw_ind := c_DW_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_dw_pad, c_PAD, o_fld_dw);

   end get_dw_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete input name) included in line and
   --!  get the associated discrete input index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dr_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dr             : out    line                                                                 ; --  Field discrete input
         o_fld_dr_ind         : out    integer range 0 to c_DR_S                                              --  Field discrete input index (equal to c_DR_S if field not recognized)
   ) is
   constant c_PAD             : character := ' '                                                            ; --  Padding character
   variable v_fld_dr_pad      : line                                                                        ; --  Field discrete input with padding
   begin

      -- Get the discrete input name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_dr_pad);

      -- Return field discrete output index
      case v_fld_dr_pad(1 to c_SIG_NAME_STR_MAX_S) is
         when "rst                 "   =>
            o_fld_dr_ind := c_DR_D_RST;

         when "clk_ref             "   =>
            o_fld_dr_ind := c_DR_CLK_REF;

         when "clk                 "   =>
            o_fld_dr_ind := c_DR_D_CLK;

         when "clk_sq1_adc         "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQ1_ADC;

         when "clk_sq1_pls_shape   "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQ1_PLS_SH;

         when "ep_cmd_busy_n       "   =>
            o_fld_dr_ind := c_DR_EP_CMD_BUSY_N;

         when "ep_data_rx_rdy      "   =>
            o_fld_dr_ind := c_DR_EP_DATA_RX_RDY;

         when others                   =>
            o_fld_dr_ind := c_DR_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_dr_pad, c_PAD, o_fld_dr);

   end get_dr_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command address) included in line and
   --!  get the associated address value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_add
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_add            : out    line                                                                 ; --  Field address
         o_fld_add_val        : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field address value
   ) is
   constant c_PAD             : character := ' '                                                            ; --  Padding character
   variable v_fld_add_pad     : line                                                                        ; --  Field address with padding
   begin

      -- Get the address name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_add_pad);

      -- Return address value
      case v_fld_add_pad(1 to c_CMD_NAME_STR_MAX_S) is
         when "Status                        "  =>
            o_fld_add_val:= c_EP_CMD_ADD_STATUS;

         when "Version                       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_VERSION;

         when others                            =>
            o_fld_add_val:= c_RET_ADD_UKWN;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_add_pad, c_PAD, o_fld_add);

   end get_cmd_add;

   -- ------------------------------------------------------------------------------------------------------
   --! Parse spi command [access] [address] [data]
   -- ------------------------------------------------------------------------------------------------------
   procedure parse_spi_cmd
   (     b_cmd                : inout  line                                                                 ; --  Command
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                       --  Field SPI command
   ) is
   constant c_CMD_DEL         : character := '-'                                                            ; --  Command delimiter character
   variable v_cmd_field       : line                                                                        ; --  Command field
   variable v_cmd_field_s     : integer                                                                     ; --  Command field size
   variable v_fld_access      : line                                                                        ; --  Field access
   variable v_fld_add         : line                                                                        ; --  Field address
   variable v_fld_add_val     : std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                                  ; --  Field address value
   variable v_fld_data        : line                                                                        ; --  Field data
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
            write(v_fld_access, v_cmd_field(1 to 1) & "ead");

         -- Wait the command end
         when "W"|"w"   =>
            o_fld_spi_cmd(c_EP_SPI_WD_S + c_EP_CMD_ADD_RW_POS) := c_EP_CMD_ADD_RW_W;
            write(v_fld_access, v_cmd_field(1 to 1) &  "rite");

         when others =>
            assert v_cmd_field = null report i_mess_header & "[access]" & c_MESS_ERR_UNKNOWN severity failure;

      end case;
      
      -- Get [address]
      get_field_line(b_cmd, c_CMD_DEL, v_cmd_field, v_cmd_field_s);
      get_cmd_add(v_cmd_field, v_fld_add, v_fld_add_val);
    
      if v_fld_add_val = c_RET_ADD_UKWN then

         -- Drop underscore included in the fields
         drop_line_char(v_fld_add, '_', v_fld_add);

         -- Get [address], hex format
         hrfield(v_fld_add, i_mess_header & "[address]", v_fld_add_val);

      end if;
      
      if c_EP_CMD_ADD_RW_POS = 0 then
         o_fld_spi_cmd(o_fld_spi_cmd'high     downto c_EP_SPI_WD_S + 1) := v_fld_add_val(v_fld_add_val'high-1 downto 0);

      else
         o_fld_spi_cmd(o_fld_spi_cmd'high - 1 downto c_EP_SPI_WD_S    ) := v_fld_add_val(v_fld_add_val'high-1 downto 0);

      end if;
      
      -- Drop underscore included in the fields
      drop_line_char(b_cmd, '_', b_cmd);

      -- Get [data], hex format
      hrfield(b_cmd, i_mess_header & "[data]", o_fld_spi_cmd(c_EP_SPI_WD_S - 1 downto 0));

      -- Elaborate message SPI command
      hfield_format(o_fld_spi_cmd, v_cmd_field);
      hfield_format(o_fld_spi_cmd(c_EP_SPI_WD_S - 1 downto 0), v_fld_data);     
      write(o_mess_spi_cmd, "value " & v_cmd_field.all & " (" & v_fld_add.all & ", mode " & v_fld_access.all & ", data " & v_fld_data.all & ")");

   end parse_spi_cmd;

end package body;