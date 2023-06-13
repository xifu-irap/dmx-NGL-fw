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
--!   @file                   pkg_type.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Type package
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

package pkg_type is

type     t_slv_arr             is array (natural range <>) of std_logic_vector                              ; --! std_logic_vector array type
type     t_slv_arr_tab         is array (natural range <>) of t_slv_arr                                     ; --! std_logic_vector array table type
type     t_int_arr             is array (natural range <>) of integer                                       ; --! Integer array type
type     t_int_arr_tab         is array (natural range <>) of t_int_arr                                     ; --! Integer array table type
type     t_str_arr             is array (natural range <>) of string                                        ; --! String array type

type     t_mem                 is record
         pp                   : std_logic                                                                   ; --! Ping-pong buffer bit
         add                  : std_logic_vector                                                            ; --! Address
         we                   : std_logic                                                                   ; --! Write enable ('0' = Inactive, '1' = Active)
         cs                   : std_logic                                                                   ; --! Chip select  ('0' = Inactive, '1' = Active)
         data_w               : std_logic_vector                                                            ; --! Data to write in memory
end record t_mem                                                                                            ; --! Memory signals interface

type     t_mem_arr             is array (natural range <>) of t_mem                                         ; --! Memory signals interface array

end pkg_type;
