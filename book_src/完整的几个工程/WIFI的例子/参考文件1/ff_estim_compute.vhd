
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: ff_estim_compute.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.6  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Computation of Fine Frequency Estimation
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/fine_freq_estim/vhdl/rtl/ff_estim_compute.vhd,v  
--  Log: ff_estim_compute.vhd,v  
-- Revision 1.6  2003/05/19 08:34:59  Dr.B
-- correct bug on CORDIC_MAX_CT.
--
-- Revision 1.5  2003/04/18 08:43:00  Dr.B
-- change cordic size.
--
-- Revision 1.4  2003/04/11 08:59:23  Dr.B
-- improve cf storage.
--
-- Revision 1.3  2003/04/04 16:32:08  Dr.B
-- cordic_vect instantiated.
--
-- Revision 1.2  2003/04/01 11:50:34  Dr.B
-- counter from sm.
--
-- Revision 1.1  2003/03/27 17:45:15  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--library fine_freq_estim_rtl;
library work;
--use fine_freq_estim_rtl.fine_freq_estim_pkg.all;
use work.fine_freq_estim_pkg.all;

--library cordic_vect_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ff_estim_compute is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                          : in  std_logic;
    reset_n                      : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i                       : in  std_logic;
    -- data used to compute Cf/Tcomb (T1mem/T2)
    t1_re_i                      : in  std_logic_vector(10 downto 0);
    t1_im_i                      : in  std_logic_vector(10 downto 0);
    t2_re_i                      : in  std_logic_vector(10 downto 0);
    t2_im_i                      : in  std_logic_vector(10 downto 0);
    -- data used to compute Cf/Tcomb (T1mem/T2)
    data_valid_4_cf_compute_i    : in  std_logic;
    last_data_i                  : in  std_logic;
    shift_param_i                : in  std_logic_vector(2 downto 0);
    -- Markers 
    start_of_symbol_i            : in  std_logic;
    -- Cf calculation
    cf_freqcorr_o                : out std_logic_vector(23 downto 0);
    data_valid_freqcorr_o        : out std_logic;
    -- Tcomb calculation
    tcomb_re_o                   : out std_logic_vector(10 downto 0);
    tcomb_im_o                   : out std_logic_vector(10 downto 0)
    );

end ff_estim_compute;
