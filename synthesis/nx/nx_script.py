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
#    @file                   nx_script.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nx run synthesis
#                            nxpython nx_script.py -h : get help
#                            nxpython nx_script.py -i : get info about default values and allowed values
#                            nxpython nx_script.py -c : clean directory removing all generated directories and files
#
#                            Examples :
#                            nxpython nx_script.py --modelboard dk  : Launch the script for Devkit Model Board
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
parser.add_argument('-i'              ,                                 action='store_true',    help='Get info about the project (topcell, model board, ...)')
parser.add_argument('-c'              ,                                 action='store_true',    help='Clean the directory')
parser.add_argument('--projectname'   , default=DefaultProjectName,                             help='Set project name (Default: %(default)s)')
parser.add_argument('--modelboard'    , default=DefaultModelBoard,                              help='Set model board (Default: %(default)s)')
parser.add_argument('--topcelllib'    , default=DefaultTopCellLib,                              help='Set top cell library (Default: %(default)s)')
parser.add_argument('--seed'          , default='',                                             help='Set Seed (Default: %(default)s)')
parser.add_argument('--timingdriven'  , default=DefaultTimingDriven,                            help='Enable TimingDriven option [Yes,No] (Default: %(default)s)')
parser.add_argument('--sta'           , default=DefaultSta,                                     help='Generate STA after progress prepared, routed or both (Default: %(default)s)')
parser.add_argument('--stacondition'  , default=DefaultStaCondition,                            help='Set condition for STA (Default: %(default)s)')
parser.add_argument('--bitstream'     , default=DefaultBitstream,                               help='Generate bitstream (Default: %(default)s)')
parser.add_argument('--progress'      , default='scratch',                                      help='Progress from which the project starts [scratch,native,synthesized,placed,routed] (Default: %(default)s)')
parser.add_argument('--suffix'        , default='',                                             help='Set a suffix in the project name directory (Default: %(default)s)')
args = parser.parse_args()

if args.seed == '':
    args.seed = DefaultSeed[AllowedModelBoard.index(args.modelboard)]

args_dict = {
    'Project Name'   : {'arg' : args.projectname,    'allowed_values' : None,                                                 'allowed_type' : None},
    'Model Board'    : {'arg' : args.modelboard,     'allowed_values' : AllowedModelBoard,                                    'allowed_type' : None},
    'Top Cell Lib'   : {'arg' : args.topcelllib,     'allowed_values' : None,                                                 'allowed_type' : None},
    'Seed'           : {'arg' : args.seed,           'allowed_values' : None,                                                 'allowed_type' : None},
    'Timing Driven'  : {'arg' : args.timingdriven,   'allowed_values' : ['Yes','No'],                                         'allowed_type' : None},
    'Sta'            : {'arg' : args.sta,            'allowed_values' : ['none','prepared','routed','all'],                   'allowed_type' : None},
    'Sta Condtion'   : {'arg' : args.stacondition,   'allowed_values' : ['bestcase','typical','worstcase'],                   'allowed_type' : None},
    'Bitstream'      : {'arg' : args.bitstream,      'allowed_values' : None,                                                 'allowed_type' : None},
    'Progress'       : {'arg' : args.progress,       'allowed_values' : ['scratch','native','synthesized','placed','routed'], 'allowed_type' : None},
    'Suffix'         : {'arg' : args.suffix,         'allowed_values' : None,                                                 'allowed_type' : None},
    }

Variant     = DefaultVariants[AllowedModelBoard.index(args.modelboard)]
TopCellName = DefaultTopCellName[AllowedModelBoard.index(args.modelboard)]

#Execute Command
if args.i:#Get info
    for arg in args_dict:
         get_info(arg,args_dict[arg]['arg'],args_dict[arg]['allowed_values'])
elif args.c:#Clean directory
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

    script.__main__(args.projectname,args.modelboard,Variant,TopCellName,args.topcelllib,args.seed,args.timingdriven,args.sta,args.stacondition,args.bitstream,args.progress,args.suffix)

