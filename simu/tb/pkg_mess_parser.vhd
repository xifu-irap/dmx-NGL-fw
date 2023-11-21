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
--!   @file                   pkg_mess_parser.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Package message result parser
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_type.all;
use     work.pkg_project.all;
use     work.pkg_mess.all;
use     work.pkg_model.all;

library std;
use std.textio.all;

package pkg_mess_parser is

   -- ------------------------------------------------------------------------------------------------------
   --! Clock parameters result message
   -- ------------------------------------------------------------------------------------------------------
   procedure clock_param_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_chk_rpt        : in     t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)     ; --! Clock check error reports
         o_err_chk_clk_prm    : out    std_logic                                                            ; --! Error check clocks parameters ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   );

   -- ------------------------------------------------------------------------------------------------------
   --! SPI parameters result message
   -- ------------------------------------------------------------------------------------------------------
   procedure spi_param_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_n_spi_chk      : in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)      ; --! SPI check error number:
         o_err_chk_spi_prm    : out    std_logic                                                            ; --! Error check SPI parameters ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Pulse shaping result message
   -- ------------------------------------------------------------------------------------------------------
   procedure pls_shaping_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_num_pls_shp    : in     integer_vector(0 to c_NB_COL-1)                                      ; --! Pulse shaping error number
         o_err_chk_pls_shp    : out    std_logic                                                            ; --! Error check pulse shaping ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   );

   -- ------------------------------------------------------------------------------------------------------
   --! Final result message
   -- ------------------------------------------------------------------------------------------------------
   procedure final_mess_res (
         i_error_cat          : in     std_logic_vector(c_ERROR_CAT_NB-1 downto 0)                          ; --! Error category
signal   i_sc_pkt_err         : in     std_logic                                                            ; --! Science packet error ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   );

end pkg_mess_parser;

package body pkg_mess_parser is

   -- ------------------------------------------------------------------------------------------------------
   --! Clock parameters result message
   -- ------------------------------------------------------------------------------------------------------
   procedure clock_param_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_chk_rpt        : in     t_int_arr_tab(0 to c_CHK_ENA_CLK_NB-1)(0 to c_ERR_N_CLK_CHK_S-1)     ; --! Clock check error reports
         o_err_chk_clk_prm    : out    std_logic                                                            ; --! Error check clocks parameters ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   ) is
   begin

      -- Clocks parameters results
      o_err_chk_clk_prm := c_LOW_LEV;
      for k in 0 to c_CHK_ENA_CLK_NB-1 loop

         -- Check if clock parameters check is enabled
         if i_chk_rpt_prm_ena(k) = c_HGH_LEV then

            -- Write clock parameters check results
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);
            fprintf(none, "Parameters check, clock " & c_CCHK(k).clk_name , res_file);
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);

            -- Check if oscillation on clock when enable inactive parameter is disable
            if c_CCHK(k).chk_osc_en = c_CHK_OSC_DIS then
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_OSC_EN_L)) &
               ", inactive parameter (no check)", res_file);

            else
               fprintf(none, "Error number of clock oscillation when enable is inactive : " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_OSC_EN_L))
               , res_file);

            end if;

            fprintf(none, "Error number of high level clock period timing :            " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_PER_H)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_h), res_file);

            fprintf(none, "Error number of low  level clock period timing :            " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_PER_L)) &
            ", expected timing: " & time'image(c_CCHK(k).clk_per_l), res_file);

            fprintf(none, "Error number of clock state when enable goes to inactive :  " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_ST_EN_L)) &
            ", expected state:  " & std_logic'image(c_CCHK(k).clk_st_ena), res_file);

            fprintf(none, "Error number of clock state when enable goes to active   :  " & integer'image(i_err_chk_rpt(k)(c_ERR_N_CLK_ST_EN_H)) &
            ", expected state:  " & std_logic'image(c_CCHK(k).clk_st_dis), res_file);

            -- Set possible error
            for j in 0 to c_ERR_N_CLK_CHK_S-1 loop
               if i_err_chk_rpt(k)(j) /= c_ZERO_INT then
                  o_err_chk_clk_prm := c_HGH_LEV;
               end if;
            end loop;

         end if;
      end loop;

   end clock_param_res;

   -- ------------------------------------------------------------------------------------------------------
   --! SPI parameters result message
   -- ------------------------------------------------------------------------------------------------------
   procedure spi_param_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_n_spi_chk      : in     t_int_arr_tab(0 to c_CHK_ENA_SPI_NB-1)(0 to c_SPI_ERR_CHK_NB-1)      ; --! SPI check error number:
         o_err_chk_spi_prm    : out    std_logic                                                            ; --! Error check SPI parameters ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   ) is
   begin

      -- SPI parameters results
      o_err_chk_spi_prm := c_LOW_LEV;
      for k in 0 to c_CHK_ENA_SPI_NB-1 loop

         -- Check if SPI parameters check is enabled
         if i_chk_rpt_prm_ena(k+c_CHK_ENA_CLK_NB) = c_HGH_LEV then

            -- Write SPI parameters check results
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);
            fprintf(none, "Parameters check, SPI " & c_SCHK(k).spi_name , res_file);
            fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR , res_file);

            fprintf(none, "Error number of low level sclk timing  :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TL)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TL)), res_file);

            fprintf(none, "Error number of high level sclk timing :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TH)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TH)), res_file);

            fprintf(none, "Error number of sclk minimum period    :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TSCMIN)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TSCMIN)), res_file);

            fprintf(none, "Error number of sclk maximum period    :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TSCMAX)) &
            ", expected timing <= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TSCMAX)), res_file);

            fprintf(none, "Error number of high level cs timing   :                    " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TCSH)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TCSH)), res_file);

            fprintf(none, "Error number of sclk edge to cs rising edge timing :        " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TS2CSR)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TS2CSR)), res_file);

            fprintf(none, "Error number of data edge to sclk edge timing :             " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TD2S)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TD2S)), res_file);

            fprintf(none, "Error number of sclk edge to data edge timing :             " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_TS2D)) &
            ", expected timing >= " & time'image(c_SCHK(k).spi_time(c_SPI_ERR_POS_TS2D)), res_file);

            fprintf(none, "Error number of sclk state when cs goes to active   :       " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_STSCA)), res_file);
            fprintf(none, "Error number of sclk state when cs goes to inactive :       " & integer'image(i_err_n_spi_chk(k)(c_SPI_ERR_POS_STSCI)), res_file);

            -- Set possible error
            for j in 0 to c_SPI_ERR_CHK_NB-1 loop
               if i_err_n_spi_chk(k)(j) /= c_ZERO_INT then
                  o_err_chk_spi_prm := c_HGH_LEV;
               end if;
            end loop;

         end if;
      end loop;

   end spi_param_res;

   -- ------------------------------------------------------------------------------------------------------
   --! Pulse shaping result message
   -- ------------------------------------------------------------------------------------------------------
   procedure pls_shaping_res (
         i_chk_rpt_prm_ena    : in     std_logic_vector(c_CMD_FILE_FLD_DATA_S-1 downto 0)                   ; --! Check report parameters enable
signal   i_err_num_pls_shp    : in     integer_vector(0 to c_NB_COL-1)                                      ; --! Pulse shaping error number
         o_err_chk_pls_shp    : out    std_logic                                                            ; --! Error check pulse shaping ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   ) is
   begin

      -- Pulse shaping error report
      o_err_chk_pls_shp := c_LOW_LEV;
      if i_chk_rpt_prm_ena(c_E_PLS_SHP) = c_HGH_LEV then
         fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

         for k in 0 to c_NB_COL-1 loop

            fprintf(none, "Error number pulse shaping channel " & integer'image(k) & ": " & integer'image(i_err_num_pls_shp(k)),   res_file);

            if i_err_num_pls_shp(k) /= c_ZERO_INT then
               o_err_chk_pls_shp := c_HGH_LEV;
            end if;

         end loop;

      end if;

   end pls_shaping_res;

   -- ------------------------------------------------------------------------------------------------------
   --! Final result message
   -- ------------------------------------------------------------------------------------------------------
   procedure final_mess_res (
         i_error_cat          : in     std_logic_vector(c_ERROR_CAT_NB-1 downto 0)                          ; --! Error category
signal   i_sc_pkt_err         : in     std_logic                                                            ; --! Science packet error ('0' = No error, '1' = Error)
         file res_file        : text                                                                          --  Result File
   ) is
   begin

      -- Result file end
      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Error simulation time         : " & std_logic'image(i_error_cat(c_ERR_SIM_TIME)),   res_file);
      fprintf(none, "Error check discrete level    : " & std_logic'image(i_error_cat(c_ERR_CHK_DIS_R)),  res_file);
      fprintf(none, "Error check command return    : " & std_logic'image(i_error_cat(c_ERR_CHK_CMD_R)),  res_file);
      fprintf(none, "Error check time              : " & std_logic'image(i_error_cat(c_ERR_CHK_TIME)),   res_file);
      fprintf(none, "Error check clocks parameters : " & std_logic'image(i_error_cat(c_ERR_CHK_CLK_PRM)),res_file);
      fprintf(none, "Error check spi parameters    : " & std_logic'image(i_error_cat(c_ERR_CHK_SPI_PRM)),res_file);
      fprintf(none, "Error check science packets   : " & std_logic'image(i_error_cat(c_ERR_CHK_SC_PKT) or i_sc_pkt_err), res_file);
      fprintf(none, "Error check pulse shaping     : " & std_logic'image(i_error_cat(c_ERR_CHK_PLS_SHP)),res_file);

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);
      fprintf(none, "Simulation time               : " & time'image(now), res_file);

      -- Final test status
      if i_error_cat = c_ZERO(i_error_cat'range) and i_sc_pkt_err = c_LOW_LEV then
         fprintf(none, "Simulation status             : PASS", res_file);

      else
         fprintf(none, "Simulation status             : FAIL", res_file);

      end if;

      fprintf(none, c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR & c_RES_FILE_DIV_BAR, res_file);

   end final_mess_res;

end package body pkg_mess_parser;
