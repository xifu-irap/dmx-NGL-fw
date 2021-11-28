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
--!   @file                   mem_param.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Dual port memory with ecc
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_fpga_tech.all;

library nx;
use     nx.nxpackage.all;

entity dmem_ecc is generic
   (     g_RAM_TYPE           : integer                                                                     ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          : integer                                                                     ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         : integer                                                                     ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           : t_ram_init                                                                    --! Memory content at initialization
   ); port
   (     a_clk                : in     std_logic                                                            ; --! Memory port A: main clock
         a_clk_shift          : in     std_logic                                                            ; --! Memory port A: 90° shifted clock (used for memory content correction)

         a_add                : in     std_logic_vector( g_RAM_ADD_S-1 downto 0)                            ; --! Memory port A: address
         a_we                 : in     std_logic                                                            ; --! Memory port A: write enable ('0' = Inactive, '1' = Active)
         a_cs                 : in     std_logic                                                            ; --! Memory port A: chip select ('0' = Inactive, '1' = Active)
         a_data_in            : in     std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port A: data in
         a_data_out           : out    std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port A: data out

         a_flg_err            : out    std_logic                                                            ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         b_clk                : in     std_logic                                                            ; --! Memory port B: main clock
         b_clk_shift          : in     std_logic                                                            ; --! Memory port B: 90° shifted clock (used for memory content correction)

         b_add                : in     std_logic_vector( g_RAM_ADD_S-1 downto 0)                            ; --! Memory port B: address
         b_we                 : in     std_logic                                                            ; --! Memory port B: write enable ('0' = Inactive, '1' = Active)
         b_cs                 : in     std_logic                                                            ; --! Memory port B: chip select ('0' = Inactive, '1' = Active)
         b_data_in            : in     std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port B: data in
         b_data_out           : out    std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port B: data out

         b_flg_err            : out    std_logic                                                              --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );
end entity dmem_ecc;

architecture RTL of dmem_ecc is
constant c_RAM_TYPE           : string    := c_RAM_TYPE(g_RAM_TYPE)                                         ; --! RAM: type
constant c_RAM_NG_LARGE       : bit       := '1'                                                            ; --! RAM: FPGA target NG-LARGE
constant c_RAM_INIT           : string    := conv_ram_init(g_RAM_INIT, c_RAM_ECC_ADD_S, c_RAM_DATA_S)       ; --! RAM: content at initialization

signal   a_add_rsize          : std_logic_vector( c_RAM_ADD_S-1 downto 0)                                   ; --! Memory port A: address  resized
signal   a_data_in_rsize      : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port A: data in  resized
signal   a_data_out_mem       : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port A: data out from memory

signal   b_add_rsize          : std_logic_vector( c_RAM_ADD_S-1 downto 0)                                   ; --! Memory port B: address  resized
signal   b_data_in_rsize      : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port B: data in  resized
signal   b_data_out_mem       : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port B: data out from memory
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on RAM bus size
   -- ------------------------------------------------------------------------------------------------------
   a_add_rsize       <= std_logic_vector(resize(unsigned(a_add)      , a_add_rsize'length));
   a_data_in_rsize   <= std_logic_vector(resize(unsigned(a_data_in)  , a_data_in_rsize'length));

   b_add_rsize       <= std_logic_vector(resize(unsigned(b_add)      , b_add_rsize'length));
   b_data_in_rsize   <= std_logic_vector(resize(unsigned(b_data_in)  , b_data_in_rsize'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_RAM_WRAP IpCore instantiation
   -- ------------------------------------------------------------------------------------------------------
   I_RAM: entity nx.nx_ram_wrap generic map
   (     STD_MODE             => c_RAM_TYPE           , -- string                                           ; --! RAM predefined operating mode
         MCKA_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port A: clock front polarity ('0' = rising edge, '1' = falling edge)
         MCKB_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port B: clock front polarity ('0' = rising edge, '1' = falling edge)
         PCKA_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port A: register clock front polarity ('0' = rising edge, '1' = falling edge)
         PCKB_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port B: register clock front polarity ('0' = rising edge, '1' = falling edge)
         PIPE_IA              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port A: register at the port inputs  ('0' = Disable, '1' = Enable)
         PIPE_IB              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port B: register at the port inputs  ('0' = Disable, '1' = Enable)
         PIPE_OA              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port A: register at the port outputs ('0' = Disable, '1' = Enable)
         PIPE_OB              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port B: register at the port outputs ('0' = Disable, '1' = Enable)
         RAW_CONFIG0          => (others => '0')      , -- bit_vector( 3 downto 0)                          ; --! Optional registers declaration. Ignored if STD_MODE is not empty
         RAW_CONFIG1          => (others => '0')      , -- bit_vector(15 downto 0)                          ; --! RAM configuration. Ignored if STD_MODE is not empty
         RAW_L_ENABLE         => c_RAM_NG_LARGE       , -- bit                                              ; --! FPGA target('0' = NG-MEDIUM, '1' = NG-LARGE)
         RAW_L_EXTEND         => (others => '0')      , -- bit_vector( 3 downto 0)                          ; --! Not used
         MEM_CTXT             => c_RAM_INIT             -- string                                             --! Memory content at initialization
   )     port map
   (     ar                   => '0'                  , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         ackr                 => '0'                  , -- in     std_logic                                 ; --! Memory port A: registers clock
         ack                  => a_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         ackd                 => a_clk_shift          , -- in     std_logic                                 ; --! Memory port A: 90° shifted clock (used for memory content correction)

         aa                   => a_add_rsize          , -- in     std_logic_vector(c_RAM_ADD_S-1 downto 0)  ; --! Memory port A: address
         awe                  => a_we                 , -- in     std_logic                                 ; --! Memory port A: write enable ('0' = Inactive, '1' = Active)
         acs                  => a_cs                 , -- in     std_logic                                 ; --! Memory port A: chip select ('0' = Inactive, '1' = Active)
         ai                   => a_data_in_rsize      , -- in     std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port A: data in
         ao                   => a_data_out_mem       , -- out    std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port A: data out

         acor                 => open                 , -- out    std_logic                                 ; --! Memory port A: flag error detected and corrected ('0' = No, '1' = Yes)
         aerr                 => a_flg_err            , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         br                   => '0'                  , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         bckr                 => '0'                  , -- in     std_logic                                 ; --! Memory port B: registers clock
         bck                  => b_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         bckd                 => b_clk_shift          , -- in     std_logic                                 ; --! Memory port B: 90° shifted clock (used for memory content correction)

         ba                   => b_add_rsize          , -- in     std_logic_vector(c_RAM_ADD_S-1 downto 0)  ; --! Memory port B: address
         bwe                  => b_we                 , -- in     std_logic                                 ; --! Memory port B: write enable ('0' = Inactive, '1' = Active)
         bcs                  => b_cs                 , -- in     std_logic                                 ; --! Memory port B: chip select ('0' = Inactive, '1' = Active)
         bi                   => b_data_in_rsize      , -- in     std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port B: data in
         bo                   => b_data_out_mem       , -- out    std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port B: data out

         bcor                 => open                 , -- out    std_logic                                 ; --! Memory port B: flag error detected and corrected ('0' = No, '1' = Yes)
         berr                 => b_flg_err              -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   a_data_out <= std_logic_vector(resize(unsigned(a_data_out_mem), a_data_out'length));
   b_data_out <= std_logic_vector(resize(unsigned(b_data_out_mem), b_data_out'length));

end architecture rtl;
