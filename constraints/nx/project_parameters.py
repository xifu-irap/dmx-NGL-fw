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
#    @file                   project_parameters.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap project parameters
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def common_parameters(p,option):
    print("Common parameters")
    p.createClock('getClockNet(i_clk_ref)', 'clk', 16666, 0, 8333)

def NG_MEDIUM_parameters(p,option):
    print("No NG-MEDIUM parameters")
    #p.addParameter('','')

def NG_LARGE_parameters(p,option):
    print("No NG-LARGE parameters")
    #p.addParameter('','')

def NG_ULTRA_parameters(p,option):
    print("No NG-ULTRA parameters")
    #p.addParameter('','')
