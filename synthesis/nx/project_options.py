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

def common_options(p,option):
    p.setOptions({
        'Autosave': 'Yes',
        'BypassingEffort': 'High',
        'CongestionEffort': 'High',
        'Dynamic': 'Yes',
        'DefaultFSMEncoding': 'OneHotSafe',
        'DefaultRAMMapping': 'AUTO',
        'DefaultROMMapping': 'AUTO',
        'DensityEffort': 'High',
        'DisableAdderBasicMerge': 'No',
        'DisableAdderTreeOptimization': 'No',
        'DisableAdderTrivialRemoval': 'No',
        'DisableAssertionChecking': 'No',
        'DisableDSPAluOperator': 'No',
        'DisableDSPFullRecognition': 'No',
        'DisableDSPPreOperator': 'No',
        'DisableDSPRegisters': 'No',
        'DisableKeepPortOrdering': 'No',
        'DisableLoadAndResetBypass': 'No',
        'DisableRAMAlternateForm': 'No',
        'DisableRAMRegisters': 'No',
        'DisableROMFullLutRecognition': 'No',
        'ExhaustiveBitstream': 'No',
        'GenerateBitstreamCMIC': 'Yes',
        'IgnoreRAMFlashClear': 'No',
        'ManageAsynchronousReadPort': 'No',
        'ManageUnconnectedOutputs': 'Error',
        'ManageUnconnectedSignals': 'Error',
        'ManageUninitializedLoops': 'No',
        'MappingEffort': 'High',
        'MaxRegisterCount': '10000',
        'OptimizedMux': 'Yes',
        'PolishingEffort': 'Medium',
        'RoutingEffort': 'High',
        'TimingDriven': 'No',
        'UnusedPads': 'Floating',
        'VariantAwareSynthesis': 'Yes'
    })

def NG_MEDIUM_options(p,option):
    print("No NG-MEDIUM options")

def NG_LARGE_options(p,option):
    print("No NG-LARGE options")

def NG_ULTRA_options(p,option):
    print("No NG-ULTRA options")
