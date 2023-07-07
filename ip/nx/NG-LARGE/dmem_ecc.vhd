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
--!   @file                   dmem_ecc.vhd
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
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_project.all;

library nx;
use     nx.nxpackage.all;

entity dmem_ecc is generic (
         g_RAM_TYPE           : integer                                                                     ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          : integer                                                                     ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         : integer                                                                     ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           : integer_vector                                                                --! Memory content at initialization
   ); port (
         i_a_rst              : in     std_logic                                                            ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              : in     std_logic                                                            ; --! Memory port A: main clock
         i_a_clk_shift        : in     std_logic                                                            ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              : in     t_mem( add(g_RAM_ADD_S-1 downto 0), data_w(g_RAM_DATA_S-1 downto 0)) ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         : out    std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port A: data out
         o_a_pp               : out    std_logic                                                            ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          : out    std_logic                                                            ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              : in     std_logic                                                            ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              : in     std_logic                                                            ; --! Memory port B: main clock
         i_b_clk_shift        : in     std_logic                                                            ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              : in     t_mem( add(g_RAM_ADD_S-1 downto 0), data_w(g_RAM_DATA_S-1 downto 0)) ; --! Memory port B inputs
         o_b_data_out         : out    std_logic_vector(g_RAM_DATA_S-1 downto 0)                            ; --! Memory port B: data out

         o_b_flg_err          : out    std_logic                                                              --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );
end entity dmem_ecc;

architecture RTL of dmem_ecc is
constant c_RAM_TYPE           : string    := c_RAM_TYPE(g_RAM_TYPE)                                         ; --! RAM: type
constant c_RAM_NG_LARGE       : bit       := '1'                                                            ; --! RAM: FPGA target NG-LARGE
constant c_RAM_INIT           : string    := conv_ram_init(g_RAM_INIT, c_RAM_ECC_ADD_S, c_RAM_DATA_S)       ; --! RAM: content at initialization

signal   a_mem                : t_mem( add(g_RAM_ADD_S downto 0), data_w(g_RAM_DATA_S-1 downto 0))          ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)

signal   a_add_rsize          : std_logic_vector( c_RAM_ADD_S-1 downto 0)                                   ; --! Memory port A: address  resized
signal   a_data_in_rsize      : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port A: data in  resized
signal   a_data_out_mem       : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port A: data out from memory

signal   b_add_rsize          : std_logic_vector( c_RAM_ADD_S-1 downto 0)                                   ; --! Memory port B: address  resized
signal   b_data_in_rsize      : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port B: data in  resized
signal   b_data_out_mem       : std_logic_vector(c_RAM_DATA_S-1 downto 0)                                   ; --! Memory port B: data out from memory
begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Scrubbing with ping-pong buffer bit for parameters storage memory configuration
   -- ------------------------------------------------------------------------------------------------------
   G_mem_prm_store: if g_RAM_TYPE = c_RAM_TYPE_PRM_STORE generate

      I_mem_scrubbing: entity work.mem_scrubbing generic map (
         g_MEM_ADD_S          => g_RAM_ADD_S          , -- integer                                          ; --! Memory address size (no ping-pong buffer bit)
         g_MEM_DATA_S         => g_RAM_DATA_S           -- integer                                            --! Memory Data to write in memory size
      ) port map (
         i_rst                => i_a_rst              , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_a_clk              , -- in     std_logic                                 ; --! System Clock
         i_mem_no_scrub       => i_a_mem              , -- in     t_mem( add(c_MEM_ADD_S-1 downto 0), ... ) ; --! Memory signals no scrubbing
         o_mem_with_scrub     => a_mem                  -- out    t_mem( add(c_MEM_ADD_S   downto 0), ... )   --! Memory signals with scrubbing and ping-pong buffer bit for address management
      );

   end generate G_mem_prm_store;

   G_mem_not_prm_store: if g_RAM_TYPE /= c_RAM_TYPE_PRM_STORE generate
      a_mem.pp       <= i_a_mem.pp;
      a_mem.add      <= std_logic_vector(resize(unsigned(i_a_mem.add), a_mem.add'length));
      a_mem.we       <= i_a_mem.we;
      a_mem.cs       <= i_a_mem.cs;
      a_mem.data_w   <= i_a_mem.data_w;

   end generate G_mem_not_prm_store;

   o_a_pp <= a_mem.pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Alignment on RAM bus size
   -- ------------------------------------------------------------------------------------------------------
   a_add_rsize       <= std_logic_vector(resize(unsigned(a_mem.add)   , a_add_rsize'length));
   a_data_in_rsize   <= std_logic_vector(resize(unsigned(a_mem.data_w), a_data_in_rsize'length));

   b_add_rsize       <= std_logic_vector(resize(unsigned(i_b_mem.pp & i_b_mem.add)  , b_add_rsize'length));
   b_data_in_rsize   <= std_logic_vector(resize(unsigned(i_b_mem.data_w)            , b_data_in_rsize'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   NX_RAM_WRAP IpCore instantiation
   -- ------------------------------------------------------------------------------------------------------
   I_ram: entity nx.nx_ram_wrap generic map (
         STD_MODE             => c_RAM_TYPE           , -- string                                           ; --! RAM predefined operating mode
         MCKA_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port A: clock front polarity ('0' = rising edge, '1' = falling edge)
         MCKB_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port B: clock front polarity ('0' = rising edge, '1' = falling edge)
         PCKA_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port A: register clock front polarity ('0' = rising edge, '1' = falling edge)
         PCKB_EDGE            => c_RAM_CLK_RE         , -- bit                                              ; --! Memory port B: register clock front polarity ('0' = rising edge, '1' = falling edge)
         PIPE_IA              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port A: register at the port inputs  ('0' = Disable, '1' = Enable)
         PIPE_IB              => c_RAM_PRM_DIS        , -- bit                                              ; --! Memory port B: register at the port inputs  ('0' = Disable, '1' = Enable)
         PIPE_OA              => c_RAM_PRM_ENA        , -- bit                                              ; --! Memory port A: register at the port outputs ('0' = Disable, '1' = Enable)
         PIPE_OB              => c_RAM_PRM_ENA        , -- bit                                              ; --! Memory port B: register at the port outputs ('0' = Disable, '1' = Enable)
         RAW_CONFIG0          => (others => c_LOW_LEV_B), -- bit_vector( 3 downto 0)                        ; --! Optional registers declaration. Ignored if STD_MODE is not empty
         RAW_CONFIG1          => (others => c_LOW_LEV_B), -- bit_vector(15 downto 0)                        ; --! RAM configuration. Ignored if STD_MODE is not empty
         RAW_L_ENABLE         => c_RAM_NG_LARGE       , -- bit                                              ; --! FPGA target('0' = NG-MEDIUM, '1' = NG-LARGE)
         RAW_L_EXTEND         => (others => c_LOW_LEV_B), -- bit_vector( 3 downto 0)                        ; --! Not used
         MEM_CTXT             => c_RAM_INIT             -- string                                             --! Memory content at initialization
   )     port map (
         ar                   => i_a_rst              , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         ackr                 => i_a_clk              , -- in     std_logic                                 ; --! Memory port A: registers clock
         ack                  => i_a_clk              , -- in     std_logic                                 ; --! Memory port A: main clock
         ackd                 => i_a_clk_shift        , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         aa                   => a_add_rsize          , -- in     std_logic_vector(c_RAM_ADD_S-1 downto 0)  ; --! Memory port A: address
         awe                  => a_mem.we             , -- in     std_logic                                 ; --! Memory port A: write enable ('0' = Inactive, '1' = Active)
         acs                  => a_mem.cs             , -- in     std_logic                                 ; --! Memory port A: chip select ('0' = Inactive, '1' = Active)
         ai                   => a_data_in_rsize      , -- in     std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port A: data in
         ao                   => a_data_out_mem       , -- out    std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port A: data out

         acor                 => open                 , -- out    std_logic                                 ; --! Memory port A: flag error detected and corrected ('0' = No, '1' = Yes)
         aerr                 => o_a_flg_err          , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         br                   => i_b_rst              , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         bckr                 => i_b_clk              , -- in     std_logic                                 ; --! Memory port B: registers clock
         bck                  => i_b_clk              , -- in     std_logic                                 ; --! Memory port B: main clock
         bckd                 => i_b_clk_shift        , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         ba                   => b_add_rsize          , -- in     std_logic_vector(c_RAM_ADD_S-1 downto 0)  ; --! Memory port B: address
         bwe                  => i_b_mem.we           , -- in     std_logic                                 ; --! Memory port B: write enable ('0' = Inactive, '1' = Active)
         bcs                  => i_b_mem.cs           , -- in     std_logic                                 ; --! Memory port B: chip select ('0' = Inactive, '1' = Active)
         bi                   => b_data_in_rsize      , -- in     std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port B: data in
         bo                   => b_data_out_mem       , -- out    std_logic_vector(c_RAM_DATA_S-1 downto 0) ; --! Memory port B: data out

         bcor                 => open                 , -- out    std_logic                                 ; --! Memory port B: flag error detected and corrected ('0' = No, '1' = Yes)
         berr                 => o_b_flg_err            -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_a_data_out <= std_logic_vector(resize(unsigned(a_data_out_mem), o_a_data_out'length));
   o_b_data_out <= std_logic_vector(resize(unsigned(b_data_out_mem), o_b_data_out'length));

end architecture RTL;
