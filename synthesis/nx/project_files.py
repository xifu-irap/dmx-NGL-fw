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
#    @file                   project_files.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                List the source files necessary for Nxmap synthesis
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def common_files(p,sources_files_directory,option):
    print("Common files")
    import os
    VHDFiles=[]
    for file in os.listdir(sources_files_directory):
        if file.endswith(".vhd"):
            VHDFiles.append(os.path.join(sources_files_directory, file))

    p.addFiles('work', VHDFiles)

def NG_MEDIUM_files(p,sources_files_directory,option):
    print("Specific Variant file")
    import os
    VHDFiles=[]
    for file in os.listdir(sources_files_directory + '/NG-MEDIUM'):
        if file.endswith(".vhd"):
            VHDFiles.append(os.path.join(sources_files_directory + '/NG-MEDIUM', file))

    p.addFiles('work', VHDFiles)

def NG_LARGE_files(p,sources_files_directory,option):
    print("Specific Variant file")
    import os
    VHDFiles=[]
    for file in os.listdir(sources_files_directory + '/NG-LARGE'):
        if file.endswith(".vhd"):
            VHDFiles.append(os.path.join(sources_files_directory + '/NG-LARGE', file))

    p.addFiles('work', VHDFiles)

def NG_ULTRA_files(p,sources_files_directory,option):
    print("Specific Variant file")
    import os
    VHDFiles=[]
    for file in os.listdir(sources_files_directory + '/NG-ULTRA'):
        if file.endswith(".vhd"):
            VHDFiles.append(os.path.join(sources_files_directory + '/NG-ULTRA', file))

    p.addFiles('work', VHDFiles)
