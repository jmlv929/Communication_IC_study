
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: channel_decoder_control.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.8  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Control of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/channel_decoder_control.vhd,v  
--  Log: channel_decoder_control.vhd,v  
-- Revision 1.8  2005/03/23 09:00:21  Dr.C
-- #BugId:704#
-- Re-init control_next_state when unsupported_length.
--
-- Revision 1.7  2005/03/04 10:32:04  Dr.C
-- #BugId:1119#
-- Updated MAX_LENGTH_DECODE_CT to 4095.
--
-- Revision 1.6  2004/12/14 17:47:55  Dr.C
-- #BugId:704#
-- Added unsupported length port.
--
-- Revision 1.5  2003/05/16 16:45:51  Dr.J
-- Changed the type of field_length_i
--
-- Revision 1.4  2003/03/31 12:48:02  Dr.C
-- Added unsigned library.
--
-- Revision 1.3  2003/03/31 12:18:37  Dr.C
-- Updated constants.
--
-- Revision 1.2  2003/03/28 15:37:03  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/24 10:17:43  Dr.C
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

 
--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity channel_decoder_control is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n               : in  std_logic;  -- Async Reset
    clk                   : in  std_logic;  -- Clock
    sync_reset_n          : in  std_logic;  -- Software reset

    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    start_of_burst_i      : in  std_logic;  -- Initialization signal
    signal_field_valid_i  : in  std_logic;  -- Signal field ready
    end_of_data_i         : in  std_logic;  -- Data field ready
    data_ready_deintpun_i : in  std_logic;  -- Data ready signal
    --
    start_of_field_o      : out std_logic;  -- Init submodules
    signal_field_valid_o  : out std_logic;  -- Signal field valid
    data_ready_o          : out std_logic;  -- Data ready signal

    --------------------------------------
    -- Enable Signals
    --------------------------------------
    enable_i             : in  std_logic;   -- incoming enable signal
    --
    enable_deintpun_o    : out std_logic;   -- enable for deintpun
    enable_viterbi_o     : out std_logic;   -- enable for viterbi
    enable_signal_o      : out std_logic;   -- enable for signal field decoding
    enable_data_o        : out std_logic;   -- enable for data output

    --------------------------------------
    -- Rgister Interface
    --------------------------------------
    length_limit_i       : in  std_logic_vector(11 downto 0);
    rx_length_chk_en_i   : in  std_logic;

    --------------------------------------
    -- Data Interface
    --------------------------------------
    signal_field_i    : in  std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0);
    smu_table_i       : in  std_logic_vector(15 downto 0);
    --
    smu_partition_o      : out std_logic_vector(1 downto 0);
    field_length_o       : out std_logic_vector(15 downto 0);
    qam_mode_o           : out std_logic_vector(1 downto 0);
    pun_mode_o           : out std_logic_vector(1 downto 0);
    parity_error_o       : out std_logic;
    unsupported_rate_o   : out std_logic;
    unsupported_length_o : out std_logic
  );

end channel_decoder_control;
