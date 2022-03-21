
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: qerr_mult.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Multiply conjugate of complex data by the quantized error.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/qerr_mult.vhd,v  
--  Log: qerr_mult.vhd,v  
-- Revision 1.3  2002/06/27 16:19:34  Dr.B
-- comments added.
--
-- Revision 1.2  2002/05/07 16:56:31  Dr.A
-- Take input conjugate inside the block.
--
-- Revision 1.1  2002/03/28 13:49:12  Dr.A
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
use ieee.std_logic_arith.all;

--library equalizer_rtl;
library work;
--use equalizer_rtl.equalizer_pkg.all;
use work.equalizer_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity qerr_mult is
  generic (
    dsize_g : integer := 6 -- Data size
  );
  port (
    data_in_re     : in  std_logic_vector(dsize_g-1 downto 0);
    data_in_im     : in  std_logic_vector(dsize_g-1 downto 0);
    error_quant    : in  std_logic_vector(1 downto 0);
    --
    -- the addition does not need an extra extended bit (data calibrated)
    data_out_re    : out std_logic_vector(dsize_g downto 0);  
    data_out_im    : out std_logic_vector(dsize_g downto 0)
  );

end qerr_mult;
