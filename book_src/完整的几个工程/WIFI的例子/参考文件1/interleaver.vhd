
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: interleaver.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Interleaver and carrier reordering block.
--               This block performs the two premutation described by the
--               standard and sends out the carriers in the order expected
--               by the IFFT.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/interleaver/vhdl/rtl/interleaver.vhd,v  
--  Log: interleaver.vhd,v  
-- Revision 1.2  2003/03/26 10:57:11  Dr.A
-- Modified marker generation for FFT compliancy.
--
-- Revision 1.1  2003/03/13 14:50:56  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library interleaver_rtl;
library work;
--use interleaver_rtl.interleaver_pkg.all;
use work.interleaver_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity interleaver is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk             : in  std_logic; -- Module clock.
    reset_n         : in  std_logic; -- Asynchronous reset.
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i        : in  std_logic; -- TX path enable.
    data_valid_i    : in  std_logic; -- High when input data is valid.
    data_ready_i    : in  std_logic; -- Following block is ready to accept data.
    qam_mode_i      : in  std_logic_vector(1 downto 0);
    marker_i        : in  std_logic; -- 'start of signal' or 'end of burst'.
    --
    pilot_ready_o   : out std_logic; -- Ready to accept data from pilot scr.
    start_signal_o  : out std_logic; -- 'start of signal' marker.
    end_burst_o     : out std_logic; -- 'end of burst' marker.
    data_valid_o    : out std_logic; -- High when output data is valid.
    data_ready_o    : out std_logic; -- Ready to accept data from puncturer.
    null_carrier_o  : out std_logic; -- '1' when data for null carrier.
    -- coding rate: 0: QAM64, 1: QPSK, 2: QAM16,  3:BPSK.
    qam_mode_o      : out std_logic_vector(1 downto 0);
    --------------------------------------
    -- Data
    --------------------------------------
    x_i             : in  std_logic; -- x data from puncturer.
    y_i             : in  std_logic; -- y data from puncturer.
    pilot_scr_i     : in  std_logic; -- Data for the 4 pilot carriers.
    --
    data_o          : out std_logic_vector(5 downto 0) -- Interleaved data.
    
  );

end interleaver;
