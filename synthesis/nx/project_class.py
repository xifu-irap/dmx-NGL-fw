# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Kevin Chopier, IRAP Toulouse.
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
#    email                   kchopier@nanoxplore.com
#    @file                   project_class.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap project class
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

import project_ios
import project_files
import project_parameters
import project_options
import project_constraints

class project_class():

    def __init__(self,variant,sources_files_directory):
        self.variant = variant
        self.sources_files_directory = sources_files_directory

    def add_ios(self,p,option=None):
        project_ios.add_ios(p,self.variant,option)

    def add_files(self,p,option=None):
        project_files.add_files(p,self.sources_files_directory,self.variant,option)

    def add_parameters(self,p,option=None):
        project_parameters.add_parameters(p,self.variant,option)

    def add_options(self,p,timing_driven,seed,option=None):
        project_options.add_options(p,self.variant,timing_driven,seed,option)

    def add_constraints(self,p,step,option=None):
        project_constraints.add_constraints(p,self.variant,step,option)
