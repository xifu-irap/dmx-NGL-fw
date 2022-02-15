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
        p.constrainModule('|-> in_rs_clk [ I_in_rs_clk ]', 'in_rs_clk', 'Soft', 25, 12, 1, 1, 'IN_RS_CLK', False)
        p.constrainModule('|-> science_data_mgt [ I_science_data_mgt ]', 'science_data_mgt', 'Soft', 26, 12, 2, 1, 'SCIENCE_DATA_MGT', False)
        p.constrainModule('|-> ep_cmd [ I_ep_cmd ]', 'ep_cmd', 'Soft', 29, 12, 1, 1, 'EP_CMD', False)
        p.constrainModule('|-> hk_mgt [ I_hk_mgt ]', 'hk_mgt', 'Soft', 48, 6, 1, 1, 'HK_MGT', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[0].I_squid_adc_mgt ]', 'squid_adc_mgt_0', 'Soft', 26,  6, 1, 4, 'SQUID1_ADC_0', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[1].I_squid_adc_mgt ]', 'squid_adc_mgt_1', 'Soft', 26, 16, 1, 4, 'SQUID1_ADC_1', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[2].I_squid_adc_mgt ]', 'squid_adc_mgt_2', 'Soft', 23, 16, 1, 4, 'SQUID1_ADC_2', False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[3].I_squid_adc_mgt ]', 'squid_adc_mgt_3', 'Soft', 23,  6, 1, 4, 'SQUID1_ADC_3', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[0].I_squid1_dac_mgt ]', 'squid1_dac_mgt_0', 'Soft', 25,  4, 1, 4, 'SQUID1_DAC_0', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[1].I_squid1_dac_mgt ]', 'squid1_dac_mgt_1', 'Soft', 25, 18, 1, 4, 'SQUID1_DAC_1', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[2].I_squid1_dac_mgt ]', 'squid1_dac_mgt_2', 'Soft', 24, 18, 1, 4, 'SQUID1_DAC_2', False)
        p.constrainModule('|-> squid1_dac_mgt [ G_column_mgt[3].I_squid1_dac_mgt ]', 'squid1_dac_mgt_3', 'Soft', 24,  4, 1, 4, 'SQUID1_DAC_3', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[0].I_squid2_dac_mgt ]', 'squid2_dac_mgt_0', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[1].I_squid2_dac_mgt ]', 'squid2_dac_mgt_1', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[2].I_squid2_dac_mgt ]', 'squid2_dac_mgt_2', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
        p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[3].I_squid2_dac_mgt ]', 'squid2_dac_mgt_3', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[0].I_squid1_adc ]', 'clk_squid_adc_0', 'Soft', 36,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_0', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[1].I_squid1_adc ]', 'clk_squid_adc_1', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_1', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[2].I_squid1_adc ]', 'clk_squid_adc_2', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_2', False)
        p.constrainModule('|-> im_ck(XAB653E3C) [ I_rst_clk_mgt|G_column_mgt[3].I_squid1_adc ]', 'clk_squid_adc_3', 'Soft', 18,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_3', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[0].I_squid1_dac_out ]', 'clk_squid_dac_0', 'Soft', 36,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_0', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[1].I_squid1_dac_out ]', 'clk_squid_dac_1', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_1', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[2].I_squid1_dac_out ]', 'clk_squid_dac_2', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_2', False)
        p.constrainModule('|-> im_ck(X29E9E6A4) [ I_rst_clk_mgt|G_column_mgt[3].I_squid1_dac_out ]', 'clk_squid_dac_3', 'Soft', 18,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_3', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_0', 'Soft', 36,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_1', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_2', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sq1_adc ]', 'cmd_ck_sq1_adc_3', 'Soft', 18,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_3', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_0', 'Soft', 36,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_0', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_1', 'Soft', 30, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_1', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_2', 'Soft', 14, 22, 1, 1, 'CLK_SQUID1_ADC_DAC_2', False)
        p.constrainModule('|-> cmd_im_ck(X118953C2) [ I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sq1_dac ]', 'cmd_ck_sq1_dac_3', 'Soft', 18,  2, 1, 1, 'CLK_SQUID1_ADC_DAC_3', False)

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
