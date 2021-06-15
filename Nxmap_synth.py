# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Kevin Chopier, IRAP Toulouse.
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
#    email                   kchopier@nanoxplore.com
#    @file                   Nxmap_synth.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap run synthesis until bitstream generation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

from nxmap import *
Variant     = 'NG-LARGE'
TopCellName = 'top_dmx'
TopCellLib  = 'work'
import sys
sys.path.insert(0, "./synthesis/nx")
sys.path.insert(0, "./constraints/nx")
import script
if len(sys.argv) > 1:
    Option = sys.argv[1]
else:
    Option = None
script.__main__(Variant,TopCellLib,TopCellName,Option)