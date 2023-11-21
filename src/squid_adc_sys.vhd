-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   slaurent@nanoxplore.com
--!   @file                   squid_adc_sys.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid ADC signals synchronized on system clock
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity squid_adc_sys is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! System Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization (System Clock)
         i_aqmde_dmp_cmp      : in     std_logic                                                            ; --! Telemetry mode, status "Dump" compared ('0' = Inactive, '1' = Active) (System Clock)
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging (System Clock)
         i_smpdl              : in     std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                      ; --! ADC sample delay (System Clock)

         o_sync_rs_rsys       : out    std_logic                                                            ; --! Pixel sequence synchronization register (System Clock)
         o_aqmde_dmp_cmp_rsys : out    std_logic                                                            ; --! Telemetry mode, status "Dump" compared register (System Clock)
         o_bxlgt_rsys         : out    std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging register (System Clock)
         o_smpdl_rsys         : out    std_logic_vector(c_DFLD_SMPDL_COL_S-1 downto 0)                      ; --! ADC sample delay register (System Clock)

         i_mem_dump_bsy       : in     std_logic                                                            ; --! SQUID MUX Memory Dump: data busy (ADC/DAC Clock)
         i_data_err           : in     std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error (ADC/DAC Clock)
         i_data_err_frst      : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes) (ADC/DAC Clock)
         i_data_err_last      : in     std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)  (ADC/DAC Clock)
         i_data_err_rdy       : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready) (ADC/DAC Clock)

         o_mem_dump_bsy_rsys  : out    std_logic                                                            ; --! SQUID MUX Memory Dump: data busy (System Clock)
         o_data_err_rsys      : out    std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error (System Clock)
         o_data_err_frst_rsys : out    std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes) (System Clock)
         o_data_err_last_rsys : out    std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)  (System Clock)
         o_data_err_rdy_rsys  : out    std_logic                                                              --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready) (System Clock)
   );
end entity squid_adc_sys;

architecture RTL of squid_adc_sys is
signal   mem_dump_bsy_rsys    : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID MUX Memory Dump: data busy (System Clock)
signal   data_err_rsys        : t_slv_arr(0 to c_FF_RSYNC_NB-1)(c_SQM_DATA_ERR_S-1 downto 0)                ; --! SQUID MUX Data error (System Clock)
signal   data_err_frst_rsys   : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes) (System Clock)
signal   data_err_last_rsys   : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)  (System Clock)
signal   data_err_rdy_rsys    : std_logic_vector(c_FF_RSYNC_NB-1 downto 0)                                  ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready) (System Clock)

attribute syn_preserve        : boolean                                                                     ; --! Disabling signal optimization
attribute syn_preserve          of o_sync_rs_rsys        : signal is true                                   ; --! Disabling signal optimization: o_sync_rs_rsys

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Inputs registered on system clock
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sys: process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         o_sync_rs_rsys       <= c_I_SYNC_DEF;
         o_aqmde_dmp_cmp_rsys <= c_LOW_LEV;
         o_bxlgt_rsys         <= c_EP_CMD_DEF_BXLGT;
         o_smpdl_rsys         <= c_EP_CMD_DEF_SMPDL;

      elsif rising_edge(i_clk) then
         o_sync_rs_rsys       <= i_sync_rs;
         o_aqmde_dmp_cmp_rsys <= i_aqmde_dmp_cmp;
         o_bxlgt_rsys         <= i_bxlgt;
         o_smpdl_rsys         <= i_smpdl;

      end if;

   end process P_reg_sys;

   -- ------------------------------------------------------------------------------------------------------
   --!   Outputs Resynchronization on System Clock
   -- ------------------------------------------------------------------------------------------------------
   P_out_rsync : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_dump_bsy_rsys  <= (others => c_LOW_LEV);
         data_err_rsys      <= (others => c_ZERO(data_err_rsys(data_err_rsys'low)'range));
         data_err_frst_rsys <= (others => c_LOW_LEV);
         data_err_last_rsys <= (others => c_LOW_LEV);
         data_err_rdy_rsys  <= (others => c_LOW_LEV);

      elsif rising_edge(i_clk) then
         mem_dump_bsy_rsys  <= mem_dump_bsy_rsys(mem_dump_bsy_rsys'high-1 downto 0) & i_mem_dump_bsy;
         data_err_rsys      <= i_data_err & data_err_rsys(0 to data_err_rsys'high-1);
         data_err_frst_rsys <= data_err_frst_rsys(data_err_frst_rsys'high-1 downto 0) & i_data_err_frst;
         data_err_last_rsys <= data_err_last_rsys(data_err_last_rsys'high-1 downto 0) & i_data_err_last;
         data_err_rdy_rsys  <= data_err_rdy_rsys( data_err_rdy_rsys'high-1  downto 0) & i_data_err_rdy;

      end if;

   end process P_out_rsync;

   o_mem_dump_bsy_rsys  <= mem_dump_bsy_rsys(mem_dump_bsy_rsys'high);
   o_data_err_rsys      <= data_err_rsys(data_err_rsys'high);
   o_data_err_frst_rsys <= data_err_frst_rsys(data_err_frst_rsys'high);
   o_data_err_last_rsys <= data_err_last_rsys(data_err_last_rsys'high);
   o_data_err_rdy_rsys  <= data_err_rdy_rsys( data_err_rdy_rsys'high);

end architecture RTL;
