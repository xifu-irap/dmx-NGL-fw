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
#    @file                   variant_custom.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap variant choice script
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

import project_files
import project_parameters
import project_options
import project_constraints
import pads_NG_LARGE

class variant_custom():

    def __init__(self,variant,sources_files_directory,ip_files_directory,embedded):
        self.variant = variant
        self.sources_files_directory = sources_files_directory
        self.ip_files_directory = ip_files_directory
        self.embedded = embedded

    def is_embedded(self):
        if (self.variant == 'NG-MEDIUM' or self.variant == 'NG-LARGE' or self.variant == 'NG-ULTRA' or not self.embedded):
            return False
        else:
            return True

    def add_banks(self,p,option=None):
        if self.variant == 'NG-MEDIUM':
            import pads_NG_MEDIUM
            pads_NG_MEDIUM.add_banks(p,option)
        elif self.variant == 'NG-LARGE':
            import pads_NG_LARGE
            pads_NG_LARGE.add_banks(p,option)
        elif self.variant == 'NG-ULTRA':
            import pads_NG_ULTRA
            pads_NG_ULTRA.add_banks(p,option)
        else:
            import pads_OTHER
            pads_OTHER.add_banks(p,option)

    def add_pads(self,p,option=None):
        if self.variant == 'NG-MEDIUM':
            import pads_NG_MEDIUM
            pads_NG_MEDIUM.add_pads(p,option)
        elif self.variant == 'NG-LARGE':
            import pads_NG_LARGE
            pads_NG_LARGE.add_pads(p,option)
        elif self.variant == 'NG-ULTRA':
            import pads_NG_ULTRA
            pads_NG_ULTRA.add_pads(p,option)
        else:
            import pads_OTHER
            pads_OTHER.add_pads(p,option)

    def add_pins(self,p,option=None):
        if self.variant == 'NG-MEDIUM-EMBEDDED':
            import pins_NG_MEDIUM
            pins_NG_MEDIUM.add_pins(p,option)
        elif self.variant == 'NG-LARGE-EMBEDDED':
            import pins_NG_LARGE
            pins_NG_LARGE.add_pins(p,option)
        elif self.variant == 'NG-ULTRA-EMBEDDED':
            import pins_NG_ULTRA
            pins_NG_ULTRA.add_pins(p,option)
        else:
            import pins_OTHER
            pins_OTHER.add_pins(p,option)

    def add_files(self,p,option=None):
        project_files.common_files(p,self.sources_files_directory,option)
        if self.variant == 'NG-MEDIUM' or self.variant == 'NG-MEDIUM-EMBEDDED':
            project_files.NG_MEDIUM_files(p,self.ip_files_directory,option)
        elif self.variant == 'NG-LARGE' or self.variant == 'NG-LARGE-EMBEDDED':
            project_files.NG_LARGE_files(p,self.ip_files_directory,option)
        elif self.variant == 'NG-ULTRA' or self.variant == 'NG-ULTRA-EMBEDDED':
            project_files.NG_ULTRA_files(p,self.ip_files_directory,option)

    def add_parameters(self,p,option=None):
        project_parameters.common_parameters(p,option)
        if self.variant == 'NG-MEDIUM' or self.variant == 'NG-MEDIUM-EMBEDDED':
            project_parameters.NG_MEDIUM_parameters(p,option)
        elif self.variant == 'NG-LARGE' or self.variant == 'NG-LARGE-EMBEDDED':
            project_parameters.NG_LARGE_parameters(p,option)
        elif self.variant == 'NG-ULTRA' or self.variant == 'NG-ULTRA-EMBEDDED':
            project_parameters.NG_ULTRA_parameters(p,option)

    def set_options(self,p,option=None):
        project_options.common_options(p,option)
        if self.variant == 'NG-MEDIUM' or self.variant == 'NG-MEDIUM-EMBEDDED':
            project_options.NG_MEDIUM_options(p,option)
        elif self.variant == 'NG-LARGE' or self.variant == 'NG-LARGE-EMBEDDED':
            project_options.NG_LARGE_options(p,option)
        elif self.variant == 'NG-ULTRA' or self.variant == 'NG-ULTRA-EMBEDDED':
            project_options.NG_ULTRA_options(p,option)

    def add_constraints(self,p,option=None):
        project_constraints.common_constraints(p,option)
        if self.variant == 'NG-MEDIUM' or self.variant == 'NG-MEDIUM-EMBEDDED':
            project_constraints.NG_MEDIUM_constraints(p,option)
        elif self.variant == 'NG-LARGE' or self.variant == 'NG-LARGE-EMBEDDED':
            project_constraints.NG_LARGE_constraints(p,option)
        elif self.variant == 'NG-ULTRA' or self.variant == 'NG-ULTRA-EMBEDDED':
            project_constraints.NG_ULTRA_constraints(p,option)
