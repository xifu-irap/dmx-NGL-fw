# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
#
#                            dmx-ngl-fw is free software: you can redistribute it and/or modify
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
#    @file                   project_constraints.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap project constraints
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def synthesis_constraints(p,variant,option):
    if variant == 'NG-LARGE' or variant == 'NG-LARGE-EMBEDDED':

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[0].I_sqm_adc ]', 'clk_squid_adc_0', 'Soft', 30, 22, 1, 1, 'CLK_SQM_ADC_0', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[1].I_sqm_adc ]', 'clk_squid_adc_1', 'Soft', 41,  2, 2, 1, 'CLK_SQM_ADC_1', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[2].I_sqm_adc ]', 'clk_squid_adc_2', 'Soft', 13,  2, 1, 1, 'CLK_SQM_ADC_2', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[3].I_sqm_adc ]', 'clk_squid_adc_3', 'Soft',  8, 22, 1, 1, 'CLK_SQM_ADC_3', False)

        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc ]', 'cmd_ck_adc_0', 'Soft', 30, 22, 1, 1, 'CLK_SQM_ADC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc ]', 'cmd_ck_adc_1', 'Soft', 41,  2, 2, 1, 'CLK_SQM_ADC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc ]', 'cmd_ck_adc_2', 'Soft', 13,  2, 1, 1, 'CLK_SQM_ADC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc ]', 'cmd_ck_adc_3', 'Soft',  8, 22, 1, 1, 'CLK_SQM_ADC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sqm_adc ]', 'rst_sys_sqm_adc_0', 'Soft', 31, 16, 1, 4, 'SQM_ADC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sqm_adc ]', 'rst_sys_sqm_adc_1', 'Soft', 36,  6, 1, 4, 'SQM_ADC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sqm_adc ]', 'rst_sys_sqm_adc_2', 'Soft', 12,  6, 1, 4, 'SQM_ADC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sqm_adc ]', 'rst_sys_sqm_adc_3', 'Soft', 13, 16, 1, 4, 'SQM_ADC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sqm_adc_rs ]', 'sync_sqm_adc_rs_0', 'Soft', 31, 16, 1, 4, 'SQM_ADC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sqm_adc_rs ]', 'sync_sqm_adc_rs_1', 'Soft', 36,  6, 1, 4, 'SQM_ADC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sqm_adc_rs ]', 'sync_sqm_adc_rs_2', 'Soft', 12,  6, 1, 4, 'SQM_ADC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sqm_adc_rs ]', 'sync_sqm_adc_rs_3', 'Soft', 13, 16, 1, 4, 'SQM_ADC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].I_aqmde_dmp_cmp ]', 'aqmde_dmp_cmp_0', 'Soft', 31, 16, 1, 4, 'SQM_ADC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].I_aqmde_dmp_cmp ]', 'aqmde_dmp_cmp_1', 'Soft', 36,  6, 1, 4, 'SQM_ADC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].I_aqmde_dmp_cmp ]', 'aqmde_dmp_cmp_2', 'Soft', 12,  6, 1, 4, 'SQM_ADC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].I_aqmde_dmp_cmp ]', 'aqmde_dmp_cmp_3', 'Soft', 13, 16, 1, 4, 'SQM_ADC_3', False)

        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[0].I_squid_adc_mgt ]', 'squid_adc_mgt_0', 'Soft', 31, 16, 1, 4, 'SQM_ADC_0', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[1].I_squid_adc_mgt ]', 'squid_adc_mgt_1', 'Soft', 36,  6, 1, 4, 'SQM_ADC_1', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[2].I_squid_adc_mgt ]', 'squid_adc_mgt_2', 'Soft', 12,  6, 1, 4, 'SQM_ADC_2', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[3].I_squid_adc_mgt ]', 'squid_adc_mgt_3', 'Soft', 13, 16, 1, 4, 'SQM_ADC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[0].I_sqm_dac_out ]', 'clk_squid_dac_0', 'Soft', 22, 22, 1, 1, 'CLK_SQM_DAC_0', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[1].I_sqm_dac_out ]', 'clk_squid_dac_1', 'Soft', 35,  2, 1, 1, 'CLK_SQM_DAC_1', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[2].I_sqm_dac_out ]', 'clk_squid_dac_2', 'Soft', 19,  2, 1, 1, 'CLK_SQM_DAC_2', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[3].I_sqm_dac_out ]', 'clk_squid_dac_3', 'Soft', 14, 22, 1, 1, 'CLK_SQM_DAC_3', False)

        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac ]', 'cmd_ck_sqm_dac_0', 'Soft', 22, 22, 1, 1, 'CLK_SQM_DAC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac ]', 'cmd_ck_sqm_dac_1', 'Soft', 35,  2, 1, 1, 'CLK_SQM_DAC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac ]', 'cmd_ck_sqm_dac_2', 'Soft', 19,  2, 1, 1, 'CLK_SQM_DAC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac ]', 'cmd_ck_sqm_dac_3', 'Soft', 14, 22, 1, 1, 'CLK_SQM_DAC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sqm_dac ]', 'rst_sys_sqm_dac_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sqm_dac ]', 'rst_sys_sqm_dac_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sqm_dac ]', 'rst_sys_sqm_dac_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sqm_dac ]', 'rst_sys_sqm_dac_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sqm_dac_rs ]', 'sync_sqm_dac_rs_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sqm_dac_rs ]', 'sync_sqm_dac_rs_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sqm_dac_rs ]', 'sync_sqm_dac_rs_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sqm_dac_rs ]', 'sync_sqm_dac_rs_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[0].G_plsss[0].I_plsss ]', 'plsss0_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_plsss[1].I_plsss ]', 'plsss1_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[1].G_plsss[0].I_plsss ]', 'plsss0_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_plsss[1].I_plsss ]', 'plsss1_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[2].G_plsss[0].I_plsss ]', 'plsss0_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_plsss[1].I_plsss ]', 'plsss1_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[3].G_plsss[0].I_plsss ]', 'plsss0_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_plsss[1].I_plsss ]', 'plsss1_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_smfbd[0].I_smfbd ]', 'smfbd0_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_smfbd[1].I_smfbd ]', 'smfbd0_1', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_smfbd[2].I_smfbd ]', 'smfbd0_2', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_smfbd[3].I_smfbd ]', 'smfbd0_3', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_smfbd[4].I_smfbd ]', 'smfbd0_4', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_smfbd[0].I_smfbd ]', 'smfbd1_0', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_smfbd[1].I_smfbd ]', 'smfbd1_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_smfbd[2].I_smfbd ]', 'smfbd1_2', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_smfbd[3].I_smfbd ]', 'smfbd1_3', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_smfbd[4].I_smfbd ]', 'smfbd1_4', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_smfbd[0].I_smfbd ]', 'smfbd2_0', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_smfbd[1].I_smfbd ]', 'smfbd2_1', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_smfbd[2].I_smfbd ]', 'smfbd2_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_smfbd[3].I_smfbd ]', 'smfbd2_3', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_smfbd[4].I_smfbd ]', 'smfbd2_4', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_smfbd[0].I_smfbd ]', 'smfbd3_0', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_smfbd[1].I_smfbd ]', 'smfbd3_1', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_smfbd[2].I_smfbd ]', 'smfbd3_2', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_smfbd[3].I_smfbd ]', 'smfbd3_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_smfbd[4].I_smfbd ]', 'smfbd3_4', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)

        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[0].I_sqm_dac_mgt ]', 'sqm_dac_mgt_0', 'Soft', 25, 18, 1, 4, 'SQM_DAC_0', False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[1].I_sqm_dac_mgt ]', 'sqm_dac_mgt_1', 'Soft', 33,  4, 1, 4, 'SQM_DAC_1', False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[2].I_sqm_dac_mgt ]', 'sqm_dac_mgt_2', 'Soft', 15,  4, 1, 4, 'SQM_DAC_2', False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[3].I_sqm_dac_mgt ]', 'sqm_dac_mgt_3', 'Soft', 17, 18, 1, 4, 'SQM_DAC_3', False)

        p.constrainModule('|-> sqm_fbk_mgt [ G_column_mgt[0].I_sqm_fbk_mgt ]', 'sqm_fbk_mgt_0', 'Soft', 24, 16, 2, 4, 'SQM_FBK_0', False)
        p.constrainModule('|-> sqm_fbk_mgt [ G_column_mgt[1].I_sqm_fbk_mgt ]', 'sqm_fbk_mgt_1', 'Soft', 32,  6, 2, 4, 'SQM_FBK_1', False)
        p.constrainModule('|-> sqm_fbk_mgt [ G_column_mgt[2].I_sqm_fbk_mgt ]', 'sqm_fbk_mgt_2', 'Soft', 15,  6, 2, 4, 'SQM_FBK_2', False)
        p.constrainModule('|-> sqm_fbk_mgt [ G_column_mgt[3].I_sqm_fbk_mgt ]', 'sqm_fbk_mgt_3', 'Soft', 17, 16, 2, 4, 'SQM_FBK_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID AMP DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sqa_dac ]', 'rst_sys_sqa_dac_0', 'Soft', 48,  6, 1, 1, 'SQA_DAC_RST_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sqa_dac ]', 'rst_sys_sqa_dac_1', 'Soft', 48,  2, 1, 1, 'SQA_DAC_RST_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sqa_dac ]', 'rst_sys_sqa_dac_2', 'Soft',  1,  2, 1, 1, 'SQA_DAC_RST_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sqa_dac ]', 'rst_sys_sqa_dac_3', 'Soft',  1,  6, 1, 1, 'SQA_DAC_RST_3', False)

        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[0].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_0', 'Soft', 45,  6, 3, 6, 'SQA_FBK_0', False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[1].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_1', 'Soft', 45,  2, 3, 4, 'SQA_FBK_1', False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[2].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_2', 'Soft',  3,  2, 3, 6, 'SQA_FBK_2', False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[3].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_3', 'Soft',  3,  6, 3, 6, 'SQA_FBK_3', False)

        p.constrainModule('|-> spi_master(XBF188228) [ G_column_mgt[0].I_sqa_dac_mgt|I_sqa_spi_master ]', 'sqa_spi_master_0', 'Soft', 48,  6, 1, 1, 'SQA_SPI_0', False)
        p.constrainModule('|-> spi_master(XBF188228) [ G_column_mgt[1].I_sqa_dac_mgt|I_sqa_spi_master ]', 'sqa_spi_master_1', 'Soft', 48,  2, 1, 1, 'SQA_SPI_1', False)
        p.constrainModule('|-> spi_master(XBF188228) [ G_column_mgt[2].I_sqa_dac_mgt|I_sqa_spi_master ]', 'sqa_spi_master_2', 'Soft',  1,  2, 1, 1, 'SQA_SPI_2', False)
        p.constrainModule('|-> spi_master(XBF188228) [ G_column_mgt[3].I_sqa_dac_mgt|I_sqa_spi_master ]', 'sqa_spi_master_3', 'Soft',  1,  6, 1, 1, 'SQA_SPI_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sqa_dac_rs ]', 'sync_sqa_dac_rs_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sqa_dac_rs ]', 'sync_sqa_dac_rs_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sqa_dac_rs ]', 'sync_sqa_dac_rs_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sqa_dac_rs ]', 'sync_sqa_dac_rs_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[0].I_saofl ]', 'saofl0_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[1].I_saofl ]', 'saofl1_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[2].I_saofl ]', 'saofl2_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[3].I_saofl ]', 'saofl3_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[4].I_saofl ]', 'saofl4_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[5].I_saofl ]', 'saofl5_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[6].I_saofl ]', 'saofl6_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[7].I_saofl ]', 'saofl7_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[8].I_saofl ]', 'saofl8_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[9].I_saofl ]', 'saofl9_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[10].I_saofl ]', 'saofl10_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saofl[11].I_saofl ]', 'saofl11_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[0].I_saofl ]', 'saofl0_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[1].I_saofl ]', 'saofl1_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[2].I_saofl ]', 'saofl2_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[3].I_saofl ]', 'saofl3_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[4].I_saofl ]', 'saofl4_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[5].I_saofl ]', 'saofl5_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[6].I_saofl ]', 'saofl6_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[7].I_saofl ]', 'saofl7_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[8].I_saofl ]', 'saofl8_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[9].I_saofl ]', 'saofl9_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[10].I_saofl ]', 'saofl10_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saofl[11].I_saofl ]', 'saofl11_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[0].I_saofl ]', 'saofl0_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[1].I_saofl ]', 'saofl1_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[2].I_saofl ]', 'saofl2_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[3].I_saofl ]', 'saofl3_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[4].I_saofl ]', 'saofl4_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[5].I_saofl ]', 'saofl5_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[6].I_saofl ]', 'saofl6_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[7].I_saofl ]', 'saofl7_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[8].I_saofl ]', 'saofl8_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[9].I_saofl ]', 'saofl9_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[10].I_saofl ]', 'saofl10_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saofl[11].I_saofl ]', 'saofl11_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[0].I_saofl ]', 'saofl0_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[1].I_saofl ]', 'saofl1_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[2].I_saofl ]', 'saofl2_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[3].I_saofl ]', 'saofl3_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[4].I_saofl ]', 'saofl4_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[5].I_saofl ]', 'saofl5_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[6].I_saofl ]', 'saofl6_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[7].I_saofl ]', 'saofl7_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[8].I_saofl ]', 'saofl8_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[9].I_saofl ]', 'saofl9_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[10].I_saofl ]', 'saofl10_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saofl[11].I_saofl ]', 'saofl11_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saomd[0].I_saomd ]','saomd_0_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saomd[1].I_saomd ]','saomd_0_1', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saomd[2].I_saomd ]','saomd_0_2', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saomd[3].I_saomd ]','saomd_0_3', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saomd[4].I_saomd ]','saomd_0_4', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saomd[0].I_saomd ]','saomd_1_0', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saomd[1].I_saomd ]','saomd_1_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saomd[2].I_saomd ]','saomd_1_2', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saomd[3].I_saomd ]','saomd_1_3', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saomd[4].I_saomd ]','saomd_1_4', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saomd[0].I_saomd ]','saomd_2_0', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saomd[1].I_saomd ]','saomd_2_1', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saomd[2].I_saomd ]','saomd_2_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saomd[3].I_saomd ]','saomd_2_3', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saomd[4].I_saomd ]','saomd_2_4', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saomd[0].I_saomd ]','saomd_3_0', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saomd[1].I_saomd ]','saomd_3_1', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saomd[2].I_saomd ]','saomd_3_2', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saomd[3].I_saomd ]','saomd_3_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saomd[4].I_saomd ]','saomd_3_4', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[0].I_saodd ]','saodd_0_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[1].I_saodd ]','saodd_0_1', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[2].I_saodd ]','saodd_0_2', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[3].I_saodd ]','saodd_0_3', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[4].I_saodd ]','saodd_0_4', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[5].I_saodd ]','saodd_0_5', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[6].I_saodd ]','saodd_0_6', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[7].I_saodd ]','saodd_0_7', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[8].I_saodd ]','saodd_0_8', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_saodd[9].I_saodd ]','saodd_0_9', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[0].I_saodd ]','saodd_1_0', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[1].I_saodd ]','saodd_1_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[2].I_saodd ]','saodd_1_2', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[3].I_saodd ]','saodd_1_3', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[4].I_saodd ]','saodd_1_4', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[5].I_saodd ]','saodd_1_5', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[6].I_saodd ]','saodd_1_6', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[7].I_saodd ]','saodd_1_7', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[8].I_saodd ]','saodd_1_8', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_saodd[9].I_saodd ]','saodd_1_9', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[0].I_saodd ]','saodd_2_0', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[1].I_saodd ]','saodd_2_1', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[2].I_saodd ]','saodd_2_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[3].I_saodd ]','saodd_2_3', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[4].I_saodd ]','saodd_2_4', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[5].I_saodd ]','saodd_2_5', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[6].I_saodd ]','saodd_2_6', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[7].I_saodd ]','saodd_2_7', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[8].I_saodd ]','saodd_2_8', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_saodd[9].I_saodd ]','saodd_2_9', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[0].I_saodd ]','saodd_3_0', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[1].I_saodd ]','saodd_3_1', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[2].I_saodd ]','saodd_3_2', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[3].I_saodd ]','saodd_3_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[4].I_saodd ]','saodd_3_4', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[5].I_saodd ]','saodd_3_5', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[6].I_saodd ]','saodd_3_6', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[7].I_saodd ]','saodd_3_7', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[8].I_saodd ]','saodd_3_8', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_saodd[9].I_saodd ]','saodd_3_9', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)

        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[0].I_sqa_dac_mgt ]', 'sqa_dac_mgt_0', 'Soft', 47,  6, 2, 1, 'SQA_DAC_0', False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[1].I_sqa_dac_mgt ]', 'sqa_dac_mgt_1', 'Soft', 47,  2, 2, 1, 'SQA_DAC_1', False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[2].I_sqa_dac_mgt ]', 'sqa_dac_mgt_2', 'Soft',  2,  2, 2, 1, 'SQA_DAC_2', False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[3].I_sqa_dac_mgt ]', 'sqa_dac_mgt_3', 'Soft',  2,  6, 2, 1, 'SQA_DAC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   EP SPI constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> ep_cmd [ I_ep_cmd ]', 'ep_cmd', 'Soft', 23, 12, 5, 1, 'REGISTER_MGT', False)

        # ------------------------------------------------------------------------------------------------------
        #   Science transmit constraints
        # ------------------------------------------------------------------------------------------------------

        # ------------------------------------------------------------------------------------------------------
        #   Internal constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X41D2BCF8) [ I_rst_clk_mgt|I_rst_first_pipe ]', 'rst_first_pipe', 'Soft', 25, 12, 1, 1, 'RST', False)
        p.constrainModule('|-> signal_reg(XC85BAA8D) [ I_rst_clk_mgt|I_rst ]', 'rst', 'Soft', 25, 12, 1, 1, 'RST', False)
        p.constrainModule('|-> register_mgt [ I_register_mgt ]', 'register_mgt', 'Soft', 23, 12, 5, 1, 'REGISTER_MGT', False)


    if option=='USE_DSP':
        p.addMappingDirective('getModels(*)','ADD','DSP')

def placing_constraints(p,variant,option):
    print("No placing common constraints")

def routing_constraints(p,variant,option):
    print("No routing common constraints")

def add_constraints(p,variant,step,option):
    if step == "Synthesize":
        synthesis_constraints(p,variant,option)
    elif step == "Place":
        placing_constraints(p,variant,option)
    elif step == "Route":
        routing_constraints(p,variant,option)
