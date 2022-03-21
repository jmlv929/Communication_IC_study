
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 
--Library XilinxCoreLib; 
 
--  Uncomment the following lines to use the declarations that are 
--  provided for instantiating Xilinx primitive components. 
 
 
entity Tx_Halfband_Compmul is 
port (  
      Clk    :        in std_logic; 
	  In_En  :        in std_logic; 
	  Out_En :        out std_logic; 
	  I1     :        in std_logic_vector(15 downto 0); 
	  Q1     :        in std_logic_vector(15 downto 0); 
	  I2     :        in std_logic_vector(13 downto 0); 
	  Q2     :        in std_logic_vector(13 downto 0); 
	  ReRes  :        out std_logic_vector(15 downto 0);   
	  ImRes  :        out std_logic_vector(15 downto 0)); 
end Tx_Halfband_Compmul; 
 
architecture Behavioral of Tx_Halfband_Compmul is 
 
signal cin_add, cin_sub 	: std_logic_vector(47 downto 0); 
signal ReRes_Tp,ImRes_Tp : std_logic_vector(47 downto 0); 
 
component comp_mul 
   port ( A_IN      : in    std_logic_vector (15 downto 0);  
          B_IN      : in    std_logic_vector (13 downto 0);  
          CEM_IN    : in    std_logic;  
          CLK_IN    : in    std_logic;  
          C_IN      : in    std_logic_vector (47 downto 0);  
          PCOUT_OUT : out   std_logic_vector (47 downto 0);  
          P_OUT     : out   std_logic_vector (47 downto 0)); 
end component; 
 
 
component comp_mul_add 
   port ( A_IN    : in    std_logic_vector (15 downto 0);  
          B_IN    : in    std_logic_vector (13 downto 0);  
          CEM_IN  : in    std_logic;  
          CLK_IN  : in    std_logic;  
          PCIN_IN : in    std_logic_vector (47 downto 0);  
          P_OUT   : out   std_logic_vector (47 downto 0)); 
end component; 
 
component comp_mul_sub 
   port ( A_IN    : in    std_logic_vector (15 downto 0);  
          B_IN    : in    std_logic_vector (13 downto 0);  
          CEM_IN  : in    std_logic;  
          CLK_IN  : in    std_logic;  
          PCIN_IN : in    std_logic_vector (47 downto 0);  
          P_OUT   : out   std_logic_vector (47 downto 0)); 
end component; 
 
begin 
 
ReRes <= ReRes_Tp(27 downto 12); 
ImRes <= ImRes_Tp(27 downto 12); 
--ReRes <= ReRes_Tp(28 downto 13); 
--ImRes <= ImRes_Tp(28 downto 13); 
 
 
   mul_I1I2:    comp_mul 
   PORT MAP (  
   		A_IN=>I1,  
          B_IN=>I2,  
          CEM_IN => In_En, 
          CLK_IN=>Clk,  
		  C_IN => (others=>'0'), 
          PCOUT_OUT=>cin_sub 
		); 
  
   mul_I1Q2:    comp_mul 
   PORT MAP ( 
   		A_IN=>I1,  
          B_IN=>Q2,  
          CEM_IN => In_En, 
          CLK_IN=>Clk,  
		  C_IN => (others=>'0'), 
          PCOUT_OUT=>cin_add 
		); 
 
    mulsub:   comp_mul_sub 
   PORT MAP ( A_IN=> Q1,  
          B_IN=> Q2, 
          CEM_IN => In_En, 
          CLK_IN=> Clk,  
          PCIN_IN=> cin_sub,  
          P_OUT=>ReRes_Tp); 
 
	muladd:   comp_mul_add 
   PORT MAP ( A_IN=>Q1,  
          B_IN=>I2, 
          CEM_IN => In_En, 
          CLK_IN=>Clk,  
          PCIN_IN=>cin_add,  
          P_OUT=>ImRes_Tp); 
 
 
process ( Clk ) 
begin 
	if (Clk'event and Clk='1') then 
		Out_En<=In_En; 
	end if; 
end process;		 
 
end Behavioral;
