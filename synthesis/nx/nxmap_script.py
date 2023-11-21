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
#    @file                   nxmap_script.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap run synthesis
#                            nxpython nxmap_script.py -h : get help
#                            nxpython nxmap_script.py -i : get info about default values and allowed values
#                            nxpython nxmap_script.py -c : clean directory removing all generated directories and files
#
#                            Examples :
#                            nxpython nxmap_script.py -v NG-LARGE                                               : Launch the script for NG-LARGE variant
#                            nxpython nxmap_script.py -v NG-LARGE --option USE_DSP                              : Launch the script for NG-LARGE variant with option "USE_DSP" which is used in sub_scripts
#                            nxpython nxmap_script.py -v NG-LARGE --progress synthesized                        : Launch the script for NG-LARGE variant reloading synthesized project from previous run with same variant and same option
#                            nxpython nxmap_script.py -v NG-LARGE --suffix try_1                                : Launch the script for NG-LARGE variant adding a suffix in the project name. Useful in case of multiple tries changing scripts.
#                            nxpython nxmap_script.py -v NG-LARGE --topcellname switch_counter --topcelllib work: Launch the script for NG-LARGE variant for a different top cell than the default one. Useful in case of unitary run before top run
#                            nxpython nxmap_script.py -v NG-LARGE --timingdriven Yes                            : Launch the script for NG-LARGE variant with TimingDriven enabled
#                            nxpython nxmap_script.py -v NG-LARGE --seed 3557                                   : Launch the script for NG-LARGE variant with a different seed
#                            nxpython nxmap_script.py -v NG-LARGE --sta all --stacondition typical              : Launch the script for NG-LARGE variant generating sta after Prepared and Routed steps in typical conditions
#                            nxpython nxmap_script.py -v NG-LARGE --bitstream Yes                               : Launch the script for NG-LARGE variant generating a bitstream at the end
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

from nxpython import *
import sys
sys.path.insert(0, "./synthesis/nx")
sys.path.insert(0, "./constraints/nx")
import script
from project_variables import *
import argparse,shutil,glob

#Functions
def check_arg(message,arg_name,arg,allowed_values=None,allowed_type=None):
    '''Check arg value and type'''
    result=True
    message=''
    if not allowed_values==None:
        if not arg in allowed_values:
            result=False
            message += arg_name + ' not allowed: ' + str(arg) + '. Expected value in ' + str(allowed_values) + '\n'
    if not allowed_type==None:
        if allowed_type == 'int':
            result=arg.isdigit()
            if not result:
                message += arg_name + ' not of expected type: ' + str(arg) + '. Allowed type is ' + allowed_type + '\n'
    print(message)
    if not result:
        sys.exit()


def get_info(arg_name,arg,allowed_values=None):
    '''Get default value and allowed values of a parameter'''
    message = 'Default ' + arg_name + ' is: ' + str(arg) + '\n'
    if not allowed_values==None:
        message += arg_name + ' must be in: ' + str(allowed_values) + '\n'
    print(message)


#Parser arguments
parser = argparse.ArgumentParser()
parser.add_argument('-i'              ,                                        action='store_true', help='Get info about the project (topcell, variants, ...)')
parser.add_argument('-c'              ,                                        action='store_true', help='Clean the directory')
parser.add_argument('--variant'       , default=DefaultVariant,                                     help='Set variant name (Default: %(default)s)')
parser.add_argument('--progress'      , default='scratch',                                          help='Progress from which the project starts [scratch,native,synthesized,placed,routed] (Default: %(default)s)')
parser.add_argument('--option'        , default=DefaultOption,                                      help='Add an option in script (Default: %(default)s)')
parser.add_argument('--timingdriven'  , default=DefaultTimingDriven,                                help='Enable TimingDriven option [Yes,No] (Default: %(default)s)')
parser.add_argument('--seed'          , default=DefaultSeed,                                        help='Set Seed (Default: %(default)s)')
parser.add_argument('--sta'           , default=DefaultSta,                                         help='Generate STA after progress prepared, routed or both (Default: %(default)s)')
parser.add_argument('--stacondition'  , default=DefaultStaCondition,                                help='Set condition for STA (Default: %(default)s)')
parser.add_argument('--bitstream'     , default=DefaultBitstream,                                   help='Generate bitstream (Default: %(default)s)')
parser.add_argument('--topcellname'   , default=DefaultTopCellName,                                 help='Set top cell name (Default: %(default)s)')
parser.add_argument('--topcelllib'    , default=DefaultTopCellLib,                                  help='Set top cell library (Default: %(default)s)')
parser.add_argument('--suffix'        , default='',                                                 help='Set a suffix in the project name directory (Default: %(default)s)')
args = parser.parse_args()


args_dict = {
    'Variant'        : {'arg' : args.variant,        'allowed_values' : AllowedVariants,                                      'allowed_type' : None},
    'Progress'       : {'arg' : args.progress,       'allowed_values' : ['scratch','native','synthesized','placed','routed'], 'allowed_type' : None},
    'Option'         : {'arg' : args.option,         'allowed_values' : AllowedOptions,                                       'allowed_type' : None},
    'Timing Driven'  : {'arg' : args.timingdriven,   'allowed_values' : ['Yes','No'],                                         'allowed_type' : None},
    'Seed'           : {'arg' : args.seed,           'allowed_values' : None,                                                 'allowed_type' : 'int'},
    'Sta'            : {'arg' : args.sta,            'allowed_values' : ['none','prepared','routed','all'],                   'allowed_type' : None},
    'Sta Condtion'   : {'arg' : args.stacondition,   'allowed_values' : ['bestcase','typical','worstcase'],                   'allowed_type' : None},
    'Bitstream'      : {'arg' : args.bitstream,      'allowed_values' : None,                                                 'allowed_type' : None},
    'Top Cell Name'  : {'arg' : args.topcellname,    'allowed_values' : None,                                                 'allowed_type' : None},
    'Top Cell Lib'   : {'arg' : args.topcelllib,     'allowed_values' : None,                                                 'allowed_type' : None},
    'Suffix'         : {'arg' : args.suffix,         'allowed_values' : None,                                                 'allowed_type' : None},
    }

#Execute Command
if args.i:#Get info
    for arg in args_dict:
         get_info(arg,args_dict[arg]['arg'],args_dict[arg]['allowed_values'])
elif args.c:#Clean directory
    for variant in AllowedVariants:#Remove projects
        for elem in glob.glob('*'+variant+'*'):
            shutil.rmtree(elem)
    for elem in ['transcript.py','logs','__pycache__','sub_scripts/__pycache__']:#Remove other generated elements
        if glob.glob(elem):
            shutil.rmtree(elem)
else:#Launch project
    message ='-------------------------------------------\n'
    message+='-------------List of variables-------------\n'
    message+='-------------------------------------------\n'
    message+='|%(variable)-20s|%(value)-20s|\n' % {'variable': 'Variable', 'value': 'Value'}
    message+='|--------------------|--------------------|\n'
    for arg in args_dict:
        check_arg(message,arg,args_dict[arg]['arg'],args_dict[arg]['allowed_values'],args_dict[arg]['allowed_type'])
        message+='|%(variable)-20s|%(value)-20s|\n' % {'variable': arg, 'value': str(args_dict[arg]['arg'])}
    print(message)

    script.__main__(args.topcelllib,args.topcellname,args.suffix,args.variant,args.progress,args.option,args.timingdriven,args.seed,args.sta,args.stacondition,args.bitstream)

