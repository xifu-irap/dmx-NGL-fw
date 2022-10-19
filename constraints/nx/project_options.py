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
#    @file                   project_options.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap options
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def add_options(p,variant,timing_driven,seed,option):
    p.setOptions({
        'DefaultFSMEncoding'          : 'OneHot',
        'DefaultRAMMapping'           : 'AUTO',
        'DefaultROMMapping'           : 'AUTO',
        'DisableAssertionChecking'    : 'No',
        'DisableKeepPortOrdering'     : 'No',
        'DisableRAMAlternateForm'     : 'No',
        'DisableROMFullLutRecognition': 'No',
        'IgnoreRAMFlashClear'         : 'No',
        'ManageUnconnectedOutputs'    : 'Ground',
        'ManageUnconnectedSignals'    : 'Ground',
        'MaxRegisterCount'            : '3700',
        'DisableAdderBasicMerge'      : 'No',
        'DisableAdderTreeOptimization': 'No',
        'DisableAdderTrivialRemoval'  : 'No',
        'DisableDSPAluOperator'       : 'No',
        'DisableDSPFullRecognition'   : 'No',
        'DisableDSPPreOperator'       : 'No',
        'DisableDSPRegisters'         : 'No',
        'DisableLoadAndResetBypass'   : 'No',
        'DisableRAMRegisters'         : 'No',
        'ManageAsynchronousReadPort'  : 'No',
        'ManageUninitializedLoops'    : 'No',
        'MappingEffort'               : 'High',
        'OptimizedMux'                : 'Yes',
        'VariantRepairSynthesis'      : 'Yes',
        'DensityEffort'               : 'High',
        'RoutingEffort'               : 'High',
        'TimingDriven'                : timing_driven,
        'Seed'                        : seed
        })
