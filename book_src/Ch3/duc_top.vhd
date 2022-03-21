LIBRARY ieee; 
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL; 
use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_textio.all; 
use std.textio.all; 
--  Uncomment the following lines to use the declarations that are 
--  provided for instantiating Xilinx primitive components. 
--library UNISIM; 
--use UNISIM.VComponents.all; 
 
entity DUC is 
PORT ( 
	Clk 		: IN std_logic; 
	Rst			: IN std_logic; 
	 
	tx_I     : IN std_logic_vector(11 downto 0); 
	tx_Q     : IN std_logic_vector(11 downto 0); 
 
	FreqOffset	: in std_logic_vector (31 downto 0); 
	AmpI    : IN std_logic_vector(11 downto 0); 
	AmpQ    : IN std_logic_vector(11 downto 0); 
 
	DataOutI  : out std_logic_vector(15 downto 0); 
	DataOutQ  : out std_logic_vector(15 downto 0)); 
	 
end entity; 
 
architecture Behavioral of DUC is 
 
--SIGNAL ClkCnt   :std_logic_vector(2 downto 0); 
-- 
--signal RCosIReg : std_logic_vector(7 downto 0); 
--signal RCosQReg : std_logic_vector(7 downto 0); 
--signal RcosIAddr : std_logic_vector(10 downto 0); 
--signal RcosQAddr : std_logic_vector(10 downto 0); 
--signal RCosIOut : std_logic_vector(15 downto 0); 
--signal RCosQOut : std_logic_vector(15 downto 0); 
--component tx_rcos_rom 
--	port ( 
--	addr: IN std_logic_VECTOR(10 downto 0); 
--	clk: IN std_logic; 
--	dout: OUT std_logic_VECTOR(15 downto 0)); 
--END component; 
 
signal MulInI : std_logic_vector(15 downto 0); 
signal HAmpI : std_logic_vector(12 downto 0); 
signal MulOutI : std_logic_vector(28 downto 0); 
signal MulInQ : std_logic_vector(15 downto 0); 
signal HAmpQ : std_logic_vector(12 downto 0); 
signal MulOutQ : std_logic_vector(28 downto 0); 
 
component mul_amp 
   port ( A_IN   : in    std_logic_vector (15 downto 0);  
          B_IN   : in    std_logic_vector (12 downto 0);  
			 CARRYIN_IN : in std_logic; 
          CLK_IN : in    std_logic;  
          P_OUT  : out   std_logic_vector (28 downto 0)); 
end component; 
 
 
SIGNAL sin      : std_logic_vector(13 downto 0); 
SIGNAL cos      : std_logic_vector(13 downto 0); 
SIGNAL NCOCnt  : std_logic_vector(31 downto 0); 
component nco_sinetab 
PORT 	( 
	THETA: IN std_logic_VECTOR(9 downto 0); 
	CLK: IN std_logic; 
	SINE: OUT std_logic_VECTOR(13 downto 0); 
	COSINE: OUT std_logic_VECTOR(13 downto 0)); 
end component; 
 
 
COMPONENT tx_halfband_compmul 
PORT( 
	Clk : IN std_logic; 
	In_En : IN std_logic; 
	I1 : IN std_logic_vector(15 downto 0); 
	Q1 : IN std_logic_vector(15 downto 0); 
	I2 : IN std_logic_vector(13 downto 0); 
	Q2 : IN std_logic_vector(13 downto 0);           
	Out_En : OUT std_logic; 
	ReRes : OUT std_logic_vector(15 downto 0); 
	ImRes : OUT std_logic_vector(15 downto 0) 
	); 
END COMPONENT; 
 
signal DataItp,DataQtp : std_logic_vector(15 downto 0); 
 
 
begin 
 
--begin 
-- 
--process(Clk, Rst)	     
--begin 
--	if ( Rst = '1') then 
--	elsif (Clk'event and Clk='1') then 
--		if En = '1' then 
--			if ( InBitEn = '1' ) then 
--				ClkCnt <= (others=>'0'); 
--			else 
--				ClkCnt<=ClkCnt+1;		 
--			end if; 
--		else 
--			ClkCnt <= (others=>'0'); 
--		end if; 
--	end if; 
--end process; 
 
--process( Clk, Rst)	   
--begin   
--	if (Rst='1') then 
--		RCosIReg <= (others=>'0'); 
--		RCosQReg <= (others=>'0'); 
--	elsif (Clk'event and Clk='1') then 
--		if En = '1' then 
--			if ( InBitEn ='1') then 
--				RCosIReg <= RCosIReg (6 downto 0) & InBitI; 
--				RCosQReg <= RCosQReg (6 downto 0) & InBitQ; 
--			end if; 
--		end if; 
--	end if; 
--end process; 
 
--RcosIAddr <= RCosIReg & ClkCnt(2 downto 0); 
--RcosQAddr <= RCosQReg & ClkCnt(2 downto 0); 
-- 
--Rcos_Rom_I : tx_rcos_rom PORT MAP ( 
--	addr => RcosIAddr, 
--	clk  => Clk, 
--	dout => RCosIOut); 
--Rcos_Rom_Q : tx_rcos_rom PORT MAP ( 
--	addr => RcosQAddr, 
--	clk  => Clk, 
--	dout => RCosQOut); 
 
--MulInI <= RCosIOut when ModEnI = '1' else X"7fff"; 
--MulInQ <= RCosQOut when ModEnQ = '1' else X"7fff"; 
 
MulInI <= tx_I & "0000"; 
MulInQ <= tx_Q & "0000"; 
HAmpI <= '0'&AmpI; 
HAmpQ <= '0'&AmpQ; 
amp_mul_I : mul_amp PORT MAP ( 
		A_IN => MulInI, 
		B_IN => HAmpI, 
		CARRYIN_IN => '0', 
		CLK_IN => Clk, 
		P_OUT => MulOutI); 
amp_mul_Q : mul_amp PORT MAP ( 
		A_IN => MulInQ, 
		B_IN => HAmpQ, 
		CARRYIN_IN => '0', 
		CLK_IN => Clk, 
		P_OUT => MulOutQ); 
 
process (Clk, Rst) 
begin 
	if (Rst='1') then 
		NCOCnt <= (others=>'0'); 
	elsif (Clk'event and Clk='1') then 
			NCOCnt <= NCOCnt+FreqOffset; 
	end if; 
end process; 
 
sintab : nco_sinetab PORT MAP( 
	THETA=>NCOCnt(31 downto 22), 
	CLK => Clk, 
	SINE=> sin, 
	COSINE=>cos 
	); 
 
 
NCO_mul : Tx_Halfband_Compmul	 PORT MAP(  
      Clk    =>Clk, 
	  In_En  =>'1', 
	  I1     =>MulOutI(27 downto 12), --HBOut_Itp, 
	  I2     =>cos, 
	  Q1     =>MulOutQ(27 downto 12), 
	  Q2     =>sin, 
	  ReRes  =>DataItp,   
	  ImRes  =>DataQtp); 
 
--Process(Clk) 
--Begin 
--	if Clk'event and Clk = '1' then 
		DataOutI <= DataItp; 
		DataOutQ <= DataQtp; 
--	end if; 
--end process; 
 
 
end Behavioral; 