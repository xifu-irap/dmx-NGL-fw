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
--!   @file                   squid_data_proc.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                Squid Data process
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

entity squid_data_proc is port (
         i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock
         i_clk_90             : in     std_logic                                                            ; --! System Clock 90 degrees shift

         i_aqmde              : in     std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                          ; --! Telemetry mode
         i_smfmd              : in     std_logic_vector(c_DFLD_SMFMD_COL_S-1 downto 0)                      ; --! SQUID MUX feedback mode
         i_bxlgt              : in     std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                      ; --! ADC sample number for averaging
         i_sqm_adc_pwdn       : in     std_logic                                                            ; --! SQUID MUX ADC: Power Down ('0' = Inactive, '1' = Active)

         i_mem_prc            : in     t_mem_prc                                                            ; --! Memory for data squid proc.: memory interface
         o_mem_prc_data       : out    t_mem_prc_dta                                                        ; --! Memory for data squid proc.: data read

         i_init_fbk_pixel_pos : in     std_logic_vector(c_MUX_FACT_S-1 downto 0)                            ; --! Initialization feedback chain accumulators Pixel position
         i_init_fbk_acc       : in     std_logic                                                            ; --! Initialization feedback chain accumulators ('0' = Inactive, '1' = Active)

         i_rl_ena             : in     std_logic                                                            ; --! Relock enable ('0' = No, '1' = Yes)
         i_sqm_fbk_smfb0      : in     std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                      ; --! SQUID MUX feedback value in open loop (signed)
         o_smfbm_close_rl     : out    std_logic                                                            ; --! SQUID MUX feedback close mode for relock ('0' = No close , '1' = Close)
         o_smfb0_rl           : out    std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                      ; --! SQUID MUX feedback value in open loop for relock (signed)
         o_mem_rl_rd_add      : out    std_logic_vector(      c_MUX_FACT_S-1 downto 0)                      ; --! Relock memories read address

         i_sqm_data_err       : in     std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                        ; --! SQUID MUX Data error
         i_sqm_data_err_frst  : in     std_logic                                                            ; --! SQUID MUX Data error first pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_last  : in     std_logic                                                            ; --! SQUID MUX Data error last pixel ('0' = No, '1' = Yes)
         i_sqm_data_err_rdy   : in     std_logic                                                            ; --! SQUID MUX Data error ready ('0' = Not ready, '1' = Ready)

         o_sqm_data_sc_msb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID MUX Data science MSB
         o_sqm_data_sc_lsb    : out    std_logic_vector(c_SC_DATA_SER_W_S-1 downto 0)                       ; --! SQUID MUX Data science LSB
         o_sqm_data_sc_first  : out    std_logic                                                            ; --! SQUID MUX Data science first pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_last   : out    std_logic                                                            ; --! SQUID MUX Data science last pixel ('0' = No, '1' = Yes)
         o_sqm_data_sc_rdy    : out    std_logic                                                            ; --! SQUID MUX Data science ready ('0' = Not ready, '1' = Ready)

         o_sqm_dta_pixel_pos  : out    std_logic_vector(    c_MUX_FACT_S-1 downto 0)                        ; --! SQUID MUX Data error corrected pixel position
         o_sqm_dta_err_cor    : out    std_logic_vector(c_SQM_DATA_FBK_S-1 downto 0)                        ; --! SQUID MUX Data error corrected (signed)
         o_sqm_dta_err_cor_cs : out    std_logic                                                              --! SQUID MUX Data error corrected chip select ('0' = Inactive, '1' = Active)
   );
end entity squid_data_proc;

architecture RTL of squid_data_proc is
constant c_MEM_ACC_WR_NPER    : integer := 2                                                                ; --! Clock period number for getting data to write in add/acc mem. from data to acc. ready
constant c_MEM_ELN_RD_NPER    : integer := 1                                                                ; --! Clock period number for reading data in add/acc memory from data element n ready
constant c_MEM_PAR_NPER       : integer := c_MEM_RD_DATA_NPER + 1                                           ; --! Clock period number for getting parameter in memory from memory address update
constant c_ADC_SMP_AVE_NPER   : integer := c_DSP_NPER + 1                                                   ; --! Clock period number for ADC sample average from SQUID MUX Data error ready
constant c_ERR_SIG_NPER       : integer := c_ADC_SMP_AVE_NPER + 1                                           ; --! Clock period number for Error signal from SQUID MUX Data error ready
constant c_DIF_E_PN_NPER      : integer := c_ADC_SMP_AVE_NPER + 1                                           ; --! Clock period number for E(p,n) - Elp(p)    from SQUID MUX Data error ready
constant c_M_PN_NPER          : integer := c_DIF_E_PN_NPER + c_DSP_NPER + 1                                 ; --! Clock period number for M(p,n)             from SQUID MUX Data error ready
constant c_PC1_PN_NPER        : integer := c_M_PN_NPER + c_DSP_NPER + 1                                     ; --! Clock period number for PC1(p,n)           from SQUID MUX Data error ready
constant c_FB_PNP1_NPER       : integer := c_PC1_PN_NPER + c_MEM_ACC_WR_NPER + 1                            ; --! Clock period number for FB(p,n+1)          from SQUID MUX Data error ready
constant c_NRM_PN_NPER        : integer := c_DIF_E_PN_NPER + c_DSP_NPER + 1                                 ; --! Clock period number for NRM(p,n)           from SQUID MUX Data error ready
constant c_SC_PN_NPER         : integer := c_NRM_PN_NPER + 2                                                ; --! Clock period number for SC(p,n)            from SQUID MUX Data error ready

constant c_TOT_NPER           : integer := c_FB_PNP1_NPER                                                   ; --! Clock period number for M(p,n)             from SQUID MUX Data error ready

constant c_ELP_P_RDY_POS      : integer := c_ADC_SMP_AVE_NPER - c_MEM_PAR_NPER - 1                          ; --! Ready position: parameters Elp(p)
constant c_KIKNM_P_RDY_POS    : integer := c_DIF_E_PN_NPER    - c_MEM_PAR_NPER - 1                          ; --! Ready position: parameters ki(p)*knorm(p)
constant c_KNORM_P_RDY_POS    : integer := c_KIKNM_P_RDY_POS                                                ; --! Ready position: parameters knorm(p)
constant c_A_P_RDY_POS        : integer := c_M_PN_NPER        - c_MEM_PAR_NPER - 1                          ; --! Ready position: parameters a(p)
constant c_DFB_PN_RDY_POS     : integer := c_M_PN_NPER        - c_MEM_RD_DATA_NPER - c_MEM_ELN_RD_NPER      ; --! Ready position: dFB(p,n)
constant c_INI_DFB_PN_RDY_POS : integer := c_DFB_PN_RDY_POS   - 1                                           ; --! Ready position: Initialization dFB(p,n)
constant c_M_PN_RDY_POS       : integer := c_M_PN_NPER - 1                                                  ; --! Ready position: M(p,n)
constant c_PC1_PN_RDY_POS     : integer := c_PC1_PN_NPER - 1                                                ; --! Ready position: PC1(p,n)
constant c_FB_PN_RDY_POS      : integer := c_NRM_PN_NPER      - c_MEM_RD_DATA_NPER - c_MEM_ELN_RD_NPER      ; --! Ready position: FB(p,n)
constant c_FB_PNP1_RDY_POS    : integer := c_FB_PNP1_NPER  - 1                                              ; --! Ready position: FB(p,n+1)
constant c_INI_FB_PN_RDY_POS  : integer := c_FB_PN_RDY_POS - 1                                              ; --! Ready position: Initialization FB(p,n)
constant c_SC_PN_RDY_POS      : integer := c_SC_PN_NPER - 1                                                 ; --! Ready position: SC(p,n)

constant c_PIXEL_POS_MAX_VAL  : integer := c_MUX_FACT - 1                                                   ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer := log2_ceil(c_PIXEL_POS_MAX_VAL+1)                                 ; --! Pixel position: size bus

constant c_DFB_PN_INIT_VAL_V  : std_logic_vector(c_DFB_PN_S-1 downto 0):=
                                std_logic_vector(to_signed(c_DFB_PN_INIT_VAL, c_DFB_PN_S))                  ; --! dFB(p,n): initialization value vetor

signal   sqm_data_err_frst_r  : std_logic_vector(c_TOT_NPER-1 downto 0)                                     ; --! SQUID MUX Data science first pixel register
signal   sqm_data_err_last_r  : std_logic_vector(c_TOT_NPER-1 downto 0)                                     ; --! SQUID MUX Data science last pixel register
signal   sqm_data_err_rdy_r   : std_logic_vector(c_TOT_NPER-1 downto 0)                                     ; --! SQUID MUX Data science ready register

signal   pixel_pos            : std_logic_vector(            c_PIXEL_POS_S-1 downto 0)                      ; --! Pixel position
signal   pixel_pos_r          : t_slv_arr(0 to c_TOT_NPER-1)(c_PIXEL_POS_S-1 downto 0)                      ; --! Pixel position register

signal   mem_parma_pp         : std_logic                                                                   ; --! Parameter a(p), TH/HK side: ping-pong buffer bit
signal   mem_parma_prm        : t_mem(
                                add(              c_MEM_PARMA_ADD_S-1 downto 0),
                                data_w(          c_DFLD_PARMA_PIX_S-1 downto 0))                            ; --! Parameter a(p), getting parameter side: memory inputs

signal   mem_kiknm_pp         : std_logic                                                                   ; --! Parameter ki(p)*knorm(p), TH/HK side: ping-pong buffer bit
signal   mem_kiknm_prm        : t_mem(
                                add(              c_MEM_KIKNM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KIKNM_PIX_S-1 downto 0))                            ; --! Parameter ki(p)*knorm(p), getting parameter side: memory inputs

signal   mem_knorm_pp         : std_logic                                                                   ; --! Parameter knorm(p), TH/HK side: ping-pong buffer bit
signal   mem_knorm_prm        : t_mem(
                                add(              c_MEM_KNORM_ADD_S-1 downto 0),
                                data_w(          c_DFLD_KNORM_PIX_S-1 downto 0))                            ; --! Parameter knorm(p), getting parameter side: memory inputs

signal   mem_smlkv_pp         : std_logic                                                                   ; --! Parameter elp(p), TH/HK side: ping-pong buffer bit
signal   mem_smlkv_prm        : t_mem(
                                add(              c_MEM_SMLKV_ADD_S-1 downto 0),
                                data_w(          c_DFLD_SMLKV_PIX_S-1 downto 0))                            ; --! Parameter elp(p), getting parameter side: memory inputs

signal   a_p                  : std_logic_vector(c_DFLD_PARMA_PIX_S-1 downto 0)                             ; --! Parameters a(p)
signal   ki_knorm_p           : std_logic_vector(c_DFLD_KIKNM_PIX_S-1 downto 0)                             ; --! Parameters ki(p)*knorm(p)
signal   knorm_p              : std_logic_vector(c_DFLD_KNORM_PIX_S-1 downto 0)                             ; --! Parameters knorm(p)
signal   elp_p                : std_logic_vector(c_DFLD_SMLKV_PIX_S-1 downto 0)                             ; --! Parameters Elp(p)

signal   a_p_aln              : std_logic_vector(c_DFLD_PARMA_PIX_S   downto 0)                             ; --! Parameters a(p)
signal   ki_knorm_p_aln       : std_logic_vector(c_DFLD_KIKNM_PIX_S   downto 0)                             ; --! Parameters ki(p)*knorm(p)
signal   knorm_p_aln          : std_logic_vector(c_DFLD_KNORM_PIX_S   downto 0)                             ; --! Parameters knorm(p)
signal   elp_p_aln            : std_logic_vector(c_ADC_SMP_AVE_S-1    downto 0)                             ; --! Parameters Elp(p) aligned on E(p,n) bus size

signal   mem_init_fbk_acc_dfb : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(0 downto 0)                               ; --! Memory initialization feedback chain accumulators dFB(p,n)
signal   mem_init_fbk_acc_fb  : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(0 downto 0)                               ; --! Memory initialization feedback chain accumulators FB(p,n)
signal   mem_smfb0_rl         : t_slv_arr(0 to 2**c_MUX_FACT_S-1)(c_DFLD_SMFB0_PIX_S-1 downto 0)            ; --! Memory SQUID MUX feedback value in open loop for relock (signed)

signal   init_fbk_acc_dfb     : std_logic                                                                   ; --! Initialization feedback chain accumulators dFB(p,n)
signal   init_fbk_acc_fb      : std_logic                                                                   ; --! Initialization feedback chain accumulators FB(p,n)
signal   smfb0                : std_logic_vector(c_DFLD_SMFB0_PIX_S-1 downto 0)                             ; --! SQUID MUX feedback value in open loop (signed)
signal   smfb0_rl_rs          : std_logic_vector(c_FB_PN_S-1 downto 0)                                      ; --! SQUID MUX feedback value in open loop for relock resize

signal   sqm_adc_ena          : std_logic                                                                   ; --! ADC enable ('0'= No, '1'= Yes)
signal   aqmde_sync           : std_logic_vector(c_DFLD_AQMDE_S-1 downto 0)                                 ; --! Telemetry mode, sync. on first pixel
signal   bxlgt_sync           : std_logic_vector(c_DFLD_BXLGT_COL_S-1 downto 0)                             ; --! ADC sample number for averaging, sync. on first pixel

signal   sqm_data_err         : std_logic_vector(c_SQM_DATA_ERR_S-1 downto 0)                               ; --! SQUID MUX Data error

signal   adc_smp_ave_coef     : std_logic_vector(c_ASP_CF_S   downto 0)                                     ; --! ADC sample number for averaging coefficient (unsigned)
signal   adc_smp_ave          : std_logic_vector(c_ADC_SMP_AVE_C_S-1 downto 0)                              ; --! ADC sample average (unsigned)
signal   adc_smp_ave_sc       : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S+1 downto 0)             ; --! ADC sample average for data science (unsigned)
signal   err_sig              : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S   downto 0)             ; --! Error signal (unsigned)
signal   err_sig_r            : t_slv_arr(0 to c_SC_PN_NPER-c_ERR_SIG_NPER-2)
                                         (c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)                    ; --! Error signal register (unsigned)

signal   dfb_mem_acc_add      : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! dFB(p,n): Memory accumulator address
signal   dfb_data_acc_rdy     : std_logic                                                                   ; --! dFB(p,n): Data to accumulate ready ('0' = Not ready, '1' = Ready)
signal   dfb_data_eln_rdy     : std_logic                                                                   ; --! dFB(p,n): Data element n ready     ('0' = Not ready, '1' = Ready)

signal   fb_mem_acc_add       : std_logic_vector(c_PIXEL_POS_S-1 downto 0)                                  ; --! FB(p,n): Memory accumulator address
signal   fb_data_acc_rdy      : std_logic                                                                   ; --! FB(p,n): Data to accumulate ready ('0' = Not ready, '1' = Ready)
signal   fb_data_eln_rdy      : std_logic                                                                   ; --! FB(p,n): Data element n ready     ('0' = Not ready, '1' = Ready)

signal   e_pn_minus_elp_p     : std_logic_vector(c_ADC_SMP_AVE_S   downto 0)                                ; --! Result: E(p,n) - Elp(p)
signal   m_pn                 : std_logic_vector(c_M_PN_C_S-1      downto 0)                                ; --! Result: M(p,n) = ki(p)*knorm(p)*(E(p,n) - Elp(p))
signal   m_pn_car_dfb_pn      : std_logic_vector(c_DFB_PN_DACC_S   downto 0)                                ; --! M(p,n) with carry for dFB(p,n+1) calculation
signal   m_pn_rnd_sat_dfb_pn  : std_logic_vector(c_DFB_PN_DACC_S-1 downto 0)                                ; --! M(p,n) round with saturation for dFB(p,n+1) calculation
signal   m_pn_rnd_sat_pc1_pn  : std_logic_vector(c_M_PN_S-1        downto 0)                                ; --! M(p,n) round with saturation for PC1(p,n) calculation
signal   dfb_pn               : std_logic_vector(c_DFB_PN_S-1      downto 0)                                ; --! Result: dFB(p,n) = M(p,n-1) + dFB(p,n-1)
signal   pc1_pn               : std_logic_vector(c_PC1_PN_C_S-1    downto 0)                                ; --! Result: PC1(p,n) = M(p,n) + a(p) * dFB(p,n)
signal   pc1_pn_rnd_sat_fb_pn : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! PC1(p,n) round with saturation for FB(p,n+1) calculation
signal   fb_pn                : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! Result: FB(p,n)
signal   fb_pnp1              : std_logic_vector(c_FB_PN_S-1       downto 0)                                ; --! Result: FB(p,n+1) = FB(p,n) + M(p,n) + a(p) * dFB(p,n)
signal   fb_pnp1_car          : std_logic_vector(c_SQM_DATA_FBK_S  downto 0)                                ; --! FB(p,n+1) with carry
signal   nrm_pn               : std_logic_vector(c_NRM_PN_C_S-1    downto 0)                                ; --! Result: NRM(p,n) = knorm(p)*(E(p,n) - Elp(p))
signal   nrm_pn_rnd_sat       : std_logic_vector(c_NRM_PN_S-1      downto 0)                                ; --! NRM(p,n) round with saturation
signal   sc_pn                : std_logic_vector(c_NRM_PN_S-1      downto 0)                                ; --! Result: SC(p,n) = knorm(p)*(E(p,n) - Elp(p)) + FB(p,n)
signal   sc_pn_car            : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S   downto 0)             ; --! SC(p,n) with carry

signal   sqm_data_sc          : std_logic_vector(c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1 downto 0)             ; --! SQUID MUX Data science

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Signal registered
   -- ------------------------------------------------------------------------------------------------------
   P_sig_r : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_err_frst_r  <= (others => '0');
         sqm_data_err_last_r  <= (others => '0');
         sqm_data_err_rdy_r   <= (others => '0');
         pixel_pos_r          <= (others => (others => '0'));
         err_sig_r            <= (others => (others => '0'));

      elsif rising_edge(i_clk) then
         sqm_data_err_frst_r  <= sqm_data_err_frst_r(sqm_data_err_frst_r'high-1 downto 0) & i_sqm_data_err_frst;
         sqm_data_err_last_r  <= sqm_data_err_last_r(sqm_data_err_last_r'high-1 downto 0) & i_sqm_data_err_last;
         sqm_data_err_rdy_r   <= sqm_data_err_rdy_r( sqm_data_err_rdy_r'high-1  downto 0) & i_sqm_data_err_rdy;
         pixel_pos_r          <= pixel_pos & pixel_pos_r(0 to pixel_pos_r'high-1);
         err_sig_r            <= err_sig(err_sig'high-1 downto 0) & err_sig_r(0 to err_sig_r'high-1);

      end if;

   end process P_sig_r;

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel position
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_pos : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         pixel_pos   <= (others => '0');

      elsif rising_edge(i_clk) then
         if i_sqm_data_err_rdy = '1' then
            if i_sqm_data_err_frst = '1' then
               pixel_pos <= (others => '0');

            elsif pixel_pos < std_logic_vector(to_unsigned(c_PIXEL_POS_MAX_VAL, pixel_pos'length)) then
               pixel_pos <= std_logic_vector(unsigned(pixel_pos) + 1);

            end if;

         end if;

      end if;

   end process P_pixel_pos;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory for parameters a(p)
   --    @Req : DRE-DMX-FW-REQ-0180
   --    @Req : REG_CY_A
   -- ------------------------------------------------------------------------------------------------------
   I_mem_parma_val: entity work.dmem_ecc generic map (
         g_RAM_TYPE           => c_RAM_TYPE_PRM_STORE , -- integer                                          ; --! Memory type ( 0  = Data transfer,  1  = Parameters storage)
         g_RAM_ADD_S          => c_MEM_PARMA_ADD_S    , -- integer                                          ; --! Memory address bus size (<= c_RAM_ECC_ADD_S)
         g_RAM_DATA_S         => c_DFLD_PARMA_PIX_S   , -- integer                                          ; --! Memory data bus size (<= c_RAM_DATA_S)
         g_RAM_INIT           => c_EP_CMD_DEF_PARMA     -- t_int_arr                                          --! Memory content at initialization
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

   a_p_aln <= std_logic_vector(resize(unsigned(a_p), a_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory a(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_parma_prm.add     <= pixel_pos_r(c_A_P_RDY_POS);
   mem_parma_prm.we      <= '0';
   mem_parma_prm.cs      <= '1';
   mem_parma_prm.data_w  <= (others => '0');

   P_mem_parma_pp : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_parma_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_rdy_r(c_A_P_RDY_POS) and sqm_data_err_frst_r(c_A_P_RDY_POS)) = '1' then
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
         g_RAM_INIT           => c_EP_CMD_DEF_KIKNM     -- t_int_arr                                          --! Memory content at initialization
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

   ki_knorm_p_aln <= std_logic_vector(resize(unsigned(ki_knorm_p), ki_knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory ki(p)*knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_kiknm_prm.add     <= pixel_pos_r(c_KIKNM_P_RDY_POS);
   mem_kiknm_prm.we      <= '0';
   mem_kiknm_prm.cs      <= '1';
   mem_kiknm_prm.data_w  <= (others => '0');

   P_mem_kiknm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_kiknm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_rdy_r(c_KIKNM_P_RDY_POS) and sqm_data_err_frst_r(c_KIKNM_P_RDY_POS)) = '1' then
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
         g_RAM_INIT           => c_EP_CMD_DEF_KNORM     -- t_int_arr                                          --! Memory content at initialization
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

   knorm_p_aln <= std_logic_vector(resize(unsigned(knorm_p), knorm_p_aln'length));

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory knorm(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_knorm_prm.add     <= pixel_pos_r(c_KNORM_P_RDY_POS);
   mem_knorm_prm.we      <= '0';
   mem_knorm_prm.cs      <= '1';
   mem_knorm_prm.data_w  <= (others => '0');

   P_mem_knorm_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_knorm_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_rdy_r(c_KNORM_P_RDY_POS) and sqm_data_err_frst_r(c_KNORM_P_RDY_POS)) = '1' then
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
         g_RAM_INIT           => c_EP_CMD_DEF_SMLKV     -- t_int_arr                                          --! Memory content at initialization
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

   elp_p_aln(elp_p_aln'high)                                                         <= '0';
   elp_p_aln(elp_p_aln'high-1                downto elp_p_aln'length-elp_p'length-1) <= elp_p;
   elp_p_aln(elp_p_aln'length-elp_p'length-2 downto                               0) <= (others => '0');

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory Elp(p): memory signals management
   --!      (Getting parameter side)
   -- ------------------------------------------------------------------------------------------------------
   mem_smlkv_prm.add     <= pixel_pos_r(c_ELP_P_RDY_POS);
   mem_smlkv_prm.we      <= '0';
   mem_smlkv_prm.cs      <= '1';
   mem_smlkv_prm.data_w  <= (others => '0');

   P_mem_smlkv_prm_pp : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         mem_smlkv_prm.pp      <= c_MEM_STR_ADD_PP_DEF;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_rdy_r(c_ELP_P_RDY_POS) and sqm_data_err_frst_r(c_ELP_P_RDY_POS)) = '1' then
            mem_smlkv_prm.pp   <= mem_smlkv_pp;

         end if;

      end if;

   end process P_mem_smlkv_prm_pp;

   -- ------------------------------------------------------------------------------------------------------
   --!   Dual port memory initialization feedback chain accumulators and
   --!    SQUID MUX feedback value in open loop for relock
   -- ------------------------------------------------------------------------------------------------------
   P_init_fbk_acc_wr : process (i_clk)
   begin

      if rising_edge(i_clk) then
         mem_init_fbk_acc_dfb(to_integer(unsigned(i_init_fbk_pixel_pos)))(0) <= i_init_fbk_acc;
         mem_init_fbk_acc_fb( to_integer(unsigned(i_init_fbk_pixel_pos)))(0) <= i_init_fbk_acc;
         mem_smfb0_rl(to_integer(unsigned(i_init_fbk_pixel_pos)))            <= i_sqm_fbk_smfb0;

      end if;

   end process P_init_fbk_acc_wr;

   P_init_fbk_acc_rd : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         init_fbk_acc_dfb <= '1';
         init_fbk_acc_fb  <= '1';
         smfb0            <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_SMFB0(0), smfb0'length));
         o_smfb0_rl       <= std_logic_vector(to_unsigned(c_EP_CMD_DEF_SMFB0(0), o_smfb0_rl'length));

      elsif rising_edge(i_clk) then
         init_fbk_acc_dfb <= mem_init_fbk_acc_dfb(to_integer(unsigned(pixel_pos_r(c_INI_DFB_PN_RDY_POS))))(0);
         init_fbk_acc_fb  <= mem_init_fbk_acc_fb( to_integer(unsigned(pixel_pos_r(c_INI_FB_PN_RDY_POS ))))(0);
         smfb0            <= mem_smfb0_rl(        to_integer(unsigned(pixel_pos_r(c_FB_PN_RDY_POS))));

         if sqm_data_err_rdy_r(c_FB_PNP1_RDY_POS-1) = '1' then
            o_smfb0_rl    <= smfb0;

         end if;

      end if;

   end process P_init_fbk_acc_rd;

   I_smfb0_rl_rs : entity work.resize_stall_msb generic map (
         g_DATA_S             => c_DFLD_SMFB0_PIX_S   , -- integer                                          ; --! Data input bus size
         g_DATA_STALL_MSB_S   => c_FB_PN_S              -- integer                                            --! Data stalled on Mean Significant Bit bus size
   ) port map (
         i_data               => smfb0                , -- in     slv(          g_DATA_S-1 downto 0)        ; --! Data
         o_data_stall_msb     => smfb0_rl_rs            -- out    slv(g_DATA_STALL_MSB_S-1 downto 0)          --! Data stalled on Mean Significant Bit
   );

   o_smfbm_close_rl  <= not(init_fbk_acc_fb);
   o_mem_rl_rd_add   <= pixel_pos_r(c_FB_PN_RDY_POS-1);

   -- ------------------------------------------------------------------------------------------------------
   --!   Registers sync. on first pixel
   -- ------------------------------------------------------------------------------------------------------
   P_reg_sync : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_adc_ena <= '0';
         aqmde_sync  <= c_EP_CMD_DEF_AQMDE;
         bxlgt_sync  <= c_EP_CMD_DEF_BXLGT;

      elsif rising_edge(i_clk) then
         if (sqm_data_err_frst_r(c_SC_PN_RDY_POS-2) and sqm_data_err_rdy_r(c_SC_PN_RDY_POS-2)) = '1' then
            aqmde_sync <= i_aqmde;

         end if;

         if (i_sqm_data_err_frst and i_sqm_data_err_rdy) = '1' then

            if (i_aqmde = c_DST_AQMDE_DUMP or i_aqmde = c_DST_AQMDE_SCIE or i_aqmde = c_DST_AQMDE_ERRS or i_smfmd = c_DST_SMFMD_ON) and (i_sqm_adc_pwdn = '0') then
               sqm_adc_ena <= '1';

            else
               sqm_adc_ena <= '0';

            end if;

         end if;

         if sqm_adc_ena = '0' then
            bxlgt_sync <= c_EP_CMD_DEF_BXLGT;

         elsif (i_sqm_data_err_frst and i_sqm_data_err_rdy) = '1' then
            bxlgt_sync <= i_bxlgt;

         end if;

      end if;

   end process P_reg_sync;

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data error
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_err : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sqm_data_err <= std_logic_vector(resize(signed(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

      elsif rising_edge(i_clk) then
         if sqm_adc_ena = '1' then
            sqm_data_err <= std_logic_vector(resize(signed(i_sqm_data_err), sqm_data_err'length));

         else
            sqm_data_err <= std_logic_vector(resize(signed(c_I_SQM_ADC_DATA_DEF), sqm_data_err'length));

         end if;

      end if;

   end process P_sqm_data_err;

   -- ------------------------------------------------------------------------------------------------------
   --!   Get ADC sample number for averaging coefficient from table
   --    @Req : DRE-DMX-FW-REQ-0145
   -- ------------------------------------------------------------------------------------------------------
   P_adc_smp_ave_coef : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         adc_smp_ave_coef <= std_logic_vector(resize(unsigned(c_ADC_SMP_AVE_TAB(to_integer(unsigned(c_EP_CMD_DEF_BXLGT)))), adc_smp_ave_coef'length));

      elsif rising_edge(i_clk) then
         adc_smp_ave_coef <= std_logic_vector(resize(unsigned(c_ADC_SMP_AVE_TAB(to_integer(unsigned(bxlgt_sync)))), adc_smp_ave_coef'length));

      end if;

   end process P_adc_smp_ave_coef;

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average, E(p,n)
   --    @Req : DRE-DMX-FW-REQ-0140
   -- ------------------------------------------------------------------------------------------------------
   I_adc_smp_ave: entity work.dsp generic map (
         g_PORTA_S            => c_ASP_CF_S+1         , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_SQM_DATA_ERR_S     , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_ADC_SMP_AVE_C_S    , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_ADC_SMP_AVE_LSB    , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_ADC_SMP_AVE_SAT    , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => adc_smp_ave_coef     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => sqm_data_err         , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => (others => '0')      , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => adc_smp_ave          , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: E(p,n) - Elp(p) (E(p,n) rounded)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   P_e_pn_minus_elp_p : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         e_pn_minus_elp_p <= (others => '0');

      elsif rising_edge(i_clk) then
         e_pn_minus_elp_p <= std_logic_vector(       resize(  signed(adc_smp_ave(adc_smp_ave'high downto 1)), e_pn_minus_elp_p'length)  +
                                              signed(resize(unsigned(adc_smp_ave(0                downto 0)), e_pn_minus_elp_p'length)) -
                                              signed(resize(unsigned(elp_p_aln                             ), e_pn_minus_elp_p'length)));
      end if;

   end process P_e_pn_minus_elp_p;

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: M(p,n) = ki(p)*knorm(p)*(E(p,n) - Elp(p))
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   I_m_pn: entity work.dsp generic map (
         g_PORTA_S            => c_ADC_SMP_AVE_S+1    , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_KIKNM_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_DFLD_KIKNM_PIX_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_M_PN_C_S           , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_M_PN_LSB           , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_M_PN_SAT           , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => e_pn_minus_elp_p     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => ki_knorm_p_aln       , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => (others => '0')      , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => m_pn                 , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   m_pn_car_dfb_pn <= m_pn(m_pn'high downto m_pn'length-m_pn_car_dfb_pn'length);

   I_m_pn_rd_sat_dfb_pn: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_DFB_PN_DACC_S+1      -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => m_pn_car_dfb_pn      , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => m_pn_rnd_sat_dfb_pn    -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   I_m_pn_rd_sat_pc1_pn: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_M_PN_C_S             -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => m_pn                 , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => m_pn_rnd_sat_pc1_pn    -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Adder with accumulator: dFB(p,n+1) = M(p,n) + dFB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   dfb_mem_acc_add   <= pixel_pos_r(       c_DFB_PN_RDY_POS);
   dfb_data_eln_rdy  <= sqm_data_err_rdy_r(c_DFB_PN_RDY_POS);
   dfb_data_acc_rdy  <= sqm_data_err_rdy_r(c_M_PN_RDY_POS);

   I_dfb_pn: entity work.adder_acc generic map (
         g_DATA_ACC_S         => c_DFB_PN_DACC_S      , -- integer                                          ; --! Data to accumulate bus size
         g_DATA_ELN_S         => c_DFB_PN_S           , -- integer                                          ; --! Data element n bus size (>= g_DATA_ACC_S)
         g_MEM_ACC_NW         => c_MUX_FACT           , -- integer                                          ; --! Memory accumulator number word
         g_MEM_ACC_INIT_VAL   => c_DFB_PN_INIT_VAL      -- integer                                            --! Memory accumulator initialization value
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_mem_acc_add        => dfb_mem_acc_add      , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address
         i_mem_acc_init_ena   => init_fbk_acc_dfb     , -- in     std_logic                                 ; --! Memory accumulator initialization enable ('0' = No, '1' = Yes)
         i_mem_acc_rl_val     => c_DFB_PN_INIT_VAL_V  , -- in     std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Memory accumulator relock value (signed)
         i_rl_ena             => i_rl_ena             , -- in     std_logic                                 ; --! Relock enable ('0' = No, '1' = Yes)
         i_data_acc           => m_pn_rnd_sat_dfb_pn  , -- in     std_logic_vector(g_DATA_ACC_S-1 downto 0) ; --! Data to accumulate (signed)
         i_data_acc_rdy       => dfb_data_acc_rdy     , -- in     std_logic                                 ; --! Data to accumulate ready ('0' = Not ready, '1' = Ready)
         i_data_eln_rdy       => dfb_data_eln_rdy     , -- in     std_logic                                 ; --! Data element n ready     ('0' = Not ready, '1' = Ready)
         o_data_elnp1         => open                 , -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Data element n+1 (signed)
         o_data_eln           => dfb_pn                 -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0)   --! Data element n   (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: PC1(p,n) = M(p,n) + a(p) * dFB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0160
   -- ------------------------------------------------------------------------------------------------------
   I_pc1_pn: entity work.dsp generic map (
         g_PORTA_S            => c_DFB_PN_S           , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_PARMA_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_M_PN_S             , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_PC1_PN_C_S         , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_PC1_PN_LSB         , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_PC1_PN_SAT         , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => dfb_pn               , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => a_p_aln              , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => m_pn_rnd_sat_pc1_pn  , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => pc1_pn               , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_pc1_pn_rd_st_fb_pn: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_PC1_PN_C_S           -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => pc1_pn               , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => pc1_pn_rnd_sat_fb_pn   -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Adder with accumulator: FB(p,n+1) = FB(p,n) + M(p,n) + a(p) * dFB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0160
   --    @Req : DRE-DMX-FW-REQ-0400
   -- ------------------------------------------------------------------------------------------------------
   fb_mem_acc_add    <= pixel_pos_r(       c_FB_PN_RDY_POS);
   fb_data_eln_rdy   <= sqm_data_err_rdy_r(c_FB_PN_RDY_POS);
   fb_data_acc_rdy   <= sqm_data_err_rdy_r(c_PC1_PN_RDY_POS);

   I_fb_pn: entity work.adder_acc generic map (
         g_DATA_ACC_S         => c_FB_PN_S            , -- integer                                          ; --! Data to accumulate bus size
         g_DATA_ELN_S         => c_FB_PN_S            , -- integer                                          ; --! Data element n bus size (>= g_DATA_ACC_S)
         g_MEM_ACC_NW         => c_MUX_FACT           , -- integer                                          ; --! Memory accumulator number word
         g_MEM_ACC_INIT_VAL   => c_FB_PN_INIT_VAL       -- integer                                            --! Memory accumulator initialization value
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_mem_acc_add        => fb_mem_acc_add       , -- in     slv(log2_ceil(g_MEM_ACC_NW)-1 downto 0)   ; --! Memory accumulator address
         i_mem_acc_init_ena   => init_fbk_acc_fb      , -- in     std_logic                                 ; --! Memory accumulator initialization enable ('0' = No, '1' = Yes)
         i_mem_acc_rl_val     => smfb0_rl_rs          , -- in     std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Memory accumulator relock value (signed)
         i_rl_ena             => i_rl_ena             , -- in     std_logic                                 ; --! Relock enable ('0' = No, '1' = Yes)
         i_data_acc           => pc1_pn_rnd_sat_fb_pn , -- in     std_logic_vector(g_DATA_ACC_S-1 downto 0) ; --! Data to accumulate (signed)
         i_data_acc_rdy       => fb_data_acc_rdy      , -- in     std_logic                                 ; --! Data to accumulate ready ('0' = Not ready, '1' = Ready)
         i_data_eln_rdy       => fb_data_eln_rdy      , -- in     std_logic                                 ; --! Data element n ready     ('0' = Not ready, '1' = Ready)
         o_data_elnp1         => fb_pnp1              , -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0) ; --! Data element n+1 (signed)
         o_data_eln           => fb_pn                  -- out    std_logic_vector(g_DATA_ELN_S-1 downto 0)   --! Data element n   (signed)
   );

   fb_pnp1_car    <= fb_pnp1(fb_pnp1'high downto fb_pnp1'length-fb_pnp1_car'length);

   I_sqm_dta_err_cor: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_SQM_DATA_FBK_S+1     -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => fb_pnp1_car          , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => o_sqm_dta_err_cor      -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   o_sqm_dta_pixel_pos  <= pixel_pos_r(c_FB_PNP1_RDY_POS-1);
   o_sqm_dta_err_cor_cs <= sqm_data_err_rdy_r(c_FB_PNP1_RDY_POS);

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: NRM(p,n) = knorm(p)*(E(p,n) - Elp(p))
   --    @Req : DRE-DMX-FW-REQ-0390
   -- ------------------------------------------------------------------------------------------------------
   I_nrm_pn: entity work.dsp generic map (
         g_PORTA_S            => c_ADC_SMP_AVE_S+1    , -- integer                                          ; --! Port A bus size (<= c_MULT_ALU_PORTA_S)
         g_PORTB_S            => c_DFLD_KNORM_PIX_S+1 , -- integer                                          ; --! Port B bus size (<= c_MULT_ALU_PORTB_S)
         g_PORTC_S            => c_DFLD_KNORM_PIX_S   , -- integer                                          ; --! Port C bus size (<= c_MULT_ALU_PORTC_S)
         g_RESULT_S           => c_NRM_PN_C_S         , -- integer                                          ; --! Result bus size (<= c_MULT_ALU_RESULT_S)
         g_RESULT_LSB_POS     => c_NRM_PN_LSB         , -- integer                                          ; --! Result LSB position

         g_DATA_TYPE          => c_MULT_ALU_SIGNED    , -- bit                                              ; --! Data type               ('0' = unsigned,           '1' = signed)
         g_SAT_RANK           => c_NRM_PN_SAT         , -- integer                                          ; --! Extrem values reached on result bus
                                                                                                              --!   unsigned: range from               0  to 2**(g_SAT_RANK+1) - 1
                                                                                                              --!     signed: range from -2**(g_SAT_RANK) to 2**(g_SAT_RANK)   - 1
         g_PRE_ADDER_OP       => '0'                  , -- bit                                              ; --! Pre-Adder operation     ('0' = add,    '1' = subtract)
         g_MUX_C_CZ           => '0'                    -- bit                                                --! Multiplexer ALU operand ('0' = Port C, '1' = Cascaded Result Input)
   ) port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock

         i_carry              => '0'                  , -- in     std_logic                                 ; --! Carry In
         i_a                  => e_pn_minus_elp_p     , -- in     std_logic_vector( g_PORTA_S-1 downto 0)   ; --! Port A
         i_b                  => knorm_p_aln          , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port B
         i_c                  => (others => '0')      , -- in     std_logic_vector( g_PORTC_S-1 downto 0)   ; --! Port C
         i_d                  => (others => '0')      , -- in     std_logic_vector( g_PORTB_S-1 downto 0)   ; --! Port D
         i_cz                 => (others => '0')      , -- in     slv(c_MULT_ALU_RESULT_S-1 downto 0)       ; --! Cascaded Result Input

         o_z                  => nrm_pn               , -- out    std_logic_vector(g_RESULT_S-1 downto 0)   ; --! Result
         o_cz                 => open                   -- out    slv(c_MULT_ALU_RESULT_S-1 downto 0)         --! Cascaded Result
   );

   I_nrm_pn_rnd_sat: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_NRM_PN_C_S           -- integer                                            --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => nrm_pn               , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => nrm_pn_rnd_sat         -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Result: SC(p,n) = knorm(p)*(E(p,n) - Elp(p)) + FB(p,n)
   --    @Req : DRE-DMX-FW-REQ-0390
   -- ------------------------------------------------------------------------------------------------------
   I_sc_pn: entity work.adder_sat generic map (
         g_DATA_S             => c_NRM_PN_S             -- integer                                            --! Data bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_fst           => nrm_pn_rnd_sat       , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data first (signed)
         i_data_sec           => fb_pn                , -- in     std_logic_vector(g_DATA_S-1 downto 0)     ; --! Data second (signed)
         o_data_add_sat       => sc_pn                  -- out    std_logic_vector(g_DATA_S-1 downto 0)       --! Data added with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   Science telemetry (rounded with saturation operation)
   -- ------------------------------------------------------------------------------------------------------
   sc_pn_car <= sc_pn(sc_pn'high downto sc_pn'length-sc_pn_car'length);

   I_sqm_data_sc: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S+1 -- integer                              --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => sc_pn_car            , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => sqm_data_sc            -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   ADC sample average for science (rounded with saturation operation)
   -- ------------------------------------------------------------------------------------------------------
   adc_smp_ave_sc <= adc_smp_ave(adc_smp_ave'high) & adc_smp_ave(adc_smp_ave'high downto adc_smp_ave'length-c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S-1);

   I_adc_smp_ave_sc: entity work.round_sat generic map (
         g_DATA_CARRY_S       => c_SC_DATA_SER_NB*c_SC_DATA_SER_W_S+2 -- integer                              --! Data with carry bus size
   )  port map (
         i_rst                => i_rst                , -- in     std_logic                                 ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                => i_clk                , -- in     std_logic                                 ; --! Clock
         i_data_carry         => adc_smp_ave_sc       , -- in     slv(g_DATA_CARRY_S-1 downto 0)            ; --! Data with carry on lsb (signed)
         o_data_rnd_sat       => err_sig                -- out    slv(g_DATA_CARRY_S-2 downto 0)              --! Data rounded with saturation (signed)
   );

   -- ------------------------------------------------------------------------------------------------------
   --!   SQUID MUX Data science
   -- ------------------------------------------------------------------------------------------------------
   P_sqm_data_sc : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         o_sqm_data_sc_msb    <= (others => '0');
         o_sqm_data_sc_lsb    <= (others => '0');
         o_sqm_data_sc_first  <= '0';
         o_sqm_data_sc_last   <= '0';
         o_sqm_data_sc_rdy    <= '0';

      elsif rising_edge(i_clk) then
         if aqmde_sync = c_DST_AQMDE_ERRS then
            o_sqm_data_sc_msb    <= err_sig_r(err_sig_r'high)(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
            o_sqm_data_sc_lsb    <= err_sig_r(err_sig_r'high)(  c_SC_DATA_SER_W_S-1 downto 0);

         else
            o_sqm_data_sc_msb    <= sqm_data_sc(2*c_SC_DATA_SER_W_S-1 downto c_SC_DATA_SER_W_S);
            o_sqm_data_sc_lsb    <= sqm_data_sc(  c_SC_DATA_SER_W_S-1 downto 0);

         end if;

         o_sqm_data_sc_first  <= sqm_data_err_frst_r(c_SC_PN_RDY_POS);
         o_sqm_data_sc_last   <= sqm_data_err_last_r(c_SC_PN_RDY_POS);
         o_sqm_data_sc_rdy    <= sqm_data_err_rdy_r( c_SC_PN_RDY_POS);

      end if;

   end process P_sqm_data_sc;

end architecture RTL;
