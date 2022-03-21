
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : 802.11b
--    ,' GoodLuck ,'      RCSfile: decode_path.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Decode Path - decode from data from PSK-Demapping (2 bits),
--               and data from CCK_demod.
--               - Perform differential decoding of data from PSK_demap
--               - Detect short or long preamble then synchronize deserializer
--               - Descramble (in serial mode at the beginning then in par)
--               - Deserialize according to the mode (DSSS 1/2 Mbs - CCK 5.5/11
--                 Mbs) and send the phy_data_ind to the Bup.
-- 
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/decode_path/vhdl/rtl/decode_path.vhd,v  
--  Log: decode_path.vhd,v  
-- Revision 1.8  2006/04/10 13:56:34  oringot
-- #BugId:2357#
-- o fixed problem in 11b with transmitter using wrong scrambler init
--
-- Revision 1.7  2004/08/24 13:45:34  arisse
-- Added globals for testbench.
--
-- Revision 1.6  2002/12/03 13:08:03  Dr.B
-- sfd_detect_enable added.
--
-- Revision 1.5  2002/09/25 16:36:48  Dr.B
-- cck_mode debug.
--
-- Revision 1.4  2002/09/17 07:22:04  Dr.B
-- descrambled short sfd detection added + port for diff_decoder.
--
-- Revision 1.3  2002/07/31 07:42:05  Dr.B
-- sfdlen added.
--
-- Revision 1.2  2002/07/09 15:53:01  Dr.B
-- sfd_comp activation changed.
--
-- Revision 1.1  2002/07/03 09:30:08  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;

--library diff_decoder_rtl;
library work;

--library scrambling_rtl;
library work;

--library sfd_comp_rtl;
library work;

--library deserializer_rtl;
library work;

--library decode_path_rtl;
library work;
--use decode_path_rtl.decode_path_pkg.all;
use work.decode_path_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity decode_path is
  port (
    ---------------------
    -- clocks and reset
    ---------------------
    clk     : in std_logic;
    reset_n : in std_logic;

    ---------------------
    -- inputs
    ---------------------
    -- data
    demap_data     : in std_logic_vector (1 downto 0);  -- data from demapping
    d_from_cck_dem : in std_logic_vector (5 downto 0);  -- data from cck_demod

    -- blocks activation
    decode_path_activate : in std_logic;
    diff_decod_first_val : in std_logic;  -- initialize the diff_decoder block when
    -- the first symbol is received
    -- (diff_decod_activate should be set).     

    -- control signals
    sfderr            : in std_logic_vector (2 downto 0);  -- allowed errs nb
    sfdlen            : in std_logic_vector (2 downto 0);  -- nb of pr sig analyzed
    symbol_sync       : in std_logic;
    sfd_detect_enable : in std_logic; -- allow sfd detection (when data are stable)
    rec_mode          : in std_logic_vector (1 downto 0);
    --                0=BPSK 1=QPSK 2=CCK5.5 3=CCK11
    scrambling_disb   : in std_logic;   -- disable the descr.when high 

    ---------------------
    -- outputs
    ---------------------
    sfd_found     : out std_logic;      -- short or long sfd found
    preamble_type : out std_logic;      -- 0 = short - 1 = long
    phy_data_ind  : out std_logic;
    data_to_bup   : out std_logic_vector ( 7 downto 0)

    );

end decode_path;
