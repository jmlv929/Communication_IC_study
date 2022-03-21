

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: biggest_picker_4.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block selects the input where max(max(|re|,|im|)) has been
--             found among the 4 inputs. The index corresponding to this input is
--             also provided.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/biggest_picker/vhdl/rtl/biggest_picker_4.vhd,v  
--  Log: biggest_picker_4.vhd,v  
-- Revision 1.3  2002/11/08 13:17:43  Dr.F
-- removed reset_n and clk ports.
--
-- Revision 1.2  2002/06/14 06:18:46  Dr.F
-- beautified for code checker.
--
-- Revision 1.1  2002/06/10 09:19:00  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--library biggest_picker_rtl;
library work;
--use biggest_picker_rtl.biggest_picker_pkg.all;
use work.biggest_picker_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity biggest_picker_4 is
  generic (
    data_length_g : integer := 16        -- Number of bits for data I/O ports.
  );
  port (
          input0_re   : in  std_logic_vector (data_length_g-1 downto 0);
          input0_im   : in  std_logic_vector (data_length_g-1 downto 0);
          input1_re   : in  std_logic_vector (data_length_g-1 downto 0);
          input1_im   : in  std_logic_vector (data_length_g-1 downto 0);
          input2_re   : in  std_logic_vector (data_length_g-1 downto 0);
          input2_im   : in  std_logic_vector (data_length_g-1 downto 0);
          input3_re   : in  std_logic_vector (data_length_g-1 downto 0);
          input3_im   : in  std_logic_vector (data_length_g-1 downto 0);

          output_re   : out std_logic_vector (data_length_g-1 downto 0);--R part of out.
          output_im   : out std_logic_vector (data_length_g-1 downto 0);--Im part of out.
          index       : out std_logic_vector (1 downto 0)
  );        
end biggest_picker_4;
