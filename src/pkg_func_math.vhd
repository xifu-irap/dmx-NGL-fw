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
--!   @file                   pkg_func_math.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Mathematical function package
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;

package pkg_func_math is

function log2_ceil              (X: in integer) return integer                                              ; --! return logarithm base 2 of X  (ceil integer)
function div_ceil               (X: in integer; Y : in integer) return integer                              ; --! return X/Y (ceil integer)
function div_floor              (X: in integer; Y : in integer) return integer                              ; --! return X/Y (floor integer)
function div_round              (X: in integer; Y : in integer) return integer                              ; --! return X/Y (round integer)
function resize_stall_msb       (ARG : in std_logic_vector; NEW_SIZE : in integer) return std_logic_vector  ; --! return resized data stalled on Mean Significant Bit

end pkg_func_math;

package body pkg_func_math is

   -- ------------------------------------------------------------------------------------------------------
   --! return logarithm base 2 of X  (ceil integer)
   -- ------------------------------------------------------------------------------------------------------
   function log2_ceil           (X: in integer) return integer is
   begin
      return integer(ceil(log2(real(X))));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (ceil integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_ceil            (X: in integer; Y : in integer) return integer is
   begin
      return integer(ceil(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (floor integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_floor           (X: in integer; Y : in integer) return integer is
   begin
      return integer(floor(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return X/Y (round integer)
   -- ------------------------------------------------------------------------------------------------------
   function div_round           (X: in integer; Y : in integer) return integer is
   begin
      return integer(round(real(X)/real(Y)));
   end function;

   -- ------------------------------------------------------------------------------------------------------
   --! return resized data stalled on Mean Significant Bit
   -- ------------------------------------------------------------------------------------------------------
   function resize_stall_msb    (ARG : in std_logic_vector; NEW_SIZE : in integer) return std_logic_vector is
   variable v_result          : std_logic_vector(NEW_SIZE-1 downto 0)                                       ; --  Result
   begin
      for k in 0 to v_result'high loop
         if k <= ARG'length then
            v_result(v_result'high - k) := ARG(ARG'high - k);

         else
            v_result(v_result'high - k) := '0';

         end if;

      end loop;

      return v_result;

   end function;

end pkg_func_math;
