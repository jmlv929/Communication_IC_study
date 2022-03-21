

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: biggest_picker.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block selects the input where max(max(|re|,|im|)) has been
--             found among 64 inputs. In fact, only 4 inputs are given at the
--             same time. Thus, the processing is performed 16 times serialy.
--             At the end, the right input is selected among the 16*4 provided.
--             The index corresponding to this input is also provided.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/biggest_picker/vhdl/rtl/biggest_picker.vhd,v  
--  Log: biggest_picker.vhd,v  
-- Revision 1.4  2002/11/08 13:17:54  Dr.F
-- biggest_picker_4 port map changed.
--
-- Revision 1.3  2002/09/18 15:26:48  Dr.J
-- CCK 5.5 debugged
--
-- Revision 1.2  2002/06/14 06:19:01  Dr.F
-- added support of CCK 5.5Mb/s rate.
--
-- Revision 1.1  2002/06/10 09:18:56  Dr.F
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
entity biggest_picker is
  generic (
    data_length_g : integer := 16            -- Number of bits for data I/O ports.
  );
  port (
          reset_n     : in  std_logic;
          clk         : in  std_logic;
          start_picker: in  std_logic;
          cck_rate    : in  std_logic; -- CCK rate. 0: 5.5Mb/s ; 1: 11Mb/s
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
          index       : out std_logic_vector (5 downto 0);
          valid_symbol: out std_logic
  );        
end biggest_picker;
