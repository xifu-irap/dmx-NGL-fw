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
--!   @file                   dmx_cmd.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DEMUX commands
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.pkg_type.all;
use     work.pkg_func_math.all;
use     work.pkg_project.all;
use     work.pkg_ep_cmd.all;

entity dmx_cmd is port
   (     i_rst                : in     std_logic                                                            ; --! Reset asynchronous assertion, synchronous de-assertion ('0' = Inactive, '1' = Active)
         i_clk                : in     std_logic                                                            ; --! Clock

         i_sync_rs            : in     std_logic                                                            ; --! Pixel sequence synchronization, synchronized on System Clock

         i_tm_mode            : in     std_logic_vector(c_DFLD_TM_MODE_S-1 downto 0)                        ; --! Telemetry mode
         i_sq1_fb_mode        : in     t_slv_arr(0 to c_NB_COL-1)(c_DFLD_SQ1FBMD_COL_S-1 downto 0)          ; --! Squid 1 Feedback mode (on/off)

         o_sync_re            : out    std_logic                                                            ; --! Pixel sequence synchronization, rising edge

         o_cmd_ck_s1_adc_ena  : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_adc_dis  : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 ADC Clocks switch commands disable ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_dac_ena  : out    std_logic_vector(c_NB_COL-1 downto 0)                                ; --! SQUID1 DAC Clocks switch commands enable  ('0' = Inactive, '1' = Active)
         o_cmd_ck_s1_dac_dis  : out    std_logic_vector(c_NB_COL-1 downto 0)                                  --! SQUID1 DAC Clocks switch commands disable ('0' = Inactive, '1' = Active)
   );
end entity dmx_cmd;

architecture RTL of dmx_cmd is
constant c_CK_PLS_CNT_MAX_VAL : integer:= (c_PIXEL_ADC_NB_CYC * c_CLK_MULT / c_CLK_ADC_DAC_MULT) - 2        ; --! System clock pulse counter: maximal value
constant c_CK_PLS_CNT_S       : integer:= log2_ceil(c_CK_PLS_CNT_MAX_VAL+1)+1                               ; --! System clock pulse counter: size bus (signed)

constant c_PIXEL_POS_MAX_VAL  : integer:= c_MUX_FACT - 1                                                    ; --! Pixel position: maximal value
constant c_PIXEL_POS_S        : integer:= log2_ceil(c_PIXEL_POS_MAX_VAL+1)+1                                ; --! Pixel position: size bus (signed)

signal   sync_rs_r            : std_logic                                                                   ; --! Pixel sequence synchronization, synchronized on System Clock register
signal   sync_re              : std_logic                                                                   ; --! Pixel sequence synchronization, rising edge
signal   ck_pls_cnt           : std_logic_vector(c_CK_PLS_CNT_S-1 downto 0)                                 ; --! System clock pulse counter
signal   pixel_pos            : std_logic_vector( c_PIXEL_POS_S-1 downto 0)                                 ; --! Pixel position

signal   cmd_ck_sq1_adc_ena   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 ADC Clocks switch commands enable (for each column: '0'=Inactive, '1'=Active)
signal   cmd_ck_sq1_dac_ena   : std_logic_vector(c_NB_COL-1 downto 0)                                       ; --! SQUID1 DAC Clocks switch commands enable (for each column: '0'=Inactive, '1'=Active)

begin

   -- ------------------------------------------------------------------------------------------------------
   --!   Pixel sequence management
   --    @Req : DRE-DMX-FW-REQ-0080
   --    @Req : DRE-DMX-FW-REQ-0090
   --    @Req : DRE-DMX-FW-REQ-0130
   -- ------------------------------------------------------------------------------------------------------
   P_pixel_seq : process (i_rst, i_clk)
   begin

      if i_rst = '1' then
         sync_rs_r   <= c_I_SYNC_DEF;
         sync_re     <= '0';
         ck_pls_cnt  <= std_logic_vector(to_signed(c_CK_PLS_CNT_MAX_VAL, ck_pls_cnt'length));
         pixel_pos   <= (others => '1');

      elsif rising_edge(i_clk) then
         sync_rs_r   <= i_sync_rs;
         sync_re     <= not(sync_rs_r) and i_sync_rs;

         if (sync_re or ck_pls_cnt(ck_pls_cnt'high)) = '1' then
            ck_pls_cnt <= std_logic_vector(to_signed(c_CK_PLS_CNT_MAX_VAL, ck_pls_cnt'length));

         elsif not(pixel_pos(pixel_pos'high)) = '1' then
            ck_pls_cnt <= std_logic_vector(signed(ck_pls_cnt) - 1);

         end if;

         if sync_re = '1' then
            pixel_pos <= std_logic_vector(to_signed(c_PIXEL_POS_MAX_VAL , pixel_pos'length));

         elsif (not(pixel_pos(pixel_pos'high)) and ck_pls_cnt(ck_pls_cnt'high)) = '1' then
            pixel_pos <= std_logic_vector(signed(pixel_pos) - 1);

         end if;

      end if;

   end process P_pixel_seq;

   o_sync_re <= sync_re;

   -- ------------------------------------------------------------------------------------------------------
   --!   Command switch clocks
   --    @Req : DRE-DMX-FW-REQ-0115
   --    @Req : DRE-DMX-FW-REQ-0260
   -- ------------------------------------------------------------------------------------------------------
   G_column_mgt: for k in 0 to c_NB_COL-1 generate
   begin
      cmd_ck_sq1_adc_ena(k) <=   '1' when i_tm_mode        = c_DST_TM_MODE_DUMP  else
                                 '1' when i_tm_mode        = c_DST_TM_MODE_NORM  else
                                 '1' when i_sq1_fb_mode(k) = c_DST_SQ1FBMD_ON    else '0';
      cmd_ck_sq1_dac_ena(k) <=   '0' when i_sq1_fb_mode(k) = c_DST_SQ1FBMD_OFF   else '1';

      P_cmd_ck_sq1 : process (i_rst, i_clk)
      begin

         if i_rst = '1' then
            o_cmd_ck_s1_adc_ena(k) <= '0';
            o_cmd_ck_s1_adc_dis(k) <= '0';

            o_cmd_ck_s1_dac_ena(k) <= '0';
            o_cmd_ck_s1_dac_dis(k) <= '0';

         elsif rising_edge(i_clk) then
            if pixel_pos = std_logic_vector(to_signed(c_PIX_POS_SW_ON, pixel_pos'length)) then
               o_cmd_ck_s1_adc_ena(k) <= cmd_ck_sq1_adc_ena(k) and ck_pls_cnt(ck_pls_cnt'high);

            else
               o_cmd_ck_s1_adc_ena(k) <= '0';

            end if;

            if pixel_pos = std_logic_vector(to_signed(c_PIX_POS_SW_ADC_OFF, pixel_pos'length)) then
               o_cmd_ck_s1_adc_dis(k) <= not(cmd_ck_sq1_adc_ena(k)) and ck_pls_cnt(ck_pls_cnt'high);

            else
               o_cmd_ck_s1_adc_dis(k) <= '0';

            end if;

            if pixel_pos = std_logic_vector(to_signed(c_PIX_POS_SW_ON, pixel_pos'length)) then
               o_cmd_ck_s1_dac_ena(k) <= cmd_ck_sq1_dac_ena(k) and ck_pls_cnt(ck_pls_cnt'high);

            else
               o_cmd_ck_s1_dac_ena(k) <= '0';

            end if;

            o_cmd_ck_s1_dac_dis(k) <= not(cmd_ck_sq1_dac_ena(k)) and sync_re;

         end if;

      end process P_cmd_ck_sq1;

   end generate G_column_mgt;

end architecture RTL;
