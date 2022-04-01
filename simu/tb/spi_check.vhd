-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-ngl-fw is free software: you can redistribute it and/or modify
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
--!   @file                   spi_check.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                SPI parameters check
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

library work;
use     work.pkg_model.all;

entity spi_check is generic
   (     g_SPI_TIME_CHK       : t_time_arr(0 to c_SPI_ERR_CHK_NB-3)                                         ; --! SPI timings to check
         g_CPOL               : std_logic                                                                     --! Clock polarity
   ); port
   (     i_spi_mosi           : in     std_logic                                                            ; --! SPI - Master Output Slave Input data
         i_spi_sclk           : in     std_logic                                                            ; --! SPI - Serial Clock
         i_spi_cs_n           : in     std_logic                                                            ; --! SPI - Chip Select

         o_err_n_spi_chk      : out    t_int_arr(0 to c_SPI_ERR_CHK_NB-1)                                     --! SPI check error number:
   );
end entity spi_check;

architecture Behavioral of spi_check is
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of serial clock state error when chip select goes to active/inactive
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_sclk_st_cs : process
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_STSCI) <= 0;
         o_err_n_spi_chk(c_SPI_ERR_POS_STSCA) <= 0;

      end if;

      wait until i_spi_cs_n'event;

      if i_spi_cs_n = '1' and i_spi_sclk = not(g_CPOL) then
         o_err_n_spi_chk(c_SPI_ERR_POS_STSCI) <= o_err_n_spi_chk(c_SPI_ERR_POS_STSCI) + 1;

      elsif i_spi_cs_n = '0' and i_spi_sclk = g_CPOL then
         o_err_n_spi_chk(c_SPI_ERR_POS_STSCA) <= o_err_n_spi_chk(c_SPI_ERR_POS_STSCA) + 1;

      end if;

   end process P_err_n_sclk_st_cs;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of low/high level serial clock timing error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_sclk_per : process
   variable v_record_time1    : time                                                                        ; --! Record time 1
   variable v_record_time2    : time                                                                        ; --! Record time 2
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TL)      <= 0;
         o_err_n_spi_chk(c_SPI_ERR_POS_TH)      <= 0;
         o_err_n_spi_chk(c_SPI_ERR_POS_TSCMIN)  <= 0;

         v_record_time1 := now;

      end if;

      v_record_time2 := v_record_time1;
      v_record_time1 := now;

      wait until i_spi_sclk'event;

      if i_spi_cs_n = '0' then

         if i_spi_sclk = '1' and (now-v_record_time1) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TL) then
            o_err_n_spi_chk(c_SPI_ERR_POS_TL) <= o_err_n_spi_chk(c_SPI_ERR_POS_TL) + 1;

         elsif i_spi_sclk = '0' and (now-v_record_time1) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TH) then
            o_err_n_spi_chk(c_SPI_ERR_POS_TH) <= o_err_n_spi_chk(c_SPI_ERR_POS_TH) + 1;

         end if;

         if (now-v_record_time2) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TSCMIN) then
            o_err_n_spi_chk(c_SPI_ERR_POS_TSCMIN) <= o_err_n_spi_chk(c_SPI_ERR_POS_TSCMIN) + 1;

         end if;

      end if;

   end process P_err_n_sclk_per;

   P_err_n_sclk_per_max : process
   variable v_record_time1    : time                                                                        ; --! Record time 1
   variable v_record_time2    : time                                                                        ; --! Record time 2
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TSCMAX)  <= 0;

         v_record_time1 := now;

      end if;

      v_record_time2 := v_record_time1;
      v_record_time1 := now;

      wait until i_spi_sclk'event for g_SPI_TIME_CHK(c_SPI_ERR_POS_TSCMAX);

      if i_spi_cs_n = '0' and i_spi_cs_n'last_event > g_SPI_TIME_CHK(c_SPI_ERR_POS_TSCMAX) then

         if (now-v_record_time2) > g_SPI_TIME_CHK(c_SPI_ERR_POS_TSCMAX) then
            o_err_n_spi_chk(c_SPI_ERR_POS_TSCMAX) <= o_err_n_spi_chk(c_SPI_ERR_POS_TSCMAX) + 1;

         end if;

      end if;

   end process P_err_n_sclk_per_max;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of high level chip select timing error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_cs_high : process
   variable v_record_time     : time                                                                        ; --! Record time
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TCSH) <= 0;

      end if;

      v_record_time := now;
      wait until falling_edge(i_spi_cs_n);

      if (now - v_record_time) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TCSH) then
         o_err_n_spi_chk(c_SPI_ERR_POS_TCSH) <= o_err_n_spi_chk(c_SPI_ERR_POS_TCSH) + 1;

      end if;

      wait until rising_edge(i_spi_cs_n);

   end process P_err_n_cs_high;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of not(SCLK) to CS rising edge timing error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_sclk_cs_ris : process
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TS2CSR) <= 0;

      end if;

      wait until rising_edge(i_spi_cs_n);

      if i_spi_sclk'last_event < g_SPI_TIME_CHK(c_SPI_ERR_POS_TS2CSR) then
         o_err_n_spi_chk(c_SPI_ERR_POS_TS2CSR) <= o_err_n_spi_chk(c_SPI_ERR_POS_TS2CSR) + 1;

      end if;

   end process P_err_n_sclk_cs_ris;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of Data Event to not(SCLK) time error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_mosi_sclk : process
   variable v_record_time     : time                                                                        ; --! Record time
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TD2S) <= 0;

      end if;

      wait until i_spi_mosi'event;
      v_record_time := now;

      wait until i_spi_sclk'event and i_spi_sclk = g_CPOL;

      if (now - v_record_time) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TD2S) then
         o_err_n_spi_chk(c_SPI_ERR_POS_TD2S) <= o_err_n_spi_chk(c_SPI_ERR_POS_TD2S) + 1;

      end if;

   end process P_err_n_mosi_sclk;

   -- ------------------------------------------------------------------------------------------------------
   --!   Number of not(SCLK) to Data Event time error
   -- ------------------------------------------------------------------------------------------------------
   P_err_n_sclk_mosi : process
   variable v_record_time     : time                                                                        ; --! Record time
   begin

      if now = 0 ps then
         o_err_n_spi_chk(c_SPI_ERR_POS_TS2D) <= 0;

      end if;

      wait until i_spi_sclk'event and i_spi_sclk = g_CPOL;
      v_record_time := now;

      wait until i_spi_mosi'event;

      if (now - v_record_time) < g_SPI_TIME_CHK(c_SPI_ERR_POS_TS2D) then
         o_err_n_spi_chk(c_SPI_ERR_POS_TS2D) <= o_err_n_spi_chk(c_SPI_ERR_POS_TS2D) + 1;

      end if;

   end process P_err_n_sclk_mosi;

end architecture Behavioral;
