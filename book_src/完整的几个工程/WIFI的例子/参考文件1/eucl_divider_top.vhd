
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Euclidean Divider
--    ,' GoodLuck ,'      RCSfile: eucl_divider_top.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Configurable euclidean divider:
--                - Optimized to accepts signed or unsigned inputs.
--                - Number of pipeline stages set by generic.
--                - The division result is valid every clock cycle with a
--               latency depending on the pipeline size.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/eucl_divider/vhdl/rtl/eucl_divider_top.vhd,v  
--  Log: eucl_divider_top.vhd,v  
-- Revision 1.6  2003/12/03 18:15:22  Dr.A
-- Added stage 4 and register before saturation.
--
-- Revision 1.5  2003/12/03 13:44:21  Dr.A
-- Revert to previous version.
--
-- Revision 1.4  2003/12/02 18:27:16  Dr.A
-- Registered output.
--
-- Revision 1.3  2003/06/25 07:44:22  Dr.C
-- Modified code to be Synopsys compliant
--
-- Revision 1.2  2003/04/24 15:48:42  Dr.A
-- Added pipeline on q_sign.
--
-- Revision 1.1  2003/04/24 07:35:30  Dr.A
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
use IEEE.STD_LOGIC_ARITH.ALL; 
 
--library eucl_divider_rtl;
library work;
--use eucl_divider_rtl.eucl_divider_pkg.all;
use work.eucl_divider_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity eucl_divider_top is
  generic (
    nb_stage_g : integer := 2;  -- Pipeline stages in the divider (0 to 3).
    dsize_g    : integer := 7;  -- Number of bits for d_in.
    zsize_g    : integer := 12; -- Number of bits for z_in.
    -- q_out integer part is q_out(qsize_g-1 downto qsize_g-zsize_g)
    -- Warning! qsize_g must be >= zsize_g!!
    qsize_g    : integer := 12; -- Number of bits for q_out.
    -- The *_neg_g generics indicates if the corresponding input is positive
    -- (*_neg_g=0) or in 2's complement code (*_neg_g=1).
    -- Warning! The configuration z_neg_g = 0 and d_neg_g = 1 is not allowed!!
    d_neg_g    : integer := 0;  -- 1 if d is in 2's complement code.
    z_neg_g    : integer := 1   -- 1 if z is in 2's complement code.
    );
  port (
    reset_n    : in  std_logic; -- Asynchronous reset.
    clk        : in  std_logic; -- System clock.
    --
    z_in       : in  std_logic_vector(zsize_g-1 downto 0); -- Dividend.
    d_in       : in  std_logic_vector(dsize_g-1 downto 0); -- Divisor.
    --
    q_out      : out std_logic_vector(qsize_g-1 downto 0)  -- Quotient.
  );

end eucl_divider_top;
