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
        #   SQUID1 ADC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[0].I_squid1_adc ]', 'clk_squid_adc_0', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_0', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[1].I_squid1_adc ]', 'clk_squid_adc_1', 'Soft', 41,  2, 1, 1, 'CLK_SQUID1_ADC_1', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[2].I_squid1_adc ]', 'clk_squid_adc_2', 'Soft', 13,  2, 1, 1, 'CLK_SQUID1_ADC_2', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[3].I_squid1_adc ]', 'clk_squid_adc_3', 'Soft',  8, 22, 1, 1, 'CLK_SQUID1_ADC_3', False)

        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_0', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_1', 'Soft', 41,  2, 1, 1, 'CLK_SQUID1_ADC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_2', 'Soft', 13,  2, 1, 1, 'CLK_SQUID1_ADC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_3', 'Soft',  8, 22, 1, 1, 'CLK_SQUID1_ADC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID1 ADC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sq1_adc ]', 'rst_sys_sq1_adc_0', 'Soft', 33, 20, 1, 4, 'SQUID1_ADC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sq1_adc ]', 'rst_sys_sq1_adc_1', 'Soft', 39,  2, 1, 4, 'SQUID1_ADC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sq1_adc ]', 'rst_sys_sq1_adc_2', 'Soft',  9,  2, 1, 4, 'SQUID1_ADC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sq1_adc ]', 'rst_sys_sq1_adc_3', 'Soft', 11, 20, 1, 4, 'SQUID1_ADC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sq1_adc_rs ]', 'sync_sq1_adc_rs_0', 'Soft', 33, 20, 1, 4, 'SQUID1_ADC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sq1_adc_rs ]', 'sync_sq1_adc_rs_1', 'Soft', 39,  2, 1, 4, 'SQUID1_ADC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sq1_adc_rs ]', 'sync_sq1_adc_rs_2', 'Soft',  9,  2, 1, 4, 'SQUID1_ADC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sq1_adc_rs ]', 'sync_sq1_adc_rs_3', 'Soft', 11, 20, 1, 4, 'SQUID1_ADC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].I_tm_mode_dmp_cmp ]', 'tm_mode_dmp_cmp_0', 'Soft', 33, 20, 1, 4, 'SQUID1_ADC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].I_tm_mode_dmp_cmp ]', 'tm_mode_dmp_cmp_1', 'Soft', 39,  2, 1, 4, 'SQUID1_ADC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].I_tm_mode_dmp_cmp ]', 'tm_mode_dmp_cmp_2', 'Soft',  9,  2, 1, 4, 'SQUID1_ADC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].I_tm_mode_dmp_cmp ]', 'tm_mode_dmp_cmp_3', 'Soft', 11, 20, 1, 4, 'SQUID1_ADC_3', False)

        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[0].I_squid_adc_mgt ]', 'squid_adc_mgt_0', 'Soft', 33, 20, 1, 4, 'SQUID1_ADC_0', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[1].I_squid_adc_mgt ]', 'squid_adc_mgt_1', 'Soft', 39,  2, 1, 4, 'SQUID1_ADC_1', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[2].I_squid_adc_mgt ]', 'squid_adc_mgt_2', 'Soft',  9,  2, 1, 4, 'SQUID1_ADC_2', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[3].I_squid_adc_mgt ]', 'squid_adc_mgt_3', 'Soft', 11, 20, 1, 4, 'SQUID1_ADC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID1 DAC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[0].I_squid1_dac_out ]', 'clk_squid_dac_0', 'Soft', 22, 22, 1, 1, 'CLK_SQUID1_DAC_0', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[1].I_squid1_dac_out ]', 'clk_squid_dac_1', 'Soft', 35,  2, 1, 1, 'CLK_SQUID1_DAC_1', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[2].I_squid1_dac_out ]', 'clk_squid_dac_2', 'Soft', 19,  2, 1, 1, 'CLK_SQUID1_DAC_2', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[3].I_squid1_dac_out ]', 'clk_squid_dac_3', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_DAC_3', False)

        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_0', 'Soft', 22, 22, 1, 1, 'CLK_SQUID1_DAC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_1', 'Soft', 35,  2, 1, 1, 'CLK_SQUID1_DAC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_2', 'Soft', 19,  2, 1, 1, 'CLK_SQUID1_DAC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_3', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_DAC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID1 DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sq1_dac ]', 'rst_sys_sq1_dac_0', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sq1_dac ]', 'rst_sys_sq1_dac_1', 'Soft', 33,  4, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sq1_dac ]', 'rst_sys_sq1_dac_2', 'Soft', 15,  4, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sq1_dac ]', 'rst_sys_sq1_dac_3', 'Soft', 17, 18, 1, 4, 'SQUID1_DAC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sq1_dac_rs ]', 'sync_sq1_dac_rs_0', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sq1_dac_rs ]', 'sync_sq1_dac_rs_1', 'Soft', 33,  4, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sq1_dac_rs ]', 'sync_sq1_dac_rs_2', 'Soft', 15,  4, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sq1_dac_rs ]', 'sync_sq1_dac_rs_3', 'Soft', 17, 18, 1, 4, 'SQUID1_DAC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[0].G_sq1_fb_pls_set[0].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set0_0', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[1].G_sq1_fb_pls_set[0].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set0_1', 'Soft', 33,  4, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[2].G_sq1_fb_pls_set[0].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set0_2', 'Soft', 15,  4, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_register_mgt|G_column_mgt_out[3].G_sq1_fb_pls_set[0].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set0_3', 'Soft', 17, 18, 1, 4, 'SQUID1_DAC_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq1_fb_pls_set[1].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set1_0', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq1_fb_pls_set[1].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set1_1', 'Soft', 33,  4, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq1_fb_pls_set[1].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set1_2', 'Soft', 15,  4, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq1_fb_pls_set[1].I_sq1_fb_pls_set ]', 'sq1_fb_pls_set1_3', 'Soft', 17, 18, 1, 4, 'SQUID1_DAC_3', False)

        p.constrainModule('|-> squid1_fbk_mgt [ G_column_mgt[0].I_squid1_fbk_mgt ]', 'squid1_fbk_mgt_0', 'Soft', 24, 16, 2, 4, 'SQUID1_FBK_0', False)
        p.constrainModule('|-> squid1_fbk_mgt [ G_column_mgt[1].I_squid1_fbk_mgt ]', 'squid1_fbk_mgt_1', 'Soft', 32,  6, 2, 4, 'SQUID1_FBK_1', False)
        p.constrainModule('|-> squid1_fbk_mgt [ G_column_mgt[2].I_squid1_fbk_mgt ]', 'squid1_fbk_mgt_2', 'Soft', 15,  6, 2, 4, 'SQUID1_FBK_2', False)
        p.constrainModule('|-> squid1_fbk_mgt [ G_column_mgt[3].I_squid1_fbk_mgt ]', 'squid1_fbk_mgt_3', 'Soft', 17, 16, 2, 4, 'SQUID1_FBK_3', False)

        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[0].I_squid1_dac_mgt ]', 'squid1_dac_mgt_0', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[1].I_squid1_dac_mgt ]', 'squid1_dac_mgt_1', 'Soft', 33,  4, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[2].I_squid1_dac_mgt ]', 'squid1_dac_mgt_2', 'Soft', 15,  4, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[3].I_squid1_dac_mgt ]', 'squid1_dac_mgt_3', 'Soft', 17, 18, 1, 4, 'SQUID1_DAC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID2 DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[0].I_rst_sys_sq2_dac ]', 'rst_sys_sq2_dac_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[1].I_rst_sys_sq2_dac ]', 'rst_sys_sq2_dac_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[2].I_rst_sys_sq2_dac ]', 'rst_sys_sq2_dac_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|G_rst_column_mgt[3].I_rst_sys_sq2_dac ]', 'rst_sys_sq2_dac_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)

        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[0].I_sync_sq2_dac_rs ]', 'sync_sq2_dac_rs_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[1].I_sync_sq2_dac_rs ]', 'sync_sq2_dac_rs_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[2].I_sync_sq2_dac_rs ]', 'sync_sq2_dac_rs_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_in_rs_clk|G_column_mgt[3].I_sync_sq2_dac_rs ]', 'sync_sq2_dac_rs_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)

        p.constrainModule('|-> squid2_fbk_mgt [ G_column_mgt[0].I_squid2_fbk_mgt ]', 'squid2_fbk_mgt_0', 'Soft', 47,  6, 2, 4, 'SQUID2_FBK_0', False)
        p.constrainModule('|-> squid2_fbk_mgt [ G_column_mgt[1].I_squid2_fbk_mgt ]', 'squid2_fbk_mgt_1', 'Soft', 47,  2, 2, 4, 'SQUID2_FBK_1', False)
        p.constrainModule('|-> squid2_fbk_mgt [ G_column_mgt[2].I_squid2_fbk_mgt ]', 'squid2_fbk_mgt_2', 'Soft',  1,  2, 3, 4, 'SQUID2_FBK_2', False)
        p.constrainModule('|-> squid2_fbk_mgt [ G_column_mgt[3].I_squid2_fbk_mgt ]', 'squid2_fbk_mgt_3', 'Soft',  1,  2, 3, 4, 'SQUID2_FBK_3', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[0].I_sq2_dac_lsb ]', 'squid2_dac_lsb0_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[1].I_sq2_dac_lsb ]', 'squid2_dac_lsb1_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[2].I_sq2_dac_lsb ]', 'squid2_dac_lsb2_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[3].I_sq2_dac_lsb ]', 'squid2_dac_lsb3_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[4].I_sq2_dac_lsb ]', 'squid2_dac_lsb4_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[5].I_sq2_dac_lsb ]', 'squid2_dac_lsb5_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[6].I_sq2_dac_lsb ]', 'squid2_dac_lsb6_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[7].I_sq2_dac_lsb ]', 'squid2_dac_lsb7_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[8].I_sq2_dac_lsb ]', 'squid2_dac_lsb8_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[9].I_sq2_dac_lsb ]', 'squid2_dac_lsb9_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[10].I_sq2_dac_lsb ]', 'squid2_dac_lsb10_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[0].G_sq2_dac_lsb[11].I_sq2_dac_lsb ]', 'squid2_dac_lsb11_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[0].I_sq2_dac_lsb ]', 'squid2_dac_lsb0_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[1].I_sq2_dac_lsb ]', 'squid2_dac_lsb1_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[2].I_sq2_dac_lsb ]', 'squid2_dac_lsb2_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[3].I_sq2_dac_lsb ]', 'squid2_dac_lsb3_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[4].I_sq2_dac_lsb ]', 'squid2_dac_lsb4_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[5].I_sq2_dac_lsb ]', 'squid2_dac_lsb5_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[6].I_sq2_dac_lsb ]', 'squid2_dac_lsb6_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[7].I_sq2_dac_lsb ]', 'squid2_dac_lsb7_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[8].I_sq2_dac_lsb ]', 'squid2_dac_lsb8_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[9].I_sq2_dac_lsb ]', 'squid2_dac_lsb9_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[10].I_sq2_dac_lsb ]', 'squid2_dac_lsb10_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[1].G_sq2_dac_lsb[11].I_sq2_dac_lsb ]', 'squid2_dac_lsb11_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[0].I_sq2_dac_lsb ]', 'squid2_dac_lsb0_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[1].I_sq2_dac_lsb ]', 'squid2_dac_lsb1_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[2].I_sq2_dac_lsb ]', 'squid2_dac_lsb2_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[3].I_sq2_dac_lsb ]', 'squid2_dac_lsb3_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[4].I_sq2_dac_lsb ]', 'squid2_dac_lsb4_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[5].I_sq2_dac_lsb ]', 'squid2_dac_lsb5_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[6].I_sq2_dac_lsb ]', 'squid2_dac_lsb6_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[7].I_sq2_dac_lsb ]', 'squid2_dac_lsb7_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[8].I_sq2_dac_lsb ]', 'squid2_dac_lsb8_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[9].I_sq2_dac_lsb ]', 'squid2_dac_lsb9_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[10].I_sq2_dac_lsb ]', 'squid2_dac_lsb10_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[2].G_sq2_dac_lsb[11].I_sq2_dac_lsb ]', 'squid2_dac_lsb11_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)

        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[0].I_sq2_dac_lsb ]', 'squid2_dac_lsb0_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[1].I_sq2_dac_lsb ]', 'squid2_dac_lsb1_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[2].I_sq2_dac_lsb ]', 'squid2_dac_lsb2_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[3].I_sq2_dac_lsb ]', 'squid2_dac_lsb3_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[4].I_sq2_dac_lsb ]', 'squid2_dac_lsb4_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[5].I_sq2_dac_lsb ]', 'squid2_dac_lsb5_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[6].I_sq2_dac_lsb ]', 'squid2_dac_lsb6_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[7].I_sq2_dac_lsb ]', 'squid2_dac_lsb7_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[8].I_sq2_dac_lsb ]', 'squid2_dac_lsb8_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[9].I_sq2_dac_lsb ]', 'squid2_dac_lsb9_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[10].I_sq2_dac_lsb ]', 'squid2_dac_lsb10_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)
        p.constrainModule('|-> signal_reg(XE2A9ECEC) [ I_register_mgt|G_column_mgt_out[3].G_sq2_dac_lsb[11].I_sq2_dac_lsb ]', 'squid2_dac_lsb11_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)

        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[0].I_squid2_dac_mgt ]', 'squid2_dac_mgt_0', 'Soft', 48,  6, 1, 1, 'SQUID2_DAC_0', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[1].I_squid2_dac_mgt ]', 'squid2_dac_mgt_1', 'Soft', 48,  2, 1, 1, 'SQUID2_DAC_1', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[2].I_squid2_dac_mgt ]', 'squid2_dac_mgt_2', 'Soft',  1,  2, 1, 1, 'SQUID2_DAC_2', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[3].I_squid2_dac_mgt ]', 'squid2_dac_mgt_3', 'Soft',  2,  2, 1, 1, 'SQUID2_DAC_3', False)

        # ------------------------------------------------------------------------------------------------------
        #   EP SPI constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> ep_cmd [ I_ep_cmd ]', 'ep_cmd', 'Soft', 23, 12, 5, 1, 'REGISTER_MGT', False)

        # ------------------------------------------------------------------------------------------------------
        #   Science transmit constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X0EFFAF6C) [ I_rst_clk_mgt|I_rst_sys_ck_sc ]', 'rst_sys_ck_sc', 'Soft', 39, 22, 1, 1, 'SCIENCE_TX', False)
        p.constrainModule('|-> signal_reg(XC85BAA8D) [ I_rst_clk_mgt|I_rst_ck_science ]', 'rst_ck_science', 'Soft', 39, 22, 1, 1, 'SCIENCE_TX', False)

        # ------------------------------------------------------------------------------------------------------
        #   Internal constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> signal_reg(X41D2BCF8) [ I_rst_clk_mgt|I_rst_first_pipe ]', 'rst_first_pipe', 'Soft', 25, 12, 1, 1, 'RST_FIRST_PIPE', False)
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
