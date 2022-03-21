
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Euclidean Divider
--    ,' GoodLuck ,'      RCSfile: eucl_divider.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Euclidean divider. Takes two positive input in 2's complement
--               and gives out the quotient with one more precision bit (0).
--               Can be divided into up to three pipeline stages.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/NLWARE/DSP/eucl_divider/vhdl/rtl/eucl_divider.vhd,v  
--  Log: eucl_divider.vhd,v  
-- Revision 1.6  2004/11/17 13:48:38  sbizet
-- #BugId:844#
-- Pipeline stages divisors MSB initialized to '1' to avoid
-- division by 0 at reset
--
-- Revision 1.5  2003/12/03 18:16:45  Dr.A
-- Added stage 4.
--
-- Revision 1.4  2003/08/25 17:23:04  Dr.A
-- Debugged z_ff2 and z_ff3.
--
-- Revision 1.3  2003/06/25 07:43:53  Dr.C
-- Modified code to be Synopsys compliant
--
-- Revision 1.2  2003/04/24 15:48:22  Dr.A
-- Added pipeline of q_sign.
--
-- Revision 1.1  2003/04/24 07:34:27  Dr.A
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
entity eucl_divider is
  generic (
    -- The qsizen_g generics define the part of qsize_g computed in each divider
    -- pipeline stage.
    qsize1_g : integer := 9;  -- 1st stage computes q_out(qsize_g : qsize1_g)
    qsize2_g : integer := 6;  -- 2nd stage computes q_out(qsize_g1-1 : qsize2_g)
    qsize3_g : integer := 3;  -- 3rd stage computes q_out(qsize_g2-1 : qsize3_g)
    qsize4_g : integer := 0;  -- 4th stage computes q_out(qsize_g3-1 : qsize4_g)
    qsize5_g : integer := 0;  -- 5th stage computes q_out(qsize_g4-1 : qsize5_g)
    zsize_g  : integer := 12; -- Dividend size.
    dsize_g  : integer := 8;  -- Divisor size.
    -- qsize_g min = zsize_g. q_out integer part is zsize_g upper bits.
    qsize_g  : integer := 12  -- Quotient size. 
    );
  port (
    reset_n  : in  std_logic; -- Asynchronous reset.
    clk      : in  std_logic; -- System clock.
    --
    z_in     : in  std_logic_vector(zsize_g-1 downto 0); -- Dividend.
    d_in     : in  std_logic_vector(dsize_g-1 downto 0); -- Divisor.
    q_sign   : in  std_logic; -- High if quotient must be inverted.
    -- Quotient output from the different pipeline stages:
    q_out0   : out std_logic_vector(qsize_g downto 0); -- from stage 0.
    q_out1   : out std_logic_vector(qsize_g downto 0); -- from stage 1.
    q_out2   : out std_logic_vector(qsize_g downto 0); -- from stage 2.
    q_out3   : out std_logic_vector(qsize_g downto 0); -- from stage 3.
    q_out4   : out std_logic_vector(qsize_g downto 0); -- from stage 4.
    -- Quotient sign from the different pipeline stages:
    q_sign0  : out std_logic; -- from stage 0.
    q_sign1  : out std_logic; -- from stage 1.
    q_sign2  : out std_logic; -- from stage 2.
    q_sign3  : out std_logic; -- from stage 3.
    q_sign4  : out std_logic  -- from stage 4.
  );

end eucl_divider;
