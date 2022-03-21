
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: channel_decoder.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.8  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : The Channel decoder does the deinterleaving, depunctering and
--               the viterbi decoding. Further, the channel decoder decodes the
--               signal field and provides the data contents of this field.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/channel_decoder.vhd,v  
--  Log: channel_decoder.vhd,v  
-- Revision 1.8  2004/12/14 17:47:49  Dr.C
-- #BugId:704#
-- Added unsupported length port.
--
-- Revision 1.7  2004/04/29 16:24:02  Dr.C
-- Updated short_reg_length_g of viterbi to 24 for correct end of signal decoding with tails bits.
--
-- Revision 1.6  2003/10/17 08:47:44  Dr.C
-- Updated generic of viterbi_boundary.
--
-- Revision 1.5  2003/05/16 16:45:30  Dr.J
-- Changed the type of field_length_i
--
-- Revision 1.4  2003/05/02 13:25:49  Dr.J
-- Used the NL viterbi
--
-- Revision 1.3  2003/03/28 15:36:56  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/26 08:47:25  Dr.F
-- removed smu_table_i port.
--
-- Revision 1.1  2003/03/24 10:17:41  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
 
--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library deintpun_rtl;
library work;
--library viterbi_rtl;
library work;

--library channel_decoder_rtl;
library work;
--use channel_decoder_rtl.channel_decoder_pkg.all;
use work.channel_decoder_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity channel_decoder is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;
    clk            : in  std_logic;
    sync_reset_n   : in  std_logic;

    --------------------------------------
    -- Interface Synchronization
    --------------------------------------
    data_valid_i   : in  std_logic;  -- Data valid from equalizer_softbit
    data_ready_i   : in  std_logic;  -- Data ready from descrambler
    --
    data_ready_o   : out std_logic;  -- Data ready to equalizer_softbit
    data_valid_o   : out std_logic;  -- Data valid to descrambler

    --------------------------------------
    -- Datapath interface
    --------------------------------------
    -- Softbits from equalizer_softbit
    soft_x0_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x1_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_x2_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y0_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y1_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y2_i      : in std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    --
    data_o         : out std_logic;  -- Decoded data to descambler

    --------------------------------------
    -- Control info interface
    --------------------------------------
    start_of_burst_i   : in std_logic;
    length_limit_i     : in std_logic_vector(11 downto 0);
    rx_length_chk_en_i : in  std_logic;
    --
    signal_field_o : out std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0);
    signal_field_parity_error_o       : out std_logic;
    signal_field_unsupported_rate_o   : out std_logic;
    signal_field_unsupported_length_o : out std_logic;
    signal_field_puncturing_mode_o    : out std_logic_vector(1 downto 0);
    signal_field_valid_o              : out std_logic;
    start_of_burst_o                  : out std_logic;
    end_of_data_o                     : out std_logic;

    --------------------------------------
    -- Debugging Ports
    --------------------------------------
    soft_x_deintpun_o     : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y_deintpun_o     : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    data_valid_deintpun_o : out std_logic  
  );

end channel_decoder;
