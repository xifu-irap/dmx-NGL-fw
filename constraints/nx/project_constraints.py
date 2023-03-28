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
from nxmap import *

class Region:
    def __init__(self, name, col, row, width, height):
        self.n  = name
        self.c  = col
        self.r  = row
        self.w  = width
        self.h  = height
        self.c2 = col + width   # Col2
        self.r2 = row + height  # Row2

def synthesis_constraints(p,variant,option):
    if variant == 'NG-LARGE' or variant == 'NG-LARGE-EMBEDDED':

        # ------------------------------------------------------------------------------------------------------
        #   Timing constraints (ns)
        # ------------------------------------------------------------------------------------------------------
        clk_per = 16.0          # System clock period
        clk_adc_dac = 8.0       # ADC/DAC clock period
        clk_adc_dac_ck = 4.0    # ADC/DAC clock period for external clock generation

        # ------------------------------------------------------------------------------------------------------
        #   Region creation
        # ------------------------------------------------------------------------------------------------------
        CLK_SQM_ADC_0   = Region('CLK_SQM_ADC_0', 30, 22,  1,  1)
        CLK_SQM_ADC_1   = Region('CLK_SQM_ADC_1', 41,  2,  1,  1)
        CLK_SQM_ADC_2   = Region('CLK_SQM_ADC_2', 13,  2,  1,  1)
        CLK_SQM_ADC_3   = Region('CLK_SQM_ADC_3',  8, 22,  1,  1)

        SQM_ADC_0       = Region('SQM_ADC_0'    , 31, 16,  2,  3)
        SQM_ADC_1       = Region('SQM_ADC_1'    , 36,  6,  2,  3)
        SQM_ADC_2       = Region('SQM_ADC_2'    , 13,  6,  2,  3)
        SQM_ADC_3       = Region('SQM_ADC_3'    , 13, 16,  2,  3)

        SQM_ADC_PWDN_0  = Region('SQM_ADC_PWD_0', 24,  2,  1,  1)
        SQM_ADC_PWDN_1  = Region('SQM_ADC_PWD_1', 24,  2,  1,  1)
        SQM_ADC_PWDN_2  = Region('SQM_ADC_PWD_2', 24,  2,  1,  1)
        SQM_ADC_PWDN_3  = Region('SQM_ADC_PWD_3', 24,  2,  1,  1)

        CLK_SQM_DAC_0   = Region('CLK_SQM_DAC_0', 22, 22,  1,  1)
        CLK_SQM_DAC_1   = Region('CLK_SQM_DAC_1', 35,  2,  1,  1)
        CLK_SQM_DAC_2   = Region('CLK_SQM_DAC_2', 19,  2,  1,  1)
        CLK_SQM_DAC_3   = Region('CLK_SQM_DAC_3', 14, 22,  1,  1)

        SQM_DAC_0       = Region('SQM_DAC_0'    , 25, 18,  1,  3)
        SQM_DAC_1       = Region('SQM_DAC_1'    , 33,  4,  1,  3)
        SQM_DAC_2       = Region('SQM_DAC_2'    , 15,  4,  1,  3)
        SQM_DAC_3       = Region('SQM_DAC_3'    , 17, 18,  1,  3)

        SQM_DAC_SLEEP_0 = Region('SQM_DAC_SLP_0', 48,  6,  1,  1)
        SQM_DAC_SLEEP_1 = Region('SQM_DAC_SLP_1', 48,  2,  1,  1)
        SQM_DAC_SLEEP_2 = Region('SQM_DAC_SLP_2',  1,  2,  1,  1)
        SQM_DAC_SLEEP_3 = Region('SQM_DAC_SLP_3',  1,  2,  1,  1)

        SQA_DAC_0       = Region('SQA_DAC_0'    , 47,  6,  2,  1)
        SQA_DAC_1       = Region('SQA_DAC_1'    , 47,  2,  2,  1)
        SQA_DAC_2       = Region('SQA_DAC_2'    ,  1,  2,  2,  1)
        SQA_DAC_3       = Region('SQA_DAC_3'    ,  1,  6,  2,  1)

        SQA_FBK_0       = Region('SQA_FBK_0'    , 44,  6,  4,  3)
        SQA_FBK_1       = Region('SQA_FBK_1'    , 44,  2,  4,  3)
        SQA_FBK_2       = Region('SQA_FBK_2'    ,  2,  2,  4,  3)
        SQA_FBK_3       = Region('SQA_FBK_3'    ,  2,  6,  4,  3)

        EP_CMD          = Region('EP_CMD'       , 38, 12,  1,  1)
        REGISTER_MGT    = Region('REGISTER_MGT' , 23, 12,  6,  4)

        SCIENCE_MGT    = Region('SCIENCE_MGT'   , 36, 18,  2,  2)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_0', 'Soft', CLK_SQM_ADC_0.c, CLK_SQM_ADC_0.r, CLK_SQM_ADC_0.w, CLK_SQM_ADC_0.h, CLK_SQM_ADC_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_1', 'Soft', CLK_SQM_ADC_1.c, CLK_SQM_ADC_1.r, CLK_SQM_ADC_1.w, CLK_SQM_ADC_1.h, CLK_SQM_ADC_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_2', 'Soft', CLK_SQM_ADC_2.c, CLK_SQM_ADC_2.r, CLK_SQM_ADC_2.w, CLK_SQM_ADC_2.h, CLK_SQM_ADC_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_sqm_adc|cmd_ck_r_reg[0]'], 'cmd_ck_adc_3', 'Soft', CLK_SQM_ADC_3.c, CLK_SQM_ADC_3.r, CLK_SQM_ADC_3.w, CLK_SQM_ADC_3.h, CLK_SQM_ADC_3.n, False)

        p.constrainModule('|-> im_ck(X369A4EF0) [ I_rst_clk_mgt|G_column_mgt[0].I_sqm_adc ]', 'ck_adc_0', 'Soft', CLK_SQM_ADC_0.c, CLK_SQM_ADC_0.r, CLK_SQM_ADC_0.w, CLK_SQM_ADC_0.h, CLK_SQM_ADC_0.n, False)
        p.constrainModule('|-> im_ck(X369A4EF0) [ I_rst_clk_mgt|G_column_mgt[1].I_sqm_adc ]', 'ck_adc_1', 'Soft', CLK_SQM_ADC_1.c, CLK_SQM_ADC_1.r, CLK_SQM_ADC_1.w, CLK_SQM_ADC_1.h, CLK_SQM_ADC_1.n, False)
        p.constrainModule('|-> im_ck(X369A4EF0) [ I_rst_clk_mgt|G_column_mgt[2].I_sqm_adc ]', 'ck_adc_2', 'Soft', CLK_SQM_ADC_2.c, CLK_SQM_ADC_2.r, CLK_SQM_ADC_2.w, CLK_SQM_ADC_2.h, CLK_SQM_ADC_2.n, False)
        p.constrainModule('|-> im_ck(X369A4EF0) [ I_rst_clk_mgt|G_column_mgt[3].I_sqm_adc ]', 'ck_adc_3', 'Soft', CLK_SQM_ADC_3.c, CLK_SQM_ADC_3.r, CLK_SQM_ADC_3.w, CLK_SQM_ADC_3.h, CLK_SQM_ADC_3.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX ADC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_0', 'Soft', SQM_ADC_PWDN_0.c, SQM_ADC_PWDN_0.r, SQM_ADC_PWDN_0.w, SQM_ADC_PWDN_0.h, SQM_ADC_PWDN_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_1', 'Soft', SQM_ADC_PWDN_1.c, SQM_ADC_PWDN_1.r, SQM_ADC_PWDN_1.w, SQM_ADC_PWDN_1.h, SQM_ADC_PWDN_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_2', 'Soft', SQM_ADC_PWDN_2.c, SQM_ADC_PWDN_2.r, SQM_ADC_PWDN_2.w, SQM_ADC_PWDN_2.h, SQM_ADC_PWDN_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_adc|o_cmd_ck_sleep_reg'], 'adc_pwdn_3', 'Soft', SQM_ADC_PWDN_3.c, SQM_ADC_PWDN_3.r, SQM_ADC_PWDN_3.w, SQM_ADC_PWDN_3.h, SQM_ADC_PWDN_3.n, False)

        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[0].I_squid_adc_mgt ]', 'squid_adc_mgt_0', 'Soft', SQM_ADC_0.c, SQM_ADC_0.r, SQM_ADC_0.w, SQM_ADC_0.h, SQM_ADC_0.n, False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[1].I_squid_adc_mgt ]', 'squid_adc_mgt_1', 'Soft', SQM_ADC_1.c, SQM_ADC_1.r, SQM_ADC_1.w, SQM_ADC_1.h, SQM_ADC_1.n, False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[2].I_squid_adc_mgt ]', 'squid_adc_mgt_2', 'Soft', SQM_ADC_2.c, SQM_ADC_2.r, SQM_ADC_2.w, SQM_ADC_2.h, SQM_ADC_2.n, False)
        p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[3].I_squid_adc_mgt ]', 'squid_adc_mgt_3', 'Soft', SQM_ADC_3.c, SQM_ADC_3.r, SQM_ADC_3.w, SQM_ADC_3.h, SQM_ADC_3.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC clocks constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_0', 'Soft', CLK_SQM_DAC_0.c, CLK_SQM_DAC_0.r, CLK_SQM_DAC_0.w, CLK_SQM_DAC_0.h, CLK_SQM_DAC_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_1', 'Soft', CLK_SQM_DAC_1.c, CLK_SQM_DAC_1.r, CLK_SQM_DAC_1.w, CLK_SQM_DAC_1.h, CLK_SQM_DAC_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_2', 'Soft', CLK_SQM_DAC_2.c, CLK_SQM_DAC_2.r, CLK_SQM_DAC_2.w, CLK_SQM_DAC_2.h, CLK_SQM_DAC_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|o_cmd_ck_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_sqm_dac_out|cmd_ck_r_reg[0]'], 'cmd_ck_dac_3', 'Soft', CLK_SQM_DAC_3.c, CLK_SQM_DAC_3.r, CLK_SQM_DAC_3.w, CLK_SQM_DAC_3.h, CLK_SQM_DAC_3.n, False)

        p.constrainModule('|-> im_ck(X2C9B091B) [ I_rst_clk_mgt|G_column_mgt[0].I_sqm_dac_out ]', 'squid_dac_mgt_0', 'Soft', CLK_SQM_DAC_0.c, CLK_SQM_DAC_0.r, CLK_SQM_DAC_0.w, CLK_SQM_DAC_0.h, CLK_SQM_DAC_0.n, False)
        p.constrainModule('|-> im_ck(X2C9B091B) [ I_rst_clk_mgt|G_column_mgt[1].I_sqm_dac_out ]', 'squid_dac_mgt_1', 'Soft', CLK_SQM_DAC_1.c, CLK_SQM_DAC_1.r, CLK_SQM_DAC_1.w, CLK_SQM_DAC_1.h, CLK_SQM_DAC_1.n, False)
        p.constrainModule('|-> im_ck(X2C9B091B) [ I_rst_clk_mgt|G_column_mgt[2].I_sqm_dac_out ]', 'squid_dac_mgt_2', 'Soft', CLK_SQM_DAC_2.c, CLK_SQM_DAC_2.r, CLK_SQM_DAC_2.w, CLK_SQM_DAC_2.h, CLK_SQM_DAC_2.n, False)
        p.constrainModule('|-> im_ck(X2C9B091B) [ I_rst_clk_mgt|G_column_mgt[3].I_sqm_dac_out ]', 'squid_dac_mgt_3', 'Soft', CLK_SQM_DAC_3.c, CLK_SQM_DAC_3.r, CLK_SQM_DAC_3.w, CLK_SQM_DAC_3.h, CLK_SQM_DAC_3.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID MUX DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[0].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_0', 'Soft', SQM_DAC_SLEEP_0.c, SQM_DAC_SLEEP_0.r, SQM_DAC_SLEEP_0.w, SQM_DAC_SLEEP_0.h, SQM_DAC_SLEEP_0.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[1].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_1', 'Soft', SQM_DAC_SLEEP_1.c, SQM_DAC_SLEEP_1.r, SQM_DAC_SLEEP_1.w, SQM_DAC_SLEEP_1.h, SQM_DAC_SLEEP_1.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[2].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_2', 'Soft', SQM_DAC_SLEEP_2.c, SQM_DAC_SLEEP_2.r, SQM_DAC_SLEEP_2.w, SQM_DAC_SLEEP_2.h, SQM_DAC_SLEEP_2.n, False)
        p.constrainPath(['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|cmd_ck_sleep_reg'],['I_rst_clk_mgt|G_column_mgt[3].I_cmd_ck_sqm_dac|o_cmd_ck_sleep_reg'], 'dac_sleep_3', 'Soft', SQM_DAC_SLEEP_3.c, SQM_DAC_SLEEP_3.r, SQM_DAC_SLEEP_3.w, SQM_DAC_SLEEP_3.h, SQM_DAC_SLEEP_3.n, False)

        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[0].I_sqm_dac_mgt ]', 'sqm_dac_mgt_0', 'Soft', SQM_DAC_0.c, SQM_DAC_0.r, SQM_DAC_0.w, SQM_DAC_0.h, SQM_DAC_0.n, False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[1].I_sqm_dac_mgt ]', 'sqm_dac_mgt_1', 'Soft', SQM_DAC_1.c, SQM_DAC_1.r, SQM_DAC_1.w, SQM_DAC_1.h, SQM_DAC_1.n, False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[2].I_sqm_dac_mgt ]', 'sqm_dac_mgt_2', 'Soft', SQM_DAC_2.c, SQM_DAC_2.r, SQM_DAC_2.w, SQM_DAC_2.h, SQM_DAC_2.n, False)
        p.constrainModule('|-> sqm_dac_mgt [ G_column_mgt[3].I_sqm_dac_mgt ]', 'sqm_dac_mgt_3', 'Soft', SQM_DAC_3.c, SQM_DAC_3.r, SQM_DAC_3.w, SQM_DAC_3.h, SQM_DAC_3.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   SQUID AMP DAC management constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[0].I_sqa_dac_mgt ]', 'sqa_dac_mgt_0', 'Soft', SQA_DAC_0.c, SQA_DAC_0.r, SQA_DAC_0.w, SQA_DAC_0.h, SQA_DAC_0.n, False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[1].I_sqa_dac_mgt ]', 'sqa_dac_mgt_1', 'Soft', SQA_DAC_1.c, SQA_DAC_1.r, SQA_DAC_1.w, SQA_DAC_1.h, SQA_DAC_1.n, False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[2].I_sqa_dac_mgt ]', 'sqa_dac_mgt_2', 'Soft', SQA_DAC_2.c, SQA_DAC_2.r, SQA_DAC_2.w, SQA_DAC_2.h, SQA_DAC_2.n, False)
        p.constrainModule('|-> sqa_dac_mgt [ G_column_mgt[3].I_sqa_dac_mgt ]', 'sqa_dac_mgt_3', 'Soft', SQA_DAC_3.c, SQA_DAC_3.r, SQA_DAC_3.w, SQA_DAC_3.h, SQA_DAC_3.n, False)

        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[0].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_0', 'Soft', SQA_FBK_0.c, SQA_FBK_0.r, SQA_FBK_0.w, SQA_FBK_0.h, SQA_FBK_0.n, False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[1].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_1', 'Soft', SQA_FBK_1.c, SQA_FBK_1.r, SQA_FBK_1.w, SQA_FBK_1.h, SQA_FBK_1.n, False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[2].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_2', 'Soft', SQA_FBK_2.c, SQA_FBK_2.r, SQA_FBK_2.w, SQA_FBK_2.h, SQA_FBK_2.n, False)
        p.constrainModule('|-> sqa_fbk_mgt [ G_column_mgt[3].I_sqa_fbk_mgt ]', 'sqa_fbk_mgt_3', 'Soft', SQA_FBK_3.c, SQA_FBK_3.r, SQA_FBK_3.w, SQA_FBK_3.h, SQA_FBK_3.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   EP SPI constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> spi_slave(X077D3D2A) [ I_ep_cmd|I_spi_slave ]', 'ep_cmd_spi_slave', 'Soft', EP_CMD.c, EP_CMD.r, EP_CMD.w, EP_CMD.h, EP_CMD.n, False)
        p.constrainModule('|-> ep_cmd [ I_ep_cmd ]', 'ep_cmd', 'Soft', REGISTER_MGT.c, REGISTER_MGT.r, REGISTER_MGT.w, REGISTER_MGT.h, REGISTER_MGT.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   Science constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> science_data_mgt [ I_science_data_mgt ]', 'science_data_mgt', 'Soft', SCIENCE_MGT.c, SCIENCE_MGT.r, SCIENCE_MGT.w, SCIENCE_MGT.h, SCIENCE_MGT.n, False)

        # ------------------------------------------------------------------------------------------------------
        #   Internal constraints
        # ------------------------------------------------------------------------------------------------------
        p.constrainModule('|-> register_mgt [ I_register_mgt ]', 'register_mgt', 'Soft', REGISTER_MGT.c, REGISTER_MGT.r, REGISTER_MGT.w, REGISTER_MGT.h, REGISTER_MGT.n, False)

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
