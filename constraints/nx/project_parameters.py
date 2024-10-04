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
#    @file                   project_parameters.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nx project parameters
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def add_parameters(p,modelboard):
    print("Common parameters")
    p.createClock(falling = 8, name = "clk_ref", period = 16, rising = 0, target = "getClockNet(i_clk_ref)")
    p.createClock(falling = 4.4, name = "sqm_adc_dc0", period = 8,  rising = 0.4, target = "getClockNet(i_sqm_adc_dc[0])")
    p.createClock(falling = 4.4, name = "sqm_adc_dc1", period = 8,  rising = 0.4, target = "getClockNet(i_sqm_adc_dc[1])")
    p.createClock(falling = 4.4, name = "sqm_adc_dc2", period = 8,  rising = 0.4, target = "getClockNet(i_sqm_adc_dc[2])")
    p.createClock(falling = 4.4, name = "sqm_adc_dc3", period = 8,  rising = 0.4, target = "getClockNet(i_sqm_adc_dc[3])")
