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
--!   @file                   pkg_science_data.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package science data
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_mess.all;

library std;
use std.textio.all;

package pkg_science_data is

   -- ------------------------------------------------------------------------------------------------------
   --! Science data error display
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_err_display (
         i_err_sc_dta_ena     : in     std_logic                                                            ; --  Error science data enable ('0' = No, '1' = Yes)
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
         i_science_data_err   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Science data error ('0' = No error, '1' = Error)
         i_mem_dmp_sc_dta_out : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --  Memory Dump, science side: data out
         i_err_sc_ctrl_dif    : in     std_logic                                                            ; --  Error science data control similar ('0' = No error, '1' = Error)
         i_err_sc_ctrl_ukn    : in     std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         i_err_sc_pkt_start   : in     std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_eod     : in     std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_size    : in     std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
         i_err_sc_data        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Error science data ('0' = No error, '1' = Error)
signal   o_sc_pkt_err         : out    std_logic                                                            ; --  Science packet error ('0' = No error, '1' = Error)
         file scd_file        : text                                                                          --  Science Data Result file
   );

end pkg_science_data;

package body pkg_science_data is

   -- ------------------------------------------------------------------------------------------------------
   --! Science data error display
   -- ------------------------------------------------------------------------------------------------------
   procedure sc_data_err_display (
         i_err_sc_dta_ena     : in     std_logic                                                            ; --  Error science data enable ('0' = No, '1' = Yes)
         i_science_data       : in     t_slv_arr(0 to c_NB_COL-1)
                                                (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --  Science Data: Data
         i_science_data_err   : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Science data error ('0' = No error, '1' = Error)
         i_mem_dmp_sc_dta_out : in     t_slv_arr(0 to c_NB_COL-1)(c_SQM_ADC_DATA_S+1 downto 0)              ; --  Memory Dump, science side: data out
         i_err_sc_ctrl_dif    : in     std_logic                                                            ; --  Error science data control similar ('0' = No error, '1' = Error)
         i_err_sc_ctrl_ukn    : in     std_logic                                                            ; --  Error science data control unknown ('0' = No error, '1' = Error)
         i_err_sc_pkt_start   : in     std_logic                                                            ; --  Error science packet start missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_eod     : in     std_logic                                                            ; --  Error science packet end of data missing ('0' = No error, '1' = Error)
         i_err_sc_pkt_size    : in     std_logic                                                            ; --  Error science packet size ('0' = No error, '1' = Error)
         i_err_sc_data        : in     std_logic_vector(c_NB_COL-1 downto 0)                                ; --  Error science data ('0' = No error, '1' = Error)
signal   o_sc_pkt_err         : out    std_logic                                                            ; --  Science packet error ('0' = No error, '1' = Error)
         file scd_file        : text                                                                          --  Science Data Result file
   ) is
   begin

      -- Errors display
      if i_err_sc_ctrl_dif = '1' then
         o_sc_pkt_err <= '1';
         fprintf(error, "Science Data Control different on the two lines", scd_file);
      end if;

      if i_err_sc_ctrl_ukn = '1' then
         o_sc_pkt_err <= '1';
         fprintf(error, "Science Data Control unknown", scd_file);
      end if;

      if i_err_sc_pkt_start = '1' then
         o_sc_pkt_err <= '1';
         fprintf(error, "Science Data packet header missing", scd_file);
      end if;

      if i_err_sc_pkt_eod = '1' then
         o_sc_pkt_err <= '1';
         fprintf(error, "Science Data packet end of data missing", scd_file);
      end if;

      if i_err_sc_pkt_size = '1' then
         o_sc_pkt_err <= '1';
         fprintf(error, "Science Data packet size not expected", scd_file);
      end if;

      G_science_data_err : for k in 0 to c_NB_COL-1 loop

         if (i_err_sc_data(k) and i_err_sc_dta_ena) = '1' then
            o_sc_pkt_err <= '1';
            fprintf(error, "Science Data packet content, column " & integer'image(k) &
                           ", does not correspond to ADC input (Read: " & hfield_format(i_science_data(k)).all & ", Expected: " & hfield_format(i_mem_dmp_sc_dta_out(k)).all & ")", scd_file);
         end if;

         if (i_science_data_err(k) and i_err_sc_dta_ena) = '1' then
            o_sc_pkt_err <= '1';
            fprintf(error, "Science Data packet content, column " & integer'image(k) & ", not expected", scd_file);
         end if;

      end loop G_science_data_err;

   end sc_data_err_display;

end package body pkg_science_data;
