
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of adder4 is

begin
  output0_real <= input0_real + input1_real;
  output0_imag <= input0_imag + input1_imag;

  output1_real <= input0_imag + input1_real;
  output1_imag <= input1_imag - input0_real;

  output2_real <= input1_real - input0_real;
  output2_imag <= input1_imag - input0_imag;

  output3_real <= input1_real - input0_imag;
  output3_imag <= input0_real + input1_imag;
end rtl;
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : FWT
--    ,' GoodLuck ,'      RCSfile: fwt.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Fast Walsh Transform
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/fwt/vhdl/rtl/fwt.vhd,v  
--  Log: fwt.vhd,v  
-- Revision 1.7  2004/04/30 15:01:37  arisse
-- Added reset of data between two packets :
-- Added input cck_demod_enable for that.
--
-- Revision 1.6  2002/09/20 07:28:55  elama
-- Variables storeX_X reseted in main process.
--
-- Revision 1.5  2002/06/05 07:25:59  elama
-- Fixed bug in the sign.
--
-- Revision 1.4  2002/05/31 12:21:15  elama
-- Incremented the size of the generic in adder4.
--
-- Revision 1.3  2002/05/30 14:45:58  elama
-- Generic size changed.
--
-- Revision 1.2  2002/03/14 17:24:48  elama
-- Reduced the number of data ouput ports and added the data_valid flag.
--
-- Revision 1.1  2002/01/29 09:31:43  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--library fwt_rtl; 
library work;
--use fwt_rtl.fwt_pkg.ALL; 
use work.fwt_pkg.ALL; 

entity fwt is
generic (
  data_length : integer := 6            -- Number of bits for data Input ports.
                                        -- 3 more bits for data output ports.
);
port (
  reset_n     : in  std_logic;          -- System reset. Active LOW.
  clk         : in  std_logic;          -- System clock.
  cck_demod_enable : in std_logic;
  start_fwt   : in  std_logic;          -- Start the fwt.
  end_fwt     : out std_logic;          -- Flag indicating fwt is finished.
  data_valid  : out std_logic;          -- Flag indicating output data valid.
--
  input0_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in0
  input0_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in0.
  input1_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in1
  input1_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in1.
  input2_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in2
  input2_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in2.
  input3_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in3
  input3_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in3.
  input4_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in4
  input4_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in4.
  input5_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in5
  input5_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in5.
  input6_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in6
  input6_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in6.
  input7_re   : in  std_logic_vector (data_length-1 downto 0);--Real part of in7
  input7_im   : in  std_logic_vector (data_length-1 downto 0);--Im part of in7.
--
  output0_re  : out std_logic_vector (data_length+2 downto 0);--R part of out0.
  output0_im  : out std_logic_vector (data_length+2 downto 0);--Im part of out0.
  output1_re  : out std_logic_vector (data_length+2 downto 0);--R part of out1.
  output1_im  : out std_logic_vector (data_length+2 downto 0);--Im part of out1.
  output2_re  : out std_logic_vector (data_length+2 downto 0);--R part of out2.
  output2_im  : out std_logic_vector (data_length+2 downto 0);--Im part of out2.
  output3_re  : out std_logic_vector (data_length+2 downto 0);--R part of out3.
  output3_im  : out std_logic_vector (data_length+2 downto 0) --Im part of out3.
);
end fwt;
