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
use     ieee.numeric_std.all;

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
   --! Get the first field (command data) included in line and
   --!  get the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_data
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_data           : out    line                                                                 ; --  Field data
         o_fld_data_val       : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field data value
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
constant c_CMD_DEL            : character := '-'                                                            ; --  Command delimiter character
constant c_PAD                : character := ' '                                                            ; --  Padding character
constant c_RET_UKWN           : std_logic_vector(c_EP_SPI_WD_S-1 downto 0) := (others => '1')               ; --! Return unknown value

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (discrete output name) included in line and
   --!  get the associated discrete output index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_dw_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_dw             : out    line                                                                 ; --  Field discrete output
         o_fld_dw_ind         : out    integer range 0 to c_DW_S                                              --  Field discrete output index (equal to c_DW_S if field not recognized)
   ) is
   variable v_fld_dw_pad      : line                                                                        ; --  Field discrete output with padding
   begin

      -- Get the discrete output name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_dw_pad);

      -- Return field discrete output index
      case v_fld_dw_pad(1 to c_SIG_NAME_STR_MAX_S) is
         when "arst_n              "   =>
            o_fld_dw_ind := c_DW_ARST_N;

         when "brd_model(0)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_0;

         when "brd_model(1)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_1;

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

         when "clk_sq1_adc_acq     "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQ1_ADC;

         when "clk_sq1_pls_shape   "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQ1_PLS_SH;

         when "ep_cmd_busy_n       "   =>
            o_fld_dr_ind := c_DR_EP_CMD_BUSY_N;

         when "ep_data_rx_rdy      "   =>
            o_fld_dr_ind := c_DR_EP_DATA_RX_RDY;

         when "rst_sq1_adc(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_ADC_0;

         when "rst_sq1_adc(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_ADC_1;

         when "rst_sq1_adc(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_ADC_2;

         when "rst_sq1_adc(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_ADC_3;

         when "rst_sq1_dac(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_DAC_0;

         when "rst_sq1_dac(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_DAC_1;

         when "rst_sq1_dac(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_DAC_2;

         when "rst_sq1_dac(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ1_DAC_3;

         when "rst_sq2_mux(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ2_MUX_0;

         when "rst_sq2_mux(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ2_MUX_1;

         when "rst_sq2_mux(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ2_MUX_2;

         when "rst_sq2_mux(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQ2_MUX_3;

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
            o_fld_add_val:= c_RET_UKWN;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_add_pad, c_PAD, o_fld_add);

   end get_cmd_add;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (command data) included in line and
   --!  get the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_cmd_data
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_data           : out    line                                                                 ; --  Field data
         o_fld_data_val       : out    std_logic_vector(c_EP_SPI_WD_S-1 downto 0)                             --  Field data value
   ) is
   variable v_fld_data_pad    : line                                                                        ; --  Field data with padding
   begin

      -- Get the data name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_data_pad);

      -- Return data value
      case v_fld_data_pad(1 to c_CMD_NAME_STR_MAX_S) is
         when "FW_VERSION                    "  =>
            o_fld_data_val:= std_logic_vector(to_unsigned(c_FW_VERSION, o_fld_data_val'length));

         when others                            =>
            o_fld_data_val:= c_RET_UKWN;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_data_pad, c_PAD, o_fld_data);

   end get_cmd_data;

   -- ------------------------------------------------------------------------------------------------------
   --! Parse spi command [access] [address] [data]
   -- ------------------------------------------------------------------------------------------------------
   procedure parse_spi_cmd
   (     b_cmd                : inout  line                                                                 ; --  Command
         i_mess_header        : in     string                                                               ; --  Message header
         o_mess_spi_cmd       : out    line                                                                 ; --  Message SPI command
         o_fld_spi_cmd        : out    std_logic_vector                                                       --  Field SPI command
   ) is
   constant c_FW_VERSION_S    : integer   := c_EP_SPI_WD_S - c_BRD_MODEL_S - c_BRD_REF_S                    ; --  Firmware version bus size
   variable v_cmd_field       : line                                                                        ; --  Command field
   variable v_cmd_field_s     : integer                                                                     ; --  Command field size
   variable v_fld_access      : line                                                                        ; --  Field access
   variable v_fld_add         : line                                                                        ; --  Field address
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
      get_cmd_add(v_cmd_field, v_fld_add, v_fld_add_val);

      if v_fld_add_val = c_RET_UKWN then

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

      -- Get [data]
      rfield(b_cmd, i_mess_header & "[data]", 0, v_cmd_field);
      get_field_line(v_cmd_field, c_CMD_DEL, v_fld_data, v_cmd_field_s);
      get_cmd_data(v_fld_data, v_fld_data, v_fld_data_val);

      if v_fld_data_val /= c_RET_UKWN then

         -- Case Version
         o_fld_spi_cmd(c_EP_SPI_WD_S-1 downto c_EP_SPI_WD_S-c_FW_VERSION_S):= v_fld_data_val(c_FW_VERSION_S-1 downto 0);
         hrfield(v_cmd_field, i_mess_header & "[data]", v_fld_data_val(c_EP_SPI_WD_S/2-1 downto 0));
         o_fld_spi_cmd(c_EP_SPI_WD_S-c_FW_VERSION_S-1 downto 0):= v_fld_data_val(c_EP_SPI_WD_S-c_FW_VERSION_S-1 downto 0);

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

end package body;