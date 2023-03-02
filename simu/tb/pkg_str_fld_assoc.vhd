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
constant c_RET_UKWN           : std_logic_vector(c_EP_SPI_WD_S-1 downto 0) := (others => '1')               ; --! Return unknown value

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
   --! Get the first field (check parameters enable name) included in line and
   --!  get the associated check parameters enable index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_ce_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_ce             : out    line                                                                 ; --  Field check parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S+1                                            --  Field check parameters enable index (equal to c_CE_S if field not recognized)
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
   --! Get the first field (science packet type) included in line and
   --!  get the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_sc_pkt_type
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                         --  Field science packet type value
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

         when "brd_model(2)        "   =>
            o_fld_dw_ind := c_DW_BRD_MODEL_2;

         when "sw_adc_vin(0)       "   =>
            o_fld_dw_ind := c_DW_SW_ADC_VIN_0;

         when "sw_adc_vin(1)       "   =>
            o_fld_dw_ind := c_DW_SW_ADC_VIN_1;

         when "frm_cnt_sc_rst      "   =>
            o_fld_dw_ind := c_DW_FRM_CNT_SC_RST;

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

         when "clk_sqm_adc_acq     "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQM_ADC;

         when "clk_sqm_pls_shape   "   =>
            o_fld_dr_ind := c_DR_D_CLK_SQM_PLS_SH;

         when "ep_cmd_busy_n       "   =>
            o_fld_dr_ind := c_DR_EP_CMD_BUSY_N;

         when "ep_data_rx_rdy      "   =>
            o_fld_dr_ind := c_DR_EP_DATA_RX_RDY;

         when "rst_sqm_adc(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_0;

         when "rst_sqm_adc(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_1;

         when "rst_sqm_adc(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_2;

         when "rst_sqm_adc(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_ADC_3;

         when "rst_sqm_dac(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_0;

         when "rst_sqm_dac(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_1;

         when "rst_sqm_dac(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_2;

         when "rst_sqm_dac(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQM_DAC_3;

         when "rst_sqa_mux(0)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_0;

         when "rst_sqa_mux(1)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_1;

         when "rst_sqa_mux(2)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_2;

         when "rst_sqa_mux(3)      "   =>
            o_fld_dr_ind := c_DR_D_RST_SQA_MUX_3;

         when "sync                "   =>
            o_fld_dr_ind := c_DR_SYNC;

         when "sqm_adc_pwdn(0)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_0;

         when "sqm_adc_pwdn(1)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_1;

         when "sqm_adc_pwdn(2)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_2;

         when "sqm_adc_pwdn(3)     "   =>
            o_fld_dr_ind := c_DR_SQM_ADC_PWDN_3;

         when "sqm_dac_sleep(0)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_0;

         when "sqm_dac_sleep(1)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_1;

         when "sqm_dac_sleep(2)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_2;

         when "sqm_dac_sleep(3)    "   =>
            o_fld_dr_ind := c_DR_SQM_DAC_SLEEP_3;

         when "clk_sqm_adc(0)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_0;

         when "clk_sqm_adc(1)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_1;

         when "clk_sqm_adc(2)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_2;

         when "clk_sqm_adc(3)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_ADC_3;

         when "clk_sqm_dac(0)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_0;

         when "clk_sqm_dac(1)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_1;

         when "clk_sqm_dac(2)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_2;

         when "clk_sqm_dac(3)      "   =>
            o_fld_dr_ind := c_DR_CLK_SQM_DAC_3;

         when "fpa_conf_busy(0)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_0;

         when "fpa_conf_busy(1)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_1;

         when "fpa_conf_busy(2)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_2;

         when "fpa_conf_busy(3)    "   =>
            o_fld_dr_ind := c_DR_FPA_CONF_BUSY_3;

         when others                   =>
            o_fld_dr_ind := c_DR_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_dr_pad, c_PAD, o_fld_dr);

   end get_dr_index;

   -- ------------------------------------------------------------------------------------------------------
   --! Get the first field (check parameters enable name) included in line and
   --!  get the associated check parameters enable index
   -- ------------------------------------------------------------------------------------------------------
   procedure get_ce_index
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_ce             : out    line                                                                 ; --  Field check parameters enable
         o_fld_ce_ind         : out    integer range 0 to c_CE_S+1                                            --  Field check parameters enable index (equal to c_CE_S if field not recognized)
   ) is
   variable v_fld_ce_pad      : line                                                                        ; --  Field check parameters enable with padding
   begin

      -- Get the check parameters enable name
      rfield_pad(b_line, c_PAD, c_SIG_NAME_STR_MAX_S, v_fld_ce_pad);

      -- Return field discrete output index
      case v_fld_ce_pad(1 to c_SIG_NAME_STR_MAX_S) is
         when "clk                 "   =>
            o_fld_ce_ind := c_CE_CLK;

         when "clk_sqm_adc         "   =>
            o_fld_ce_ind := c_CE_CK1_ADC;

         when "clk_sqm_pls_shape   "   =>
            o_fld_ce_ind := c_CE_CK1_PLS;

         when "clk_sqm_adc(0)      "   =>
            o_fld_ce_ind := c_CE_C0_CK1_ADC;

         when "clk_sqm_adc(1)      "   =>
            o_fld_ce_ind := c_CE_C1_CK1_ADC;

         when "clk_sqm_adc(2)      "   =>
            o_fld_ce_ind := c_CE_C2_CK1_ADC;

         when "clk_sqm_adc(3)      "   =>
            o_fld_ce_ind := c_CE_C3_CK1_ADC;

         when "clk_sqm_dac(0)      "   =>
            o_fld_ce_ind := c_CE_C0_CK1_DAC;

         when "clk_sqm_dac(1)      "   =>
            o_fld_ce_ind := c_CE_C1_CK1_DAC;

         when "clk_sqm_dac(2)      "   =>
            o_fld_ce_ind := c_CE_C2_CK1_DAC;

         when "clk_sqm_dac(3)      "   =>
            o_fld_ce_ind := c_CE_C3_CK1_DAC;

         when "clk_science_01      "   =>
            o_fld_ce_ind := c_CE_CLK_SC_01;

         when "clk_science_23      "   =>
            o_fld_ce_ind := c_CE_CLK_SC_23;

         when "spi_hk              "   =>
            o_fld_ce_ind := c_SPIE_HK;

         when "spi_sqa_lsb(0)      "   =>
            o_fld_ce_ind := c_SPIE_C0_SQA_LSB;

         when "spi_sqa_off(0)      "   =>
            o_fld_ce_ind := c_SPIE_C0_SQA_OFF;

         when "spi_sqa_lsb(1)      "   =>
            o_fld_ce_ind := c_SPIE_C1_SQA_LSB;

         when "spi_sqa_off(1)      "   =>
            o_fld_ce_ind := c_SPIE_C1_SQA_OFF;

         when "spi_sqa_lsb(2)      "   =>
            o_fld_ce_ind := c_SPIE_C2_SQA_LSB;

         when "spi_sqa_off(2)      "   =>
            o_fld_ce_ind := c_SPIE_C2_SQA_OFF;

         when "spi_sqa_lsb(3)      "   =>
            o_fld_ce_ind := c_SPIE_C3_SQA_LSB;

         when "spi_sqa_off(3)      "   =>
            o_fld_ce_ind := c_SPIE_C3_SQA_OFF;

         when "pulse_shaping       "   =>
            o_fld_ce_ind := c_E_PLS_SHP;

         when others                   =>
            o_fld_ce_ind := c_CE_S;

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_ce_pad, c_PAD, o_fld_ce);

   end get_ce_index;

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
         when "DATA_ACQ_MODE                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_AQMDE;

         when "SQ_MUX_FB_ON_OFF              "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFMD;

         when "SQ_AMP_OFFSET_MODE            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFM;

         when "TEST_PATTERN                  "  =>
            o_fld_add_val:= c_EP_CMD_ADD_TSTPT;

         when "TEST_PATTERN_ENABLE           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_TSTEN;

         when "BOXCAR_LENGTH                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_BXLGT;

         when "DELOCK_FLAG                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLFLG;

         when "Status                        "  =>
            o_fld_add_val:= c_EP_CMD_ADD_STATUS;

         when "Fw_Version                    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_FW_VER;

         when "Hw_Version                    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_HW_VER;

         when "C0_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(0);

         when "C0_KI_KNORM                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(0);

         when "C0_KNORM                      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(0);

         when "C0_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(0);

         when "C0_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(0);

         when "C0_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(0);

         when "C0_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(0);

         when "C0_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(0);

         when "C0_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(0);

         when "C0_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(0);

         when "C0_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(0);

         when "C0_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(0);

         when "C0_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(0);

         when "C0_FB1_PULSE_SHAPING          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(0);

         when "C0_FB1_PULSE_SHAPING_SELECTION"  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(0);

         when "C0_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(0);

         when "C0_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(0);

         when "C0_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(0);

         when "C1_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(1);

         when "C1_KI_KNORM                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(1);

         when "C1_KNORM                      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(1);

         when "C1_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(1);

         when "C1_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(1);

         when "C1_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(1);

         when "C1_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(1);

         when "C1_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(1);

         when "C1_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(1);

         when "C1_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(1);

         when "C1_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(1);

         when "C1_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(1);

         when "C1_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(1);

         when "C1_FB1_PULSE_SHAPING          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(1);

         when "C1_FB1_PULSE_SHAPING_SELECTION"  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(1);

         when "C1_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(1);

         when "C1_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(1);

         when "C1_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(1);

         when "C2_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(2);

         when "C2_KI_KNORM                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(2);

         when "C2_KNORM                      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(2);

         when "C2_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(2);

         when "C2_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(2);

         when "C2_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(2);

         when "C2_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(2);

         when "C2_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(2);

         when "C2_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(2);

         when "C2_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(2);

         when "C2_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(2);

         when "C2_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(2);

         when "C2_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(2);

         when "C2_FB1_PULSE_SHAPING          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(2);

         when "C2_FB1_PULSE_SHAPING_SELECTION"  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(2);

         when "C2_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(2);

         when "C2_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(2);

         when "C2_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(2);

         when "C3_A                          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PARMA(3);

         when "C3_KI_KNORM                   "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KIKNM(3);

         when "C3_KNORM                      "  =>
            o_fld_add_val:= c_EP_CMD_ADD_KNORM(3);

         when "C3_MUX_SQ_FB0                 "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFB0(3);

         when "C3_MUX_SQ_LOCKPOINT_V         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMLKV(3);

         when "C3_MUX_SQ_FB_MODE             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBM(3);

         when "C3_AMP_SQ_OFFSET_FINE         "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFF(3);

         when "C3_AMP_SQ_OFFSET_COARSE       "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFC(3);

         when "C3_AMP_SQ_OFFSET_LSB          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOFL(3);

         when "C3_MUX_SQ_FB_DELAY            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMFBD(3);

         when "C3_AMP_SQ_OFFSET_DAC_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAODD(3);

         when "C3_AMP_SQ_OFFSET_MUX_DELAY    "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SAOMD(3);

         when "C3_SAMPLING_DELAY             "  =>
            o_fld_add_val:= c_EP_CMD_ADD_SMPDL(3);

         when "C3_FB1_PULSE_SHAPING          "  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSH(3);

         when "C3_FB1_PULSE_SHAPING_SELECTION"  =>
            o_fld_add_val:= c_EP_CMD_ADD_PLSSS(3);

         when "C3_RELOCK_DELAY               "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLDEL(3);

         when "C3_RELOCK_THRESHOLD           "  =>
            o_fld_add_val:= c_EP_CMD_ADD_RLTHR(3);

         when "C3_DELOCK_COUNTERS            "  =>
            o_fld_add_val:= c_EP_CMD_ADD_DLCNT(3);

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
   --! Get the first field (science packet type) included in line and
   --!  get the associated data value
   -- ------------------------------------------------------------------------------------------------------
   procedure get_sc_pkt_type
   (     b_line               : inout  line                                                                 ; --  Line to analysis
         o_fld_sc_pkt         : out    line                                                                 ; --  Field science packet type
         o_fld_sc_pkt_val     : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                         --  Field science packet type value
   ) is
   variable v_fld_sc_pkt_pad  : line                                                                        ; --  Field science packet type with padding
   begin

      -- Get the science packet type name
      rfield_pad(b_line, c_PAD, c_CMD_NAME_STR_MAX_S, v_fld_sc_pkt_pad);

      -- Return the science packet type value
      case v_fld_sc_pkt_pad(1 to c_CMD_NAME_STR_MAX_S) is
         when "science_data                  "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_SC_DTA;

         when "test_pattern                  "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_TST_PAT;

         when "adc_dump                      "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_ADC_DMP;

         when "error_signal                  "  =>
            o_fld_sc_pkt_val:= c_SC_CTRL_ERRS;

         when others                            =>
            o_fld_sc_pkt_val:= c_RET_UKWN(o_fld_sc_pkt_val'range);

      end case;

      -- Drop padding character(s)
      drop_line_char(v_fld_sc_pkt_pad, c_PAD, o_fld_sc_pkt);

   end get_sc_pkt_type;

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

end package body;