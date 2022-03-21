
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: str_proc_control.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.9   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Controls for the Stream Processor.
--               Contains the state machine and the mux/decode logic between
--               RC4 and AES signals.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/stream_processor/vhdl/rtl/str_proc_control.vhd,v  
--  Log: str_proc_control.vhd,v  
-- Revision 1.9  2003/12/04 09:57:38  Dr.A
-- Added registers to ease synthesis.
--
-- Revision 1.8  2003/11/12 16:32:20  Dr.A
-- Changes for big endain interface: added acctype control signal.
-- Grouped bursts by access type for control structure accesses.
--
-- Revision 1.7  2003/10/13 16:38:54  Dr.A
-- Register for state_number.
--
-- Revision 1.6  2003/10/07 14:45:52  Dr.A
-- firstpack and lastpack read from control structure only in TKIP mode.
--
-- Revision 1.5  2003/09/23 14:08:40  Dr.A
-- Added read_done_dly and state_number. Debuged control structure read (use of cryptmode).
--
-- Revision 1.4  2003/08/28 15:23:28  Dr.A
-- Changed bsize length.
--
-- Revision 1.3  2003/08/13 16:24:48  Dr.A
-- Removed unused write control signals.
--
-- Revision 1.2  2003/07/16 13:42:49  Dr.A
-- Updated for version 0.09.
--
-- Revision 1.1  2003/07/03 14:39:26  Dr.A
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
 
--library endianness_converter_rtl;
library work;
--use endianness_converter_rtl.endianness_converter_pkg.ALL;
use work.endianness_converter_pkg.ALL;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity str_proc_control is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk             : in  std_logic; -- AHB and APB clock.
    reset_n         : in  std_logic; -- AHB and APB reset. Inverted logic.
    --------------------------------------
    -- Registers interface
    --------------------------------------
    startop         : in  std_logic; -- Pulse that starts the en/decryption.
    stopop          : in  std_logic; -- Pulse that stops the en/decryption.
    --
    process_done    : out std_logic; -- Pulse indicating en/decryption finished.
    mic_int         : out std_logic; -- Interrupt on MIC error.
    --------------------------------------
    -- RC4 Control lines
    --------------------------------------
    rc4_process_done: in  std_logic; -- Pulse indicating RC4 finished.
    rc4_start_read  : in  std_logic; -- Starts read sequence for the RC4.
    rc4_read_size   : in  std_logic_vector( 3 downto 0);  -- Read size.
    rc4_read_addr   : in  std_logic_vector(31 downto 0);  -- Read address.
    rc4_start_write : in  std_logic; -- Starts write sequence for the RC4.
    rc4_write_size  : in  std_logic_vector( 3 downto 0);  -- Write size.
    rc4_write_addr  : in  std_logic_vector(31 downto 0);  -- Write address.
    rc4_mic_int     : in  std_logic; -- Interrupt on RC4-TKIP MIC error.
    --
    rc4_startop     : out std_logic; -- Pulse to launch RC4 algorithm.
    --------------------------------------
    -- AES Control lines
    --------------------------------------
    aes_process_done: in  std_logic; -- Pulse indicating AES finished.
    aes_start_read  : in  std_logic; -- Starts read sequence for the AES.
    aes_read_size   : in  std_logic_vector( 3 downto 0);  -- Size of read data.
    aes_read_addr   : in  std_logic_vector(31 downto 0);  -- Read address.
    aes_start_write : in  std_logic; -- Positive edge starts AHB write.
    aes_write_size  : in  std_logic_vector( 3 downto 0);  -- Size of write data
    aes_write_addr  : in  std_logic_vector(31 downto 0);  -- Write address.
    aes_mic_int     : in  std_logic; -- Interrupt on AES-CCMP MIC error.
    --
    aes_startop     : out std_logic; -- Pulse to launch AES algorithm.
    --------------------------------------
    -- AHB interface control lines
    --------------------------------------
    read_done       : in  std_logic; -- AHB read done.
    --
    start_read      : out std_logic; -- Positive edge starts AHB read.
    read_size       : out std_logic_vector( 3 downto 0); -- Size of data to read
    read_addr       : out std_logic_vector(31 downto 0); -- Read address.
    read_done_dly   : out std_logic; -- AHB read done delayed by one clk cycle.
    start_write     : out std_logic; -- Positive edge starts AHB write.
    write_size      : out std_logic_vector( 3 downto 0); -- Size of data to write
    write_addr      : out std_logic_vector(31 downto 0); -- Write address.
    --------------------------------------
    -- Endianness controls
    --------------------------------------
    -- Type of data accessed: word, halfword, byte, for endian converter.
    acctype         : out std_logic_vector( 1 downto 0);
    --------------------------------------
    -- Data lines
    --------------------------------------
    -- Data read on the AHB.
    read_word0      : in  std_logic_vector(31 downto 0);
    read_word1      : in  std_logic_vector(31 downto 0);
    read_word2      : in  std_logic_vector(31 downto 0);
    read_word3      : in  std_logic_vector(31 downto 0);
    -- RC4 encryption / decryption result or data to write.
    rc4_result_w0   : in  std_logic_vector(31 downto 0); -- RC4 result word 0.
    rc4_result_w1   : in  std_logic_vector(31 downto 0); -- RC4 result word 1.
    rc4_result_w2   : in  std_logic_vector(31 downto 0); -- RC4 result word 2.
    rc4_result_w3   : in  std_logic_vector(31 downto 0); -- RC4 result word 3.
    -- AES encryption / decryption result or data to write.
    aes_result_w0   : in  std_logic_vector(31 downto 0); -- AES Result word 0.
    aes_result_w1   : in  std_logic_vector(31 downto 0); -- AES Result word 1.
    aes_result_w2   : in  std_logic_vector(31 downto 0); -- AES Result word 2.
    aes_result_w3   : in  std_logic_vector(31 downto 0); -- AES Result word 3.
    -- Encryption / decryption result or data to write to AHB interface.
    result_w0       : out std_logic_vector(31 downto 0); -- Result word 0.
    result_w1       : out std_logic_vector(31 downto 0); -- Result word 1.
    result_w2       : out std_logic_vector(31 downto 0); -- Result word 2.
    result_w3       : out std_logic_vector(31 downto 0); -- Result word 3.
    --------------------------------------
    -- Control structure
    --------------------------------------
    -- Address of control structure.
    strpcsaddr      : in  std_logic_vector(31 downto 0);
    --
    rc4_firstpack   : out std_logic;
    rc4_lastpack    : out std_logic;
    opmode          : out std_logic;
    priority        : out std_logic_vector( 7 downto 0);
    strpksize       : out std_logic_vector( 7 downto 0); -- Key size in bytes.
    aes_msize       : out std_logic_vector( 5 downto 0); -- MAC size in bytes.
    strpbsize       : out std_logic_vector(15 downto 0); -- data buffer size.
    state_number    : out std_logic_vector(12 downto 0); -- Nb of 16-byte states
    -- Address of source data.
    strpsaddr       : out std_logic_vector(31 downto 0);
    -- Address of destination data.
    strpdaddr       : out std_logic_vector(31 downto 0);
    strpmaddr       : out std_logic_vector(31 downto 0);
    michael_w0      : out std_logic_vector(31 downto 0);
    michael_w1      : out std_logic_vector(31 downto 0);
    packet_num      : out std_logic_vector(47 downto 0);
    enablecrypt     : out std_logic;   -- Enables (1) or disable (0) encryption
    enablecrc       : out std_logic;   -- Enables (1) or disables CRC operation
    enablemic       : out std_logic;   -- Enables (1) or disables MIC operation
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    ctrl_diag       : out std_logic_vector(7 downto 0)

  );

end str_proc_control;
