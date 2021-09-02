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

def common_constraints(p,option):
    print("Common constraints")
    p.setAnalysisConditions('worstcase')

def NG_MEDIUM_constraints(p,option):
    print("No NG-MEDIUM constraints")

def NG_LARGE_constraints(p,option):
    print("NG-LARGE Regions definition")

    p.constrainModule('|-> science_data_tx [ I_science_data_tx ]', 'science_data_tx', 'Soft', 36, 22, 1, 1, 'SCIENCE_DATA_TX', False)
    p.constrainModule('|-> ep_cmd [ I_ep_cmd ]', 'ep_cmd', 'Soft', 48, 10, 1, 1, 'EP_CMD', False)
    p.constrainModule('|-> register_mgt [ I_register_mgt ]', 'register_mgt', 'Soft', 47, 10, 2, 1, 'REGISTER_MGT', False)
    p.constrainModule('|-> hk_mgt [ I_hk_mgt ]', 'hk_mgt', 'Soft', 48, 6, 1, 1, 'HK_MGT', False)
    p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[0].I_squid_adc_mgt ]', 'squid_adc_mgt_0', 'Soft', 37,  1, 1, 4, 'SQUID1_DAC_0', False)
    p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[1].I_squid_adc_mgt ]', 'squid_adc_mgt_1', 'Soft', 27, 20, 1, 4, 'SQUID1_DAC_1', False)
    p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[2].I_squid_adc_mgt ]', 'squid_adc_mgt_2', 'Soft', 13, 20, 1, 4, 'SQUID1_DAC_2', False)
    p.constrainModule('|-> squid_adc_mgt [ G_column_mgt[3].I_squid_adc_mgt ]', 'squid_adc_mgt_3', 'Soft', 12,  1, 1, 4, 'SQUID1_DAC_3', False)
    p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[0].I_squid2_dac_mgt ]', 'squid2_dac_mgt_0', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
    p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[1].I_squid2_dac_mgt ]', 'squid2_dac_mgt_1', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
    p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[2].I_squid2_dac_mgt ]', 'squid2_dac_mgt_2', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)
    p.constrainModule('|-> squid2_dac_mgt [ G_column_mgt[3].I_squid2_dac_mgt ]', 'squid2_dac_mgt_3', 'Soft', 1,  6, 1, 1, 'SQUID2_DAC', False)


def NG_ULTRA_constraints(p,option):
    print("No NG_ULTRA constraints")
