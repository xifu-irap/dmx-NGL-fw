# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
#
#                            dmx-fw is free software: you can redistribute it and/or modify
#                            it under the terms of the GNU General Public License as published by
#                            the Free Software Foundation, either version 3 of the License, or
#                            (at your option) any later version.
#
#                            This program is distributed in the hope that it will be useful,
#                            but WITHOUT ANY WARRANTY; without even the implied warranty of
#                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                            GNU General Public License for more details.
#
#                            You should have received a copy of the GNU General Public License
#                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    email                   slaurent@nanoxplore.com
#    @file                   dmx_fw_vsim.do
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Modelsim script for dmx_fw_vsim compilation files:
#                                *  Command line argument 1: IP directory
#                                *  Command line argument 2: Source directory
#                                *  Command line argument 3: Testbench directory
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###################### Parameters ##########################
quietly set IP_DIR $1
quietly set SRC_DIR $2
quietly set TB_DIR $3

###################### Files compilation ###################
   vlib work
   vcom -work work -2008                  \
      ${SRC_DIR}/pkg_type.vhd             \
      ${SRC_DIR}/pkg_func_math.vhd        \
      ${IP_DIR}/pkg_fpga_tech.vhd         \
      ${SRC_DIR}/pkg_project.vhd          \
      ${SRC_DIR}/pkg_ep_cmd.vhd           \
      ${SRC_DIR}/pkg_ep_cmd_type.vhd      \
      ${SRC_DIR}/multiplexer.vhd          \
      ${SRC_DIR}/resize_stall_msb.vhd     \
      ${SRC_DIR}/cmd_im_ck.vhd            \
      ${SRC_DIR}/mem_scrubbing.vhd        \
      ${IP_DIR}/lowskew.vhd               \
      ${IP_DIR}/dsp.vhd                   \
      ${IP_DIR}/pll.vhd                   \
      ${IP_DIR}/dmem_ecc.vhd              \
      ${SRC_DIR}/im_ck.vhd                \
      ${SRC_DIR}/rst_clk_mgt.vhd          \
      ${SRC_DIR}/in_rs_clk.vhd            \
      ${SRC_DIR}/round_sat.vhd            \
      ${SRC_DIR}/adder_sat.vhd            \
      ${SRC_DIR}/spi_slave.vhd            \
      ${SRC_DIR}/sts_err_wrt_mgt.vhd      \
      ${SRC_DIR}/sts_err_out_mgt.vhd      \
      ${SRC_DIR}/sts_err_dis_mgt.vhd      \
      ${SRC_DIR}/ep_cmd.vhd               \
      ${SRC_DIR}/mem_data_rd_mux.vhd      \
      ${SRC_DIR}/ep_cmd_tx_wd.vhd         \
      ${SRC_DIR}/mem_in_gen.vhd           \
      ${SRC_DIR}/register_cs_mgt.vhd      \
      ${SRC_DIR}/rg_aqmde_mgt.vhd         \
      ${SRC_DIR}/rg_tsten_mgt.vhd         \
      ${SRC_DIR}/register_mgt.vhd         \
      ${SRC_DIR}/dmx_cmd.vhd              \
      ${SRC_DIR}/spi_master.vhd           \
      ${SRC_DIR}/science_data_tx.vhd      \
      ${SRC_DIR}/science_data_mgt.vhd     \
      ${SRC_DIR}/hk_mgt.vhd               \
      ${SRC_DIR}/adder_acc.vhd            \
      ${SRC_DIR}/squid_adc_mgt.vhd        \
      ${SRC_DIR}/squid_data_proc.vhd      \
      ${SRC_DIR}/sqm_fbk_mgt.vhd          \
      ${SRC_DIR}/pulse_shaping.vhd        \
      ${SRC_DIR}/sqm_dac_mgt.vhd          \
      ${SRC_DIR}/sqa_fbk_mgt.vhd          \
      ${SRC_DIR}/sqa_dac_mgt.vhd          \
      ${SRC_DIR}/sqm_spi_mgt.vhd          \
      ${SRC_DIR}/test_pattern_gen.vhd     \
      ${SRC_DIR}/relock.vhd               \
      ${SRC_DIR}/top_dmx.vhd              \
      ${TB_DIR}/pkg_model.vhd             \
      ${TB_DIR}/pkg_mess.vhd              \
      ${TB_DIR}/pkg_str_fld_assoc.vhd     \
      ${TB_DIR}/pkg_func_cmd_spi.vhd      \
      ${TB_DIR}/pkg_func_cmd_script.vhd   \
      ${TB_DIR}/pkg_func_parser.vhd       \
      ${TB_DIR}/pkg_science_data.vhd      \
      ${TB_DIR}/adc_ad9254_model.vhd      \
      ${TB_DIR}/dac_dac5675a_model.vhd    \
      ${TB_DIR}/dac121s101_model.vhd      \
      ${TB_DIR}/adc128s102_model.vhd      \
      ${TB_DIR}/cd74hc4051_model.vhd      \
      ${TB_DIR}/clock_check.vhd           \
      ${TB_DIR}/clock_check_model.vhd     \
      ${TB_DIR}/clock_model.vhd           \
      ${TB_DIR}/spi_check.vhd             \
      ${TB_DIR}/spi_check_model.vhd       \
      ${TB_DIR}/ep_spi_model.vhd          \
      ${TB_DIR}/pulse_shaping_check.vhd   \
      ${TB_DIR}/sqa_dac_model.vhd         \
      ${TB_DIR}/squid_model.vhd           \
      ${TB_DIR}/science_data_rx.vhd       \
      ${TB_DIR}/science_data_check.vhd    \
      ${TB_DIR}/science_data_model.vhd    \
      ${TB_DIR}/hk_model.vhd              \
      ${TB_DIR}/parser.vhd                \
      ${TB_DIR}/fpga_system_fpasim_top.vhd\
      ${TB_DIR}/top_dmx_tb.vhd