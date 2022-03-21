
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : FFT
--    ,' GoodLuck ,'      RCSfile: fft_2cordic.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : FFT 64 points.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/fft_2cordic/vhdl/rtl/fft_2cordic.vhd,v  
--  Log: fft_2cordic.vhd,v  
-- Revision 1.6  2003/05/23 15:17:59  Dr.J
-- Added library std_logic_arith
--
-- Revision 1.5  2003/05/23 15:13:52  Dr.J
-- Added a sign extension
--
-- Revision 1.4  2003/05/23 15:01:58  Dr.J
-- The output size is datasize + 1
--
-- Revision 1.3  2003/05/14 14:58:44  Dr.J
-- Changed only the default value of the generics
--
-- Revision 1.2  2003/03/29 08:03:53  Dr.F
-- added library declaration of cordic_fft2.
--
-- Revision 1.1  2003/03/17 08:10:52  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 
 
--library fft_2cordic_rtl;
library work;
--use fft_2cordic_rtl.fft_2cordic_pkg.all;
use work.fft_2cordic_pkg.all;

--library cordic_fft2_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity fft_2cordic is
  generic (
    data_size_g   : integer := 11; -- should be between 10 and 32
    cordic_bits_g : integer := 10  -- should be between 8 and 31
                                   -- data_size_g-1 >= cordic_bits_g
          );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    masterclk    : in  std_logic;   
    reset_n      : in  std_logic;
    sync_rst_ni  : in  std_logic;

    --------------------------------------
    -- fft control
    --------------------------------------
    start_fft_i    : in  std_logic;   
    ifft_mode_i    : in  std_logic;  -- 0 for fft mode
                                   -- 1 for ifft mode 
    ifft_norm_i    : in  std_logic;  -- 0 no ifft normalization
                                   -- 1 ifft normalization (x 1/64) 
    --
    read_done_o    : out std_logic;  -- If this signal is high, the last input
                                     -- word is read at tne next rising edge of
                                     -- "masterclk"
    fft_done_o     : out std_logic;   

    --------------------------------------
    -- fft data
    --------------------------------------
    x_0_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_0_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_1_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_1_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_2_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_2_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_3_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_3_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_4_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_4_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_5_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_5_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_6_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_6_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_7_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_7_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_8_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_8_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_9_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    y_9_i       : in  std_logic_vector(data_size_g-1 downto 0);   
    x_10_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_10_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_11_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_11_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_12_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_12_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_13_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_13_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_14_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_14_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_15_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_15_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_16_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_16_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_17_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_17_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_18_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_18_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_19_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_19_i      : in  std_logic_vector(data_size_g-1 downto 0);
    x_20_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_20_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_21_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_21_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_22_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_22_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_23_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_23_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_24_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_24_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_25_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_25_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_26_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_26_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_27_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_27_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_28_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_28_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_29_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_29_i      : in  std_logic_vector(data_size_g-1 downto 0);
    x_30_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_30_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_31_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_31_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_32_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_32_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_33_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_33_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_34_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_34_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_35_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_35_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_36_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_36_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_37_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_37_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_38_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_38_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_39_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_39_i      : in  std_logic_vector(data_size_g-1 downto 0);
    x_40_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_40_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_41_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_41_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_42_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_42_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_43_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_43_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_44_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_44_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_45_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_45_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_46_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_46_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_47_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_47_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_48_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_48_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_49_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_49_i      : in  std_logic_vector(data_size_g-1 downto 0);
    x_50_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_50_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_51_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_51_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_52_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_52_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_53_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_53_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_54_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_54_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_55_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_55_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_56_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_56_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_57_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_57_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_58_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_58_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_59_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_59_i      : in  std_logic_vector(data_size_g-1 downto 0);
    x_60_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_60_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_61_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_61_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_62_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_62_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    x_63_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    y_63_i      : in  std_logic_vector(data_size_g-1 downto 0);   
    --
    x_0_o      : out std_logic_vector(data_size_g downto 0);   
    y_0_o      : out std_logic_vector(data_size_g downto 0);   
    x_1_o      : out std_logic_vector(data_size_g downto 0);   
    y_1_o      : out std_logic_vector(data_size_g downto 0);   
    x_2_o      : out std_logic_vector(data_size_g downto 0);   
    y_2_o      : out std_logic_vector(data_size_g downto 0);   
    x_3_o      : out std_logic_vector(data_size_g downto 0);   
    y_3_o      : out std_logic_vector(data_size_g downto 0);   
    x_4_o      : out std_logic_vector(data_size_g downto 0);   
    y_4_o      : out std_logic_vector(data_size_g downto 0);   
    x_5_o      : out std_logic_vector(data_size_g downto 0);   
    y_5_o      : out std_logic_vector(data_size_g downto 0);   
    x_6_o      : out std_logic_vector(data_size_g downto 0);   
    y_6_o      : out std_logic_vector(data_size_g downto 0);   
    x_7_o      : out std_logic_vector(data_size_g downto 0);   
    y_7_o      : out std_logic_vector(data_size_g downto 0);   
    x_8_o      : out std_logic_vector(data_size_g downto 0);   
    y_8_o      : out std_logic_vector(data_size_g downto 0);   
    x_9_o      : out std_logic_vector(data_size_g downto 0);   
    y_9_o      : out std_logic_vector(data_size_g downto 0);   
    x_10_o     : out std_logic_vector(data_size_g downto 0);   
    y_10_o     : out std_logic_vector(data_size_g downto 0);   
    x_11_o     : out std_logic_vector(data_size_g downto 0);   
    y_11_o     : out std_logic_vector(data_size_g downto 0);   
    x_12_o     : out std_logic_vector(data_size_g downto 0);   
    y_12_o     : out std_logic_vector(data_size_g downto 0);   
    x_13_o     : out std_logic_vector(data_size_g downto 0);   
    y_13_o     : out std_logic_vector(data_size_g downto 0);   
    x_14_o     : out std_logic_vector(data_size_g downto 0);   
    y_14_o     : out std_logic_vector(data_size_g downto 0);   
    x_15_o     : out std_logic_vector(data_size_g downto 0);   
    y_15_o     : out std_logic_vector(data_size_g downto 0);   
    x_16_o     : out std_logic_vector(data_size_g downto 0);   
    y_16_o     : out std_logic_vector(data_size_g downto 0);   
    x_17_o     : out std_logic_vector(data_size_g downto 0);   
    y_17_o     : out std_logic_vector(data_size_g downto 0);   
    x_18_o     : out std_logic_vector(data_size_g downto 0);   
    y_18_o     : out std_logic_vector(data_size_g downto 0);   
    x_19_o     : out std_logic_vector(data_size_g downto 0);   
    y_19_o     : out std_logic_vector(data_size_g downto 0);
    x_20_o     : out std_logic_vector(data_size_g downto 0);   
    y_20_o     : out std_logic_vector(data_size_g downto 0);   
    x_21_o     : out std_logic_vector(data_size_g downto 0);   
    y_21_o     : out std_logic_vector(data_size_g downto 0);   
    x_22_o     : out std_logic_vector(data_size_g downto 0);   
    y_22_o     : out std_logic_vector(data_size_g downto 0);   
    x_23_o     : out std_logic_vector(data_size_g downto 0);   
    y_23_o     : out std_logic_vector(data_size_g downto 0);   
    x_24_o     : out std_logic_vector(data_size_g downto 0);   
    y_24_o     : out std_logic_vector(data_size_g downto 0);   
    x_25_o     : out std_logic_vector(data_size_g downto 0);   
    y_25_o     : out std_logic_vector(data_size_g downto 0);   
    x_26_o     : out std_logic_vector(data_size_g downto 0);   
    y_26_o     : out std_logic_vector(data_size_g downto 0);   
    x_27_o     : out std_logic_vector(data_size_g downto 0);   
    y_27_o     : out std_logic_vector(data_size_g downto 0);   
    x_28_o     : out std_logic_vector(data_size_g downto 0);   
    y_28_o     : out std_logic_vector(data_size_g downto 0);   
    x_29_o     : out std_logic_vector(data_size_g downto 0);   
    y_29_o     : out std_logic_vector(data_size_g downto 0);
    x_30_o     : out std_logic_vector(data_size_g downto 0);   
    y_30_o     : out std_logic_vector(data_size_g downto 0);   
    x_31_o     : out std_logic_vector(data_size_g downto 0);   
    y_31_o     : out std_logic_vector(data_size_g downto 0);   
    x_32_o     : out std_logic_vector(data_size_g downto 0);   
    y_32_o     : out std_logic_vector(data_size_g downto 0);   
    x_33_o     : out std_logic_vector(data_size_g downto 0);   
    y_33_o     : out std_logic_vector(data_size_g downto 0);   
    x_34_o     : out std_logic_vector(data_size_g downto 0);   
    y_34_o     : out std_logic_vector(data_size_g downto 0);   
    x_35_o     : out std_logic_vector(data_size_g downto 0);   
    y_35_o     : out std_logic_vector(data_size_g downto 0);   
    x_36_o     : out std_logic_vector(data_size_g downto 0);   
    y_36_o     : out std_logic_vector(data_size_g downto 0);   
    x_37_o     : out std_logic_vector(data_size_g downto 0);   
    y_37_o     : out std_logic_vector(data_size_g downto 0);   
    x_38_o     : out std_logic_vector(data_size_g downto 0);   
    y_38_o     : out std_logic_vector(data_size_g downto 0);   
    x_39_o     : out std_logic_vector(data_size_g downto 0);   
    y_39_o     : out std_logic_vector(data_size_g downto 0);
    x_40_o     : out std_logic_vector(data_size_g downto 0);   
    y_40_o     : out std_logic_vector(data_size_g downto 0);   
    x_41_o     : out std_logic_vector(data_size_g downto 0);   
    y_41_o     : out std_logic_vector(data_size_g downto 0);   
    x_42_o     : out std_logic_vector(data_size_g downto 0);   
    y_42_o     : out std_logic_vector(data_size_g downto 0);   
    x_43_o     : out std_logic_vector(data_size_g downto 0);   
    y_43_o     : out std_logic_vector(data_size_g downto 0);   
    x_44_o     : out std_logic_vector(data_size_g downto 0);   
    y_44_o     : out std_logic_vector(data_size_g downto 0);   
    x_45_o     : out std_logic_vector(data_size_g downto 0);   
    y_45_o     : out std_logic_vector(data_size_g downto 0);   
    x_46_o     : out std_logic_vector(data_size_g downto 0);   
    y_46_o     : out std_logic_vector(data_size_g downto 0);   
    x_47_o     : out std_logic_vector(data_size_g downto 0);   
    y_47_o     : out std_logic_vector(data_size_g downto 0);   
    x_48_o     : out std_logic_vector(data_size_g downto 0);   
    y_48_o     : out std_logic_vector(data_size_g downto 0);   
    x_49_o     : out std_logic_vector(data_size_g downto 0);   
    y_49_o     : out std_logic_vector(data_size_g downto 0);
    x_50_o     : out std_logic_vector(data_size_g downto 0);   
    y_50_o     : out std_logic_vector(data_size_g downto 0);   
    x_51_o     : out std_logic_vector(data_size_g downto 0);   
    y_51_o     : out std_logic_vector(data_size_g downto 0);   
    x_52_o     : out std_logic_vector(data_size_g downto 0);   
    y_52_o     : out std_logic_vector(data_size_g downto 0);   
    x_53_o     : out std_logic_vector(data_size_g downto 0);   
    y_53_o     : out std_logic_vector(data_size_g downto 0);   
    x_54_o     : out std_logic_vector(data_size_g downto 0);   
    y_54_o     : out std_logic_vector(data_size_g downto 0);   
    x_55_o     : out std_logic_vector(data_size_g downto 0);   
    y_55_o     : out std_logic_vector(data_size_g downto 0);   
    x_56_o     : out std_logic_vector(data_size_g downto 0);   
    y_56_o     : out std_logic_vector(data_size_g downto 0);   
    x_57_o     : out std_logic_vector(data_size_g downto 0);   
    y_57_o     : out std_logic_vector(data_size_g downto 0);   
    x_58_o     : out std_logic_vector(data_size_g downto 0);   
    y_58_o     : out std_logic_vector(data_size_g downto 0);   
    x_59_o     : out std_logic_vector(data_size_g downto 0);   
    y_59_o     : out std_logic_vector(data_size_g downto 0);
    x_60_o     : out std_logic_vector(data_size_g downto 0);   
    y_60_o     : out std_logic_vector(data_size_g downto 0);   
    x_61_o     : out std_logic_vector(data_size_g downto 0);   
    y_61_o     : out std_logic_vector(data_size_g downto 0);   
    x_62_o     : out std_logic_vector(data_size_g downto 0);   
    y_62_o     : out std_logic_vector(data_size_g downto 0);   
    x_63_o     : out std_logic_vector(data_size_g downto 0);   
    y_63_o     : out std_logic_vector(data_size_g downto 0)   
  );

end fft_2cordic;
