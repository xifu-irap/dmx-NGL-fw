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
#    @file                   pads_NG_LARGE.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Banks & pads NG-LARGE configuration
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def add_banks(p,option=None):
    banks = {
    'IOB0'   : {'voltage': '2.5'},
    'IOB1'   : {'voltage': '2.5'},
    'IOB2'   : {'voltage': '2.5'},
    'IOB3'   : {'voltage': '2.5'},
    'IOB4'   : {'voltage': '2.5'},
    'IOB5'   : {'voltage': '2.5'},
    'IOB6'   : {'voltage': '2.5'},
    'IOB7'   : {'voltage': '2.5'},
    'IOB8'   : {'voltage': '2.5'},
    'IOB9'   : {'voltage': '2.5'},
    'IOB10'  : {'voltage': '2.5'},
    'IOB11'  : {'voltage': '2.5'},
    'IOB12'  : {'voltage': '2.5'},
    'IOB13'  : {'voltage': '2.5'},
    'IOB14'  : {'voltage': '2.5'},
    'IOB15'  : {'voltage': '2.5'},
    'IOB16'  : {'voltage': '2.5'},
    'IOB17'  : {'voltage': '2.5'},
    'IOB18'  : {'voltage': '2.5'},
    'IOB19'  : {'voltage': '2.5'},
    'IOB20'  : {'voltage': '2.5'},
    'IOB21'  : {'voltage': '2.5'},
    'IOB22'  : {'voltage': '2.5'},
    'IOB23'  : {'voltage': '2.5'}
          }
    p.addBanks(banks)

def add_pads(p,option=None):
    import math

    c_IO_DEL_STEP        = 160                                              # FPGA I/O delay by step value (ps)

    c_C0_SQ1_ADC_DCO_TIM = 600                                              # SQUID1 ADC col.0: time between rising edge ADC DCO signal and o_c0_clk_sq1_adc rising edge (ps) (TBD-Measure)
    c_C1_SQ1_ADC_DCO_TIM = 600                                              # SQUID1 ADC col.1: time between rising edge ADC DCO signal and o_c1_clk_sq1_adc rising edge (ps) (TBD-Measure)
    c_C2_SQ1_ADC_DCO_TIM = 600                                              # SQUID1 ADC col.2: time between rising edge ADC DCO signal and o_c2_clk_sq1_adc rising edge (ps) (TBD-Measure)
    c_C3_SQ1_ADC_DCO_TIM = 600                                              # SQUID1 ADC col.3: time between rising edge ADC DCO signal and o_c3_clk_sq1_adc rising edge (ps) (TBD-Measure)

    c_C0_SQ1_ADC_STEP    = math.floor(c_C0_SQ1_ADC_DCO_TIM/c_IO_DEL_STEP)   # SQUID1 ADC col.0: step delay number
    c_C1_SQ1_ADC_STEP    = math.floor(c_C1_SQ1_ADC_DCO_TIM/c_IO_DEL_STEP)   # SQUID1 ADC col.1: step delay number
    c_C2_SQ1_ADC_STEP    = math.floor(c_C2_SQ1_ADC_DCO_TIM/c_IO_DEL_STEP)   # SQUID1 ADC col.2: step delay number
    c_C3_SQ1_ADC_STEP    = math.floor(c_C3_SQ1_ADC_DCO_TIM/c_IO_DEL_STEP)   # SQUID1 ADC col.3: step delay number

    pads = {

#    'i_arst_n'               : {'location': 'IOB00_D01P', 'standard': 'LVCMOS', 'drive' :'2mA', 'inputDelayOn': True, 'inputDelayLine': c_C0_SQ1_ADC_STEP }, #

   }
    p.addPads(pads)
