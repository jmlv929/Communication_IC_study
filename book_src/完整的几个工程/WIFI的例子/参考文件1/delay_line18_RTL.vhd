

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of delay_line18 is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Registers for delay line
  signal data_ff0_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff1_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff2_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff3_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff4_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff5_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff6_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff7_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff8_int   : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff9_int   : std_logic_vector(dsize_g-1 downto 0);  

  signal data_ff10_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff11_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff12_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff13_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff14_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff15_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff16_int  : std_logic_vector(dsize_g-1 downto 0);  
  signal data_ff17_int  : std_logic_vector(dsize_g-1 downto 0);  


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Delay line, at half the clock frequency.
  shift_pr: process (reset_n, clk)
  begin
    if reset_n = '0' then
      data_ff0_int   <= (others => '0');
      data_ff1_int   <= (others => '0');
      data_ff2_int   <= (others => '0');
      data_ff3_int   <= (others => '0');
      data_ff4_int   <= (others => '0');
      data_ff5_int   <= (others => '0');
      data_ff6_int   <= (others => '0');
      data_ff7_int   <= (others => '0');
      data_ff8_int   <= (others => '0');
      data_ff9_int   <= (others => '0');
      
      data_ff10_int  <= (others => '0');
      data_ff11_int  <= (others => '0');
      data_ff12_int  <= (others => '0');
      data_ff13_int  <= (others => '0');
      data_ff14_int  <= (others => '0');
      data_ff15_int  <= (others => '0');
      data_ff16_int  <= (others => '0');
      data_ff17_int  <= (others => '0');
      
    elsif clk'event and clk = '1' then
      if shift = '1' then
        data_ff0_int  <= data_in;       -- Store new value.
        data_ff1_int  <= data_ff0_int;  -- Shift all others registers.
        data_ff2_int  <= data_ff1_int;     
        data_ff3_int  <= data_ff2_int;
        data_ff4_int  <= data_ff3_int;
        data_ff5_int  <= data_ff4_int;
        data_ff6_int  <= data_ff5_int;
        data_ff7_int  <= data_ff6_int;
        data_ff8_int  <= data_ff7_int;
        data_ff9_int  <= data_ff8_int;
                                 
        data_ff10_int  <= data_ff9_int; 
        data_ff11_int  <= data_ff10_int;
        data_ff12_int  <= data_ff11_int;
        data_ff13_int  <= data_ff12_int;
        data_ff14_int  <= data_ff13_int;
        data_ff15_int  <= data_ff14_int;
        data_ff16_int  <= data_ff15_int;
        data_ff17_int  <= data_ff16_int;
        
      end if;
    end if;
  end process shift_pr;
  
  -- Assign outputs.
  data_ff0  <= data_ff0_int; 
  data_ff1  <= data_ff1_int; 
  data_ff2  <= data_ff2_int; 
  data_ff3  <= data_ff3_int; 
  data_ff4  <= data_ff4_int; 
  data_ff5  <= data_ff5_int; 
  data_ff6  <= data_ff6_int; 
  data_ff7  <= data_ff7_int; 
  data_ff8  <= data_ff8_int; 
  data_ff9  <= data_ff9_int; 

  data_ff10 <= data_ff10_int;
  data_ff11 <= data_ff11_int;
  data_ff12 <= data_ff12_int;
  data_ff13 <= data_ff13_int;
  data_ff14 <= data_ff14_int;
  data_ff15 <= data_ff15_int;
  data_ff16 <= data_ff16_int;
  data_ff17 <= data_ff17_int;
  

end RTL;
