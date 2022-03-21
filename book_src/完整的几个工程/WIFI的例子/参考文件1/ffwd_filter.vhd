
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: ffwd_filter.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.13   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Feedforward filter for equalization.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/ffwd_filter.vhd,v  
--  Log: ffwd_filter.vhd,v  
-- Revision 1.13  2004/04/05 15:27:35  Dr.B
-- Added condition on datapath to maintain registers reset until filter is activated (equalizer_init_n='1').
-- Changed data_i/q_ff18 for data_i/q_ff17 in filter_i/q_out OUTPUT when filter is not activated..
--
-- Revision 1.12  2003/09/30 08:36:18  Dr.B
-- debug output truncature.
--
-- Revision 1.11  2003/09/18 08:38:13  Dr.A
-- tk_out set to zero when equalizer_init_n is low.
--
-- Revision 1.10  2003/09/09 12:59:46  Dr.C
-- Removed power_estim links.
--
-- Revision 1.9  2002/12/03 15:05:42  Dr.B
-- change condition on multiplier sharing activate -> init_n.
--
-- Revision 1.8  2002/11/06 17:16:22  Dr.A
-- Optimized abs_2 signals.
--
-- Revision 1.7  2002/09/25 15:44:32  Dr.A
-- Use multiplier output to other blocks when equ_activate = 0.
--
-- Revision 1.6  2002/09/19 17:00:00  Dr.A
-- Share a multiplier external block + misc debug.
--
-- Revision 1.5  2002/07/31 13:07:30  Dr.B
-- new size.
--
-- Revision 1.4  2002/07/11 12:37:19  Dr.B
-- remove unused signals.
--
-- Revision 1.3  2002/06/27 16:18:27  Dr.B
-- filter removed. 9 complex_4mult instead.
--
-- Revision 1.2  2002/05/07 16:56:10  Dr.A
-- New filter.
--
-- Revision 1.1  2002/03/28 13:49:09  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 

--library equalizer_rtl;
library work;
--use equalizer_rtl.equalizer_pkg.all;
use work.equalizer_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ffwd_filter is
  generic (
    dsize_g   : integer := 6;  -- Data size
    csize_g   : integer := 21; -- Coefficients size
    outsize_g : integer := 9   -- output data size
  );
  port (
    -- Clock and reset
    reset_n         : in  std_logic;
    clk             : in  std_logic;
    -- Counter for filter speed
    div_counter     : in  std_logic_vector(1 downto 0);
    -- Equalizer disable
    equalizer_disb  : in  std_logic;
    equalizer_init_n: in  std_logic; -- filter coeffs= 0  when low.
    -- Data to multiply  when equ is disable for peak detector
    d_signed_peak_i   : in  std_logic_vector(dsize_g-1 downto 0);
    d_signed_peak_q   : in  std_logic_vector(dsize_g-1 downto 0);
    -- Filter inputs from delay line
    data_i_ff0      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff1      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff2      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff3      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff4      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff5      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff6      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff7      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff8      : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff9      : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_i_ff10     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff11     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff12     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff13     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff14     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff15     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff16     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff17     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff18     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff19     : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_i_ff20     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff21     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff22     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff23     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff24     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff25     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff26     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff27     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff28     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff29     : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_i_ff30     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff31     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff32     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff33     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff34     : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff35     : in  std_logic_vector(dsize_g-1 downto 0);

    data_q_ff0      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff1      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff2      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff3      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff4      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff5      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff6      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff7      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff8      : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff9      : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_q_ff10     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff11     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff12     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff13     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff14     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff15     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff16     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff17     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff18     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff19     : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_q_ff20     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff21     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff22     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff23     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff24     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff25     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff26     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff27     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff28     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff29     : in  std_logic_vector(dsize_g-1 downto 0);
    
    data_q_ff30     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff31     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff32     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff33     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff34     : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff35     : in  std_logic_vector(dsize_g-1 downto 0);

    
    -- Filter coefficients (real part)
    k_i0            : in  std_logic_vector(csize_g-1 downto 0);
    k_i1            : in  std_logic_vector(csize_g-1 downto 0);
    k_i2            : in  std_logic_vector(csize_g-1 downto 0);
    k_i3            : in  std_logic_vector(csize_g-1 downto 0);
    k_i4            : in  std_logic_vector(csize_g-1 downto 0);
    k_i5            : in  std_logic_vector(csize_g-1 downto 0);
    k_i6            : in  std_logic_vector(csize_g-1 downto 0);
    k_i7            : in  std_logic_vector(csize_g-1 downto 0);
    k_i8            : in  std_logic_vector(csize_g-1 downto 0);
    k_i9            : in  std_logic_vector(csize_g-1 downto 0);
    
    k_i10           : in  std_logic_vector(csize_g-1 downto 0);
    k_i11           : in  std_logic_vector(csize_g-1 downto 0);
    k_i12           : in  std_logic_vector(csize_g-1 downto 0);
    k_i13           : in  std_logic_vector(csize_g-1 downto 0);
    k_i14           : in  std_logic_vector(csize_g-1 downto 0);
    k_i15           : in  std_logic_vector(csize_g-1 downto 0);
    k_i16           : in  std_logic_vector(csize_g-1 downto 0);
    k_i17           : in  std_logic_vector(csize_g-1 downto 0);
    k_i18           : in  std_logic_vector(csize_g-1 downto 0);
    k_i19           : in  std_logic_vector(csize_g-1 downto 0);
    
    k_i20           : in  std_logic_vector(csize_g-1 downto 0);
    k_i21           : in  std_logic_vector(csize_g-1 downto 0);
    k_i22           : in  std_logic_vector(csize_g-1 downto 0);
    k_i23           : in  std_logic_vector(csize_g-1 downto 0);
    k_i24           : in  std_logic_vector(csize_g-1 downto 0);
    k_i25           : in  std_logic_vector(csize_g-1 downto 0);
    k_i26           : in  std_logic_vector(csize_g-1 downto 0);
    k_i27           : in  std_logic_vector(csize_g-1 downto 0);
    k_i28           : in  std_logic_vector(csize_g-1 downto 0);
    k_i29           : in  std_logic_vector(csize_g-1 downto 0);
    
    k_i30           : in  std_logic_vector(csize_g-1 downto 0);
    k_i31           : in  std_logic_vector(csize_g-1 downto 0);
    k_i32           : in  std_logic_vector(csize_g-1 downto 0);
    k_i33           : in  std_logic_vector(csize_g-1 downto 0);
    k_i34           : in  std_logic_vector(csize_g-1 downto 0);
    k_i35           : in  std_logic_vector(csize_g-1 downto 0);
    
    -- Filter coefficients (imaginary part)
    k_q0            : in  std_logic_vector(csize_g-1 downto 0);
    k_q1            : in  std_logic_vector(csize_g-1 downto 0);
    k_q2            : in  std_logic_vector(csize_g-1 downto 0);
    k_q3            : in  std_logic_vector(csize_g-1 downto 0);
    k_q4            : in  std_logic_vector(csize_g-1 downto 0);
    k_q5            : in  std_logic_vector(csize_g-1 downto 0);
    k_q6            : in  std_logic_vector(csize_g-1 downto 0);
    k_q7            : in  std_logic_vector(csize_g-1 downto 0);
    k_q8            : in  std_logic_vector(csize_g-1 downto 0);
    k_q9            : in  std_logic_vector(csize_g-1 downto 0);
    
    k_q10           : in  std_logic_vector(csize_g-1 downto 0);
    k_q11           : in  std_logic_vector(csize_g-1 downto 0);
    k_q12           : in  std_logic_vector(csize_g-1 downto 0);
    k_q13           : in  std_logic_vector(csize_g-1 downto 0);
    k_q14           : in  std_logic_vector(csize_g-1 downto 0);
    k_q15           : in  std_logic_vector(csize_g-1 downto 0);
    k_q16           : in  std_logic_vector(csize_g-1 downto 0);
    k_q17           : in  std_logic_vector(csize_g-1 downto 0);
    k_q18           : in  std_logic_vector(csize_g-1 downto 0);
    k_q19           : in  std_logic_vector(csize_g-1 downto 0);
    
    k_q20           : in  std_logic_vector(csize_g-1 downto 0);
    k_q21           : in  std_logic_vector(csize_g-1 downto 0);
    k_q22           : in  std_logic_vector(csize_g-1 downto 0);
    k_q23           : in  std_logic_vector(csize_g-1 downto 0);
    k_q24           : in  std_logic_vector(csize_g-1 downto 0);
    k_q25           : in  std_logic_vector(csize_g-1 downto 0);
    k_q26           : in  std_logic_vector(csize_g-1 downto 0);
    k_q27           : in  std_logic_vector(csize_g-1 downto 0);
    k_q28           : in  std_logic_vector(csize_g-1 downto 0);
    k_q29           : in  std_logic_vector(csize_g-1 downto 0);
    
    k_q30           : in  std_logic_vector(csize_g-1 downto 0);
    k_q31           : in  std_logic_vector(csize_g-1 downto 0);
    k_q32           : in  std_logic_vector(csize_g-1 downto 0);
    k_q33           : in  std_logic_vector(csize_g-1 downto 0);
    k_q34           : in  std_logic_vector(csize_g-1 downto 0);
    k_q35           : in  std_logic_vector(csize_g-1 downto 0);
    
    -- Filter output
    filter_i_out    : out std_logic_vector(outsize_g-1 downto 0);
    filter_q_out    : out std_logic_vector(outsize_g-1 downto 0);
    tk_i_out        : out std_logic_vector(outsize_g-1 downto 0);
    tk_q_out        : out std_logic_vector(outsize_g-1 downto 0);
    -- Output for peak_detect
    abs_2_corr      : out std_logic_vector (2*dsize_g-1 downto 0)
    
  );

end ffwd_filter;
