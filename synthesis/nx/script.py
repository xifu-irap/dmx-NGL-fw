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
#    @file                   script.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Main Nxmap synthesis script
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


####################################################################################################
#########################################GLOBAL DECLARATION#########################################
####################################################################################################

#########################################LIBRARY IMPORTATION########################################
import sys
import traceback
import os

from nxmap import *

from variant_custom import variant_custom

def __main__(Variant,TopCellLib,TopCellName,Option=None,Embedded=False):

    ##########################################GLOBAL CONSTANT###########################################

    script_path  = os.getcwd()

    project_path = script_path + '/'+ TopCellName + '_' + Variant

    if not Option==None:
        project_path+='_' + Option

    if not os.path.isdir(project_path):
            os.makedirs(project_path)

    sources_files_directory = script_path + '/src'
    ip_files_directory      = script_path + '/ip/nx'
    rtl_files_directory     = project_path + '/rtl'

    ####################################################################################################
    ##########################################PROJECT CREATION##########################################
    ####################################################################################################

    ###########################################GLOBAL SETTING###########################################
    p = createProject(project_path)
    p.setVariantName(Variant)
    p.setTopCellName(TopCellLib,TopCellName)

    ###########################################VARIANT SETTINGS#########################################

    board = variant_custom(Variant,sources_files_directory,ip_files_directory,Embedded)
    board.add_files(p,Option)
    board.add_parameters(p,Option)
    board.set_options(p,Option)
    board.add_constraints(p,Option)

    if not board.is_embedded():
        board.add_banks(p,Option)
        board.add_pads(p,Option)
    else:
        board.add_pins(p,Option)

    ####################################################################################################
    ##########################################PROJECT PROGRESS##########################################
    ####################################################################################################

    p.save(rtl_files_directory + '/native'+'.nym')

    ##########################################PROJECT SYNTHESIZE########################################

    for i in range(2):
        if not p.progress('Synthesize',i+1):
            p.destroy()
            sys.exit(1)
        p.save(rtl_files_directory + '/synthesized_'+str(i+1)+'.nym')

    ############################################PROJECT PLACE###########################################

    for i in range(5):
        if not p.progress('Place',i+1):
            p.destroy()
            sys.exit(1)
        p.save(rtl_files_directory + '/placed_'+str(i+1)+'.nym')

    ############################################PROJECT ROUTE###########################################

    for i in range(3):
        if not p.progress('Route',i+1):
            p.destroy()
            sys.exit(1)
        p.save(rtl_files_directory + '/routed_'+str(i+1)+'.nym')

    ############################################PROJECT REPORT##########################################

    p.reportInstances()

    ############################################TIMING ANALYSIS#########################################

    #standard
    Timing_analysis = p.createAnalyzer()
    Timing_analysis.launch({'conditions': 'typical', 'maximumSlack': 500, 'searchPathsLimit': 10})
    #Worstcase
    Timing_analysis = p.createAnalyzer()
    Timing_analysis.launch({'conditions': 'worstcase', 'maximumSlack': 500, 'searchPathsLimit': 10})

    ##########################################BISTREAM GENERATION#######################################

    p.generateBitstream('bitstream'+'.nxb')

    ################################################SUMMARY#############################################
    print('Errors: ', getErrorCount())
    print('Warnings: ', getWarningCount())
    printText('Design successfully generated')
