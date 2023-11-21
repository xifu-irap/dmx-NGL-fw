# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
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
#    email                   slaurent@nanoxplore.com
#    @file                   project_options.py
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Nxmap options
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

def add_options(p,variant,timing_driven,seed,option):
    p.setOptions({
        'Autosave'                          : 'Yes',
        'BypassingEffort'                   : 'High',
        'CMICLatency'                       : '0',
        'CongestionEffort'                  : 'High',
        'DefaultFSMEncoding'                : 'OneHot',
        'DefaultRAMMapping'                 : 'AUTO',
        'DefaultROMMapping'                 : 'AUTO',
        'DensityEffort'                     : 'High',
        'DisableAdderBasicMerge'            : 'No',
        'DisableAdderTreeOptimization'      : 'No',
        'DisableAdderTrivialRemoval'        : 'No',
        'DisableAssertionChecking'          : 'No',
        'DisableDSPAluOperator'             : 'No',
        'DisableDSPFullRecognition'         : 'No',
        'DisableDSPPreOperator'             : 'No',
        'DisableDSPRegisters'               : 'No',
        'DisableKeepPortOrdering'           : 'No',
        'DisableLoadAndResetBypass'         : 'No',
        'DisableRAMAlternateForm'           : 'No',
        'DisableRAMRegisters'               : 'No',
        'DisableRegisterMergeInDspForAdd'   : 'No',
        'DisableROMFullLutRecognition'      : 'No',
        'Dynamic'                           : 'No',
        'ExhaustiveBitstream'               : 'No',
        'GenerateBitstreamCMIC'             : 'No',
        'IgnoreRAMFlashClear'               : 'No',
        'InitializeContext'                 : 'No',
        'ManageAsynchronousReadPort'        : 'No',
        'ManageUnconnectedOutputs'          : 'Error',
        'ManageUnconnectedSignals'          : 'Error',
        'ManageUninitializedLoops'          : 'No',
        'MappingEffort'                     : 'High',
        'MaxRegisterCount'                  : '20000',
        'OptimizedMux'                      : 'Yes',
        'PolishingEffort'                   : 'High',
        'ReadyOffWithSoftReset'             : 'No',
        'ReplicationApproval'               : 'Yes',
        'RoutingEffort'                     : 'High',
        'SaveTiming'                        : 'No',
        'Seed'                              : seed,
        'SetRunAfterContext'                : 'No',
        'SharingEffort'                     : 'Medium',
        'SharingFanout'                     : '30',
        'SimplifyRegions'                   : 'Yes',
        'TimingDriven'                      : timing_driven,
        'TimingEffort'                      : 'High',
        'UnusedPads'                        : 'Floating'
        })
