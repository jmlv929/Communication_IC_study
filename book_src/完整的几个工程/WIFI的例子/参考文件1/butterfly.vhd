
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : FFT
--    ,' GoodLuck ,'      RCSfile: butterfly.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : butterfly operation (in fact FFT 8 points).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/fft_2cordic/vhdl/rtl/butterfly.vhd,v  
--  Log: butterfly.vhd,v  
-- Revision 1.5  2003/06/25 07:59:09  Dr.C
-- Modified code to be Synopsys compliant
--
-- Revision 1.4  2003/05/23 14:05:05  Dr.J
-- Removed array mismatch
--
-- Revision 1.3  2003/05/23 09:10:18  Dr.J
-- Updated to increase the precision
--
-- Revision 1.2  2003/05/14 14:57:23  Dr.J
-- Changed the size of the data between the several stages to increase the
-- performence.
--
-- Revision 1.1  2003/03/17 08:10:49  Dr.F
-- Initial revision
--
--
---------------------------------------------------'-----------------------------
-- Revision history
--
-- Revision 1.3  2003/01/24 13:30:23  rmetzler
-- Beautified and made compliant with the NICE design rules
--
-- Revision 1.2  2003/01/20 09:58:38  rmetzler
-- Increase accuracy of the multiplication for the last 2 bits
--
-- Revision 1.1  2002/12/18 11:00:00  cklausma
-- initial check in with ncvs
--
-- Revision 1.2  2001/09/26 14:07:22  omilou
-- changed decimal point management.
--
-- Revision 1.1  2001/06/11 06:19:05  omilou
-- Initial revision
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity butterfly is
  generic (
    data_size_g    : integer   -- should be between 10 and 32
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
    ifft_mode_i  : in  std_logic;  -- 0 for fft mode
                                   -- 1 for ifft mode 

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
    -- 
    x_0_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_0_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_1_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_1_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_2_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_2_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_3_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_3_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_4_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_4_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_5_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_5_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_6_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_6_o      : out std_logic_vector(data_size_g-1 downto 0);   
    x_7_o      : out std_logic_vector(data_size_g-1 downto 0);   
    y_7_o      : out std_logic_vector(data_size_g-1 downto 0)   
  );

end butterfly;
