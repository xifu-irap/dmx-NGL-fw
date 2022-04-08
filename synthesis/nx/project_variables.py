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
#    @file                   project_variables.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap project variables
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Top Cell
DefaultTopCellName  = 'top_dmx'
DefaultTopCellLib   = 'work'
#Variant
DefaultVariant      = 'NG-LARGE'
AllowedVariants     = ['NG-MEDIUM','NG-MEDIUM-EMBEDDED','NG-LARGE']
#Option
DefaultOption       = ''
AllowedOptions      = ['','USE_DSP']
#Project
DefaultSeed         = '2000'
DefaultTimingDriven = 'Yes'
DefaultSta          = 'routed'
DefaultStaCondition = 'worstcase'
DefaultBitstream    = 'Yes'
