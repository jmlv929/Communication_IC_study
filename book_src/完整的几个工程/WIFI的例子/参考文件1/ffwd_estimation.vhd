
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: ffwd_estimation.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.14   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Feedforward estimation for equalizer.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/ffwd_estimation.vhd,v  
--  Log: ffwd_estimation.vhd,v  
-- Revision 1.14  2005/01/24 14:14:43  arisse
-- #BugId:624#
-- Added status signals for registers.
--
-- Revision 1.13  2004/04/29 15:57:41  arisse
--  coeff_err_i/q was not reseted between two packets : corrected.
--
-- Revision 1.12  2004/03/15 13:25:54  Dr.B
-- Debug res_mult_comp.
--
-- Revision 1.11  2003/12/12 15:19:15  Dr.B
-- change beta shift.
--
-- Revision 1.10  2003/11/28 08:43:08  arisse
-- Changed generation of array_alpha_shift_trunc_i/q.
--
-- Revision 1.9  2003/09/19 15:14:45  Dr.B
-- debug alpha and beta shift + dc_offset saturation.
--
-- Revision 1.8  2002/11/14 09:12:23  Dr.B
-- dc_offset truncation changes.
--
-- Revision 1.7  2002/08/19 09:18:27  Dr.B
-- variables for max val of array_add_i/q changed to signals.
--
-- Revision 1.6  2002/08/07 12:55:39  Dr.B
-- dc_offset saturation added.
--
-- Revision 1.5  2002/07/31 13:07:45  Dr.B
-- new size.
--
-- Revision 1.4  2002/07/11 12:38:50  Dr.B
-- added saturation on coeff accumulation.
--
-- Revision 1.3  2002/06/27 16:17:57  Dr.B
-- synchro with matlab simu + area optimization.
--
-- Revision 1.2  2002/05/07 16:53:56  Dr.A
-- Cleaned code.
-- Added equalizer_init_n input.
--
-- Revision 1.1  2002/03/28 13:49:04  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

--library equalizer_rtl;
library work;
--use equalizer_rtl.equalizer_pkg.all;
use work.equalizer_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

-- pragma translate_off
--use equalizer_rtl.equalizer_global_pkg.all;
-- pragma translate_on 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ffwd_estimation is
  generic (
    -- generics for coefficients calculation
    dsize_g   : integer := 8;           -- Data Input size
    shifta_g  : integer := 12;          -- data size after shifting by alpha.
    cacsize_g : integer := 20;          -- accumulated coeff size  
    csize_g   : integer := 9;           -- Coeff size (output)
    coeff_g   : integer := 36;  -- Number of filter coefficients (31 to 50)

    -- generics for DC_output calculation
    dccoeff_g  : integer := 20;  -- numbers of bits kept from coeff to calc sum.
    sum_g      : integer := 10;         -- data size of the sum
    multerr_g  : integer := 18;         -- data size after the mult by error
    shiftb_g   : integer := 21;         -- data size after shifting by beta
    dcacsize_g : integer := 21;         -- accumulated dc_offset size  
    dcsize_g   : integer := 6;           -- DC_offset size (output)
    outsize_g : integer := 9  
    );
  port (
    -- Clock and reset
    reset_n : in std_logic;
    clk     : in std_logic;

    -- Chip synchronization.
    div_counter      : in std_logic_vector(1 downto 0);
    equalizer_init_n : in std_logic;    -- Use init coefficients values when 0.
    -- Demodulation error
    error_i          : in std_logic_vector(outsize_g-1 downto 0);  -- I error.
    error_q          : in std_logic_vector(outsize_g-1 downto 0);  -- Q error.
    -- Estimation parameters.
    alpha            : in std_logic_vector(2 downto 0);  -- Shift values from
    beta             : in std_logic_vector(2 downto 0);  -- modem registers.
    -- Control of accumulation
    alpha_accu_disb  : in std_logic;    -- stop coeff accu when high
    beta_accu_disb   : in std_logic;    -- stop dc accu when high

    -- Data from I delay line
    data_i_ff0  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff1  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff2  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff3  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff4  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff5  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff6  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff7  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff8  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff9  : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff10 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff11 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff12 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff13 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff14 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff15 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff16 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff17 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff18 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff19 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff20 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff21 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff22 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff23 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff24 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff25 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff26 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff27 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff28 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff29 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff30 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff31 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff32 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff33 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff34 : in  std_logic_vector(dsize_g-1 downto 0);
    data_i_ff35 : in  std_logic_vector(dsize_g-1 downto 0);
    -- Data from Q delay line
    data_q_ff0  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff1  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff2  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff3  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff4  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff5  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff6  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff7  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff8  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff9  : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff10 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff11 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff12 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff13 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff14 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff15 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff16 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff17 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff18 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff19 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff20 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff21 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff22 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff23 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff24 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff25 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff26 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff27 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff28 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff29 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff30 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff31 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff32 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff33 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff34 : in  std_logic_vector(dsize_g-1 downto 0);
    data_q_ff35 : in  std_logic_vector(dsize_g-1 downto 0);
    -- Filter coefficients (real part)
    coeff_i0    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i1    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i2    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i3    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i4    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i5    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i6    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i7    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i8    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i9    : out std_logic_vector(csize_g-1 downto 0);
    coeff_i10   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i11   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i12   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i13   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i14   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i15   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i16   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i17   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i18   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i19   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i20   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i21   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i22   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i23   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i24   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i25   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i26   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i27   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i28   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i29   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i30   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i31   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i32   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i33   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i34   : out std_logic_vector(csize_g-1 downto 0);
    coeff_i35   : out std_logic_vector(csize_g-1 downto 0);

    -- Filter coefficients (imaginary part)
    coeff_q0  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q1  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q2  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q3  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q4  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q5  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q6  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q7  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q8  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q9  : out std_logic_vector(csize_g-1 downto 0);
    coeff_q10 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q11 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q12 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q13 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q14 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q15 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q16 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q17 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q18 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q19 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q20 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q21 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q22 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q23 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q24 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q25 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q26 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q27 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q28 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q29 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q30 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q31 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q32 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q33 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q34 : out std_logic_vector(csize_g-1 downto 0);
    coeff_q35 : out std_logic_vector(csize_g-1 downto 0);
    
    -- Register stat
    coeff_sum_i_stat : out std_logic_vector(sum_g-1 downto 0);
    coeff_sum_q_stat : out std_logic_vector(sum_g-1 downto 0);
    
    -- DC offset.
    dc_offset_i : out std_logic_vector(dcsize_g-1 downto 0);
    dc_offset_q : out std_logic_vector(dcsize_g-1 downto 0)
    );

end ffwd_estimation;
