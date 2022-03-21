
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: freq_domain.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.15  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Frequency domain top.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/freq_domain/vhdl/rtl/freq_domain.vhd,v  
--  Log: freq_domain.vhd,v  
-- Revision 1.15  2004/12/14 16:59:35  Dr.C
-- #BugId:772#
-- Updated channel decoder port map.
--
-- Revision 1.14  2004/07/20 16:14:42  Dr.C
-- Change order of FFT saturation and the multiplication by 4.
--
-- Revision 1.13  2004/04/26 07:41:10  Dr.C
-- Added saturation after FFT and cleaned code.
--
-- Revision 1.12  2003/10/16 07:08:17  Dr.C
-- Debugged diag port connection.
--
-- Revision 1.11  2003/10/15 16:39:57  Dr.C
-- Added debug port.
--
-- Revision 1.10  2003/06/25 16:01:59  Dr.J
-- Changed the size of the sto and cpe in the ramp phase rot
--
-- Revision 1.9  2003/06/11 13:11:43  Dr.J
-- Changed the sign of the sto an cpe
--
-- Revision 1.8  2003/05/26 09:18:00  Dr.F
-- shifted output of preamble demux.
--
-- Revision 1.7  2003/05/14 15:10:10  Dr.F
-- removed multiplication by 8 after FFT.
--
-- Revision 1.6  2003/05/12 15:02:36  Dr.F
-- added signal_valid_i input to ramp_phase_rot.
--
-- Revision 1.5  2003/04/24 06:22:45  Dr.F
-- debugged internal connections.
--
-- Revision 1.4  2003/04/04 07:59:55  Dr.F
-- removed the inverter.
--
-- Revision 1.3  2003/03/31 08:40:29  Dr.F
-- added inverter.
--
-- Revision 1.2  2003/03/28 16:04:54  Dr.F
-- changed some port names.
--
-- Revision 1.1  2003/03/27 09:43:00  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library freq_domain_rtl;
library work;
--use freq_domain_rtl.freq_domain_pkg.all;
use work.freq_domain_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--library rx_predmx_rtl;
library work;
--library wiener_filter_rtl;
library work;
--library wie_mem_rtl;
library work;
--library rx_equ_rtl;
library work;
--library channel_decoder_rtl;
library work;
--library rx_descr_rtl;
library work;
--library pilot_tracking_rtl;
library work;
--library ramp_phase_rot_rtl;
library work;

--------------------------------------------
-- Entity
--------------------------------------------
entity freq_domain is

  port (
    clk                             : in  std_logic;
    reset_n                         : in  std_logic;
    sync_reset_n                    : in  std_logic;
    -- from mac interface
    data_ready_i                    : in  std_logic;
    
    -- FFT Shell interface
    i_i                             : in  FFT_ARRAY_T;
    q_i                             : in  FFT_ARRAY_T;
    data_valid_i                    : in  std_logic;
    start_of_burst_i                : in  std_logic;
    start_of_symbol_i               : in  std_logic;
    data_ready_o                    : out std_logic;

    -- from descrambling
    data_o                          : out std_logic;
    data_valid_o                    : out std_logic;
    rxv_service_o                   : out std_logic_vector(15 downto 0);
    rxv_service_ind_o               : out std_logic;
    start_of_burst_o                : out std_logic;
    -----------------------------------------------------------------------
    -- Parameters
    -----------------------------------------------------------------------
    -- to wiener filter
    wf_window_i       		          : in  std_logic_vector(1 downto 0);
    -- to channel decoder
    length_limit_i                  : in std_logic_vector(11 downto 0);
    rx_length_chk_en_i              : in std_logic;
    -- to equalizer
    histoffset_54_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_48_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_36_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_24_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_18_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_12_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_09_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 
    histoffset_06_i                 : in  std_logic_vector(HISTOFFSET_WIDTH_CT -1 downto 0); 

    satmaxncarr_54_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_48_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_36_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_24_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_18_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_12_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_09_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_06_i                : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 

    reducerasures_i                 : in  std_logic_vector(1 downto 0);
    -----------------------------------------------------------------------
    -- Control info interface
    -----------------------------------------------------------------------
    signal_field_o                    : out std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0);
    signal_field_parity_error_o       : out std_logic;
    signal_field_unsupported_rate_o   : out std_logic;
    signal_field_unsupported_length_o : out std_logic;
    signal_field_valid_o              : out std_logic;
    end_of_data_o                     : out std_logic;
    -----------------------------------------------------------------------
    -- Diag. port
    -----------------------------------------------------------------------
    freq_domain_diag                  : out std_logic_vector(6 downto 0)
    );

end freq_domain;
