
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: ramp_phase_rot.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.32   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Ramp phase rotation
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/ramp_phase_rot/vhdl/rtl/ramp_phase_rot.vhd,v  
--  Log: ramp_phase_rot.vhd,v  
-- Revision 1.32  2004/08/09 13:51:06  Dr.C
-- Increase cordic_x_mul and cordic_y_mul by 1-bit.
--
-- Revision 1.31  2004/07/22 13:55:41  Dr.C
-- Debugged signal width.
--
-- Revision 1.30  2004/07/22 13:29:53  Dr.C
-- Updated phase calculation.
--
-- Revision 1.29  2004/07/20 16:32:04  Dr.C
-- Added a saturation on data out.
--
-- Revision 1.28  2003/11/20 09:15:23  Dr.C
-- Debugged sensitivity list.
--
-- Revision 1.27  2003/11/19 18:28:04  Dr.C
-- Debugged state machine during run_ramp state.
--
-- Revision 1.26  2003/10/29 14:10:05  Dr.C
-- Debugged data_valid_o.
--
-- Revision 1.25  2003/10/28 11:31:33  ahemani
-- For the signal symbol, the data bypasses the CORDIC. Earlier it went through
-- CORDIC with 0 degree angle but CORDIC slightly distorted the data causing
-- mismatch in equalizer.
--
-- Revision 1.24  2003/09/24 07:46:39  ahemaniramp_phase_rot.vhd
-- Signals involved in phase angle calculation have been increased by 1 bit
-- to prevent under/overflow. To be completely safe the signals need to be
-- increased to 23 bits. Alternatively Kalman needs to redimensioned down to
-- produce fewer bits.
-- This is a temp check in. More thorough verification needs to be done..
--
-- Revision 1.23  2003/07/08 13:39:24  Dr.C
-- Debugged start_of_symbol_o reset value.
--
-- Revision 1.22  2003/07/07 09:06:33  Dr.J
-- Added library ramp_phase_rot_rtl;
--
-- Revision 1.21  2003/07/07 08:58:27  Dr.J
-- Removed the cordic_pkg
--
-- Revision 1.20  2003/07/07 08:56:57  Dr.J
-- Updated with the new size of the cordic
--
-- Revision 1.19  2003/06/26 11:57:58  Dr.J
-- Changed the range of the angle
--
-- Revision 1.18  2003/06/26 11:43:23  Dr.J
-- Debugged
--
-- Revision 1.17  2003/06/11 08:55:43  Dr.J
-- Bit true with matlab
--
-- Revision 1.16  2003/05/12 15:21:44  Dr.C
-- Reworked state machine.
--
-- Revision 1.15  2003/05/07 14:08:45  Dr.C
-- Changed cordic port map.
--
-- Revision 1.14  2003/05/05 15:36:03  Dr.C
-- Changed pilot_valid_mem.
--
-- Revision 1.13  2003/05/05 13:37:36  Dr.C
-- Changed pilot_valid_mem.
--
-- Revision 1.12  2003/04/30 09:41:01  Dr.C
-- Updated sensitivity list.
--
-- Revision 1.11  2003/04/30 09:36:03  Dr.C
-- Reworked state machine.
--
-- Revision 1.10  2003/04/29 13:05:54  Dr.C
-- Added wait_data_valid state & changed data_ready_o and data_valid_o assignment.
--
-- Revision 1.9  2003/04/23 17:05:11  Dr.F
-- start phase calculation on start_of_symbol for the first symbol.
--
-- Revision 1.8  2003/04/11 06:14:28  Dr.F
-- debugged output update.
--
-- Revision 1.7  2003/04/08 12:44:32  Dr.C
-- Debugged sensitivity list.
--
-- Revision 1.6  2003/04/03 10:44:26  Dr.C
-- Debugged state machine.
--
-- Revision 1.5  2003/03/31 12:24:11  Dr.C
-- Updated sensitivity list.
--
-- Revision 1.4  2003/03/28 18:54:36  Dr.C
-- Debugged phase value.
--
-- Revision 1.3  2003/03/28 18:00:29  Dr.C
-- Updated first_symbol signal value.
--
-- Revision 1.2  2003/03/28 13:25:19  Dr.C
-- Added saturation.
--
-- Revision 1.1  2003/03/27 09:10:39  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library cordic_rtl;
library work;

--library ramp_phase_rot_rtl;
library work;
--use ramp_phase_rot_rtl.ramp_phase_rot_pkg.all;
use work.ramp_phase_rot_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity ramp_phase_rot is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n           : in  std_logic;
    sync_reset_n      : in  std_logic;
    clk               : in  std_logic;
    --------------------------------------
    -- Phase calculation
    --------------------------------------
    cpe_i             : in  std_logic_vector(16 downto 0);
    sto_i             : in  std_logic_vector(16 downto 0);
    --------------------------------------
    -- Flow controls
    --------------------------------------
    -- from pilots tracking
    estimate_done_i   : in  std_logic;
    signal_valid_i    : in  std_logic;
    -- from serialyzer
    pilot_valid_i     : in  std_logic;
    data_valid_i      : in  std_logic;
    start_of_burst_i  : in  std_logic;
    start_of_symbol_i : in  std_logic;
    -- from equalyzer
    data_ready_i      : in  std_logic;
    --
    -- to serialyzer
    data_ready_o      : out std_logic;
    -- to equalizer
    data_valid_o      : out std_logic;
    start_of_burst_o  : out std_logic;
    start_of_symbol_o : out std_logic;
    --------------------------------------
    -- Data
    --------------------------------------
    data_i_i          : in  std_logic_vector(11 downto 0);
    data_q_i          : in  std_logic_vector(11 downto 0);
    --
    data_i_o          : out std_logic_vector(11 downto 0);
    data_q_o          : out std_logic_vector(11 downto 0)
    );

end ramp_phase_rot;
