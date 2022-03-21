--------------------------------------------------------------------------------
--       ------------      Project : GoodLuck Package
--    ,' GoodLuck ,'      RCSfile: dec_sr_e_i.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Decrementer with synchronous reset, enable and final count 
--               interrupt.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/packages/commonlib/vhdl/rtl/dec_sr_e_i.vhd,v  
--  Log: dec_sr_e_i.vhd,v  
-- Revision 1.3  2001/12/06 09:18:45  Dr.J
-- Added description and project name
--
-- Revision 1.2  2000/01/26 13:04:10  Dr.F
-- reordered interface.
--
-- Revision 1.1  2000/01/26 12:21:14  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

--library CommonLib;
library work;
--use CommonLib.slv_pkg.all;
use work.slv_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity dec_sr_e_i is
  generic ( depth_g        : integer := 4);
  port ( reset_n           :  in slv1;
         clk               :  in slv1;
         sreset            :  in slv1;
         enable            :  in slv1;
         maxval            :  in std_logic_vector(depth_g-1 downto 0);
         termint           : out slv1;
         q                 : out std_logic_vector(depth_g-1 downto 0)
       );
end dec_sr_e_i;
