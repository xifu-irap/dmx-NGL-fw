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
--!   @file                   squid_data_proc_mem.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process parameter memories management
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_fpga_tech.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;
use     work.pkg_ep_cmd_type.all;

entity squid_data_proc_mem is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_mem_prc            : in     t_mem_prc                                                            ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       : out    t_mem_prc_dta                                                        ; --! Memory for data squid proc.: data read

         i_mem_parma_prm_add  : in     std_logic_vector(c_MEM_PARMA_ADD_S-1  downto 0)                      ; --! Parameter a(p): memory parameter side address
         i_mem_kiknm_prm_add  : in     std_logic_vector(c_MEM_KIKNM_ADD_S-1  downto 0)                      ; --! Parameter ki(p)*knorm(p): memory parameter side address
         i_mem_knorm_prm_add  : in     std_logic_vector(c_MEM_KNORM_ADD_S-1  downto 0)                      ; --! Parameter knorm(p): memory parameter side address
         i_mem_smlkv_prm_add  : in     std_logic_vector(c_MEM_SMLKV_ADD_S-1  downto 0)                      ; --! Parameter Elp(p): memory parameter side address

         i_mem_parma_pp_rdy   : in     std_logic                                                            ; --! Parameter a(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_kiknm_pp_rdy   : in     std_logic                                                            ; --! Parameter ki(p)*knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_knorm_pp_rdy   : in     std_logic                                                            ; --! Parameter knorm(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)
         i_mem_smlkv_pp_rdy   : in     std_logic                                                            ; --! Parameter Elp(p): ping-pong buffer bit ready ('0' = Inactive, '1' = Active)

         o_a_p_aln            : out    std_logic_vector(c_DFLD_PARMA_PIX_S   downto 0)                      ; --! Parameters a(p)
         o_ki_knorm_p_aln     : out    std_logic_vector(c_DFLD_KIKNM_PIX_S   downto 0)                      ; --! Parameters ki(p)*knorm(p)
         o_knorm_p_aln        : out    std_logic_vector(c_DFLD_KNORM_PIX_S   downto 0)                      ; --! Parameters knorm(p)
         o_elp_p_aln          : out    std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                        --! Parameters Elp(p) aligned on E(p,n) bus size
   );
end entity squid_data_proc_mem;

architecture RTL of squid_data_proc_mem is
signal   mem_parma_pp         : std_logic                                                                   ; --! Parameter a(p), TC/HK side: ping-pong buffer bit
signal   mem_parma_prm        : t_mem(
                                add(              c_MEM_PARMA_ADD_S-1 downto 0),
                                data_w(          c_DFLD_PARMA_PIX_S-1 downto 0))                            ; --! Parameter a(p), getting parameter side: memory inputs

signal   mem_kiknm_pp         : std_logic                                                                   ; --! Parameter ki(p)*knorm(p), TC/HK side: ping-pong buffer bit
signal   mem_kiknm_prm        : t_mem(
                                add(              c_MEM_KIKNM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KIKNM_PIX_S-1 downto 0))                            ; --! Parameter ki(p)*knorm(p), getting parameter side: memory inputs

signal   mem_knorm_pp         : std_logic                                                                   ; --! Parameter knorm(p), TC/HK side: ping-pong buffer bit
signal   mem_knorm_prm        : t_mem(
                                add(              c_MEM_KNORM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KNORM_PIX_S-1 downto 0))                            ; --! Parameter knorm(p), getting parameter side: memory inputs

signal   mem_smlkv_pp         : std_logic                                                                   ; --! Parameter elp(p), TC/HK side: ping-pong buffer bit
signal   mem_smlkv_prm        : t_mem(
                                add(              c_MEM_SMLKV_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMLKV_PIX_S-1 downto 0))                            ; --! Parameter elp(p), getting parameter side: memory inputs

signal   a_p                  : std_logic_vector(c_DFLD_PARMA_PIX_S-1 downto 0)                             ; --! Parameters a(p)
signal   ki_knorm_p           : std_logic_vector(c_DFLD_KIKNM_PIX_S-1 downto 0)                             ; --! Parameters ki(p)*knorm(p)
signal   knorm_p              : std_logic_vector(c_DFLD_KNORM_PIX_S-1 downto 0)                             ; --! Parameters knorm(p)
signal   elp_p                : std_logic_vector(c_DFLD_SMLKV_PIX_S-1 downto 0)                             ; --! Parameters Elp(p)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters a(p)
   --    @Req : DRE-DMX-FW-REQ-0180
   --    @Req : REG_CY_A
   -- ------------------------------------------------------------------------------------------------------
   I_mem_parma_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_PARMA_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_PARMA_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_PARMA     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.parma      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.parma , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_parma_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_parma_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => a_p                  , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_a_p_aln <= std_logic_vector(resize(unsigned(a_p), o_a_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory a(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_parma_prm.add     <= i_mem_parma_prm_add;
   mem_parma_prm.we      <= c_LOW_LEV;
   mem_parma_prm.cs      <= c_HGH_LEV;
   mem_parma_prm.data_w  <= c_ZERO(mem_parma_prm.data_w'range);

   --! Memory a(p), ping-pong buffer bit
   P_mem_parma_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_parma_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_parma_pp_rdy = c_HGH_LEV then
            mem_parma_prm.pp   <= mem_parma_pp;

         end if;

      end if;

   end process P_mem_parma_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters ki(p)*knorm(p)
   --    @Req : DRE-DMX-FW-REQ-0170
   --    @Req : REG_CY_KI_KNORM
   -- ------------------------------------------------------------------------------------------------------
   I_mem_kiknm_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_KIKNM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_KIKNM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_KIKNM     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.kiknm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.kiknm , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_kiknm_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_kiknm_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => ki_knorm_p           , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_ki_knorm_p_aln <= std_logic_vector(resize(unsigned(ki_knorm_p), o_ki_knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory ki(p)*knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_kiknm_prm.add     <= i_mem_kiknm_prm_add;
   mem_kiknm_prm.we      <= c_LOW_LEV;
   mem_kiknm_prm.cs      <= c_HGH_LEV;
   mem_kiknm_prm.data_w  <= c_ZERO(mem_kiknm_prm.data_w'range);

   --! Memory ki(p)*knorm(p), ping-pong buffer bit
   P_mem_kiknm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_kiknm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_kiknm_pp_rdy = c_HGH_LEV then
            mem_kiknm_prm.pp   <= mem_kiknm_pp;

         end if;

      end if;

   end process P_mem_kiknm_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters knorm(p)
   --    @Req : DRE-DMX-FW-REQ-0185
   --    @Req : REG_CY_KNORM
   -- ------------------------------------------------------------------------------------------------------
   I_mem_knorm_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_KNORM_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_KNORM_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_KNORM     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.knorm      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.knorm , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_knorm_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_knorm_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => knorm_p              , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_knorm_p_aln <= std_logic_vector(resize(unsigned(knorm_p), o_knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_knorm_prm.add     <= i_mem_knorm_prm_add;
   mem_knorm_prm.we      <= c_LOW_LEV;
   mem_knorm_prm.cs      <= c_HGH_LEV;
   mem_knorm_prm.data_w  <= c_ZERO(mem_knorm_prm.data_w'range);

   --! Memory knorm(p), ping-pong buffer bit
   P_mem_knorm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_knorm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_knorm_pp_rdy = c_HGH_LEV then
            mem_knorm_prm.pp   <= mem_knorm_pp;

         end if;

      end if;

   end process P_mem_knorm_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters Elp(p)
   --    @Req : DRE-DMX-FW-REQ-0190
   --    @Req : REG_CY_MUX_SQ_LOCKPOINT_V
   -- ------------------------------------------------------------------------------------------------------
   I_mem_smlkv_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_SMLKV_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_SMLKV_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_SMLKV     -- integer_vector                                     --! Memory content at initialization
   ) port map (
         i_a_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port A: registers reset ('0' = Inactive, '1' = Active)
         i_a_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port A: main clock
         i_a_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port A: 90 degrees shifted clock (used for memory content correction)

         i_a_mem              => i_mem_prc.smlkv      , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port A inputs (scrubbing with ping-pong buffer bit for parameters storage)
         o_a_data_out         => o_mem_prc_data.smlkv , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port A: data out
         o_a_pp               => mem_smlkv_pp         , -- out    std_logic                                 ; --! Memory port A: ping-pong buffer bit for address management

         o_a_flg_err          => open                 , -- out    std_logic                                 ; --! Memory port A: flag error uncorrectable detected ('0' = No, '1' = Yes)

         i_b_rst              => i_rst                , -- in     std_logic                                 ; --! Memory port B: registers reset ('0' = Inactive, '1' = Active)
         i_b_clk              => i_clk                , -- in     std_logic                                 ; --! Memory port B: main clock
         i_b_clk_shift        => i_clk_90             , -- in     std_logic                                 ; --! Memory port B: 90 degrees shifted clock (used for memory content correction)

         i_b_mem              => mem_smlkv_prm        , -- in     t_mem( add(g_RAM_ADD_S-1 downto 0), ...)  ; --! Memory port B inputs
         o_b_data_out         => elp_p                , -- out    slv(g_RAM_DATA_S-1 downto 0)              ; --! Memory port B: data out

         o_b_flg_err          => open                   -- out    std_logic                                   --! Memory port B: flag error uncorrectable detected ('0' = No, '1' = Yes)
   );

   o_elp_p_aln(o_elp_p_aln'high)                                                           <= c_LOW_LEV;
   o_elp_p_aln(o_elp_p_aln'high-1                downto o_elp_p_aln'length-elp_p'length-1) <= elp_p;
   o_elp_p_aln(o_elp_p_aln'length-elp_p'length-2 downto                                 0) <= c_ZERO(o_elp_p_aln'length-elp_p'length-2 downto 0);

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Elp(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smlkv_prm.add     <= i_mem_smlkv_prm_add;
   mem_smlkv_prm.we      <= c_LOW_LEV;
   mem_smlkv_prm.cs      <= c_HGH_LEV;
   mem_smlkv_prm.data_w  <= c_ZERO(mem_smlkv_prm.data_w'range);

   --! Memory Elp(p), ping-pong buffer bit
   P_mem_smlkv_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = c_RST_LEV_ACT then
         mem_smlkv_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if i_mem_smlkv_pp_rdy = c_HGH_LEV then
            mem_smlkv_prm.pp   <= mem_smlkv_pp;

         end if;

      end if;

   end process P_mem_smlkv_prm_pp;

end architecture RTL;
