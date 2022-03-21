

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of mapping is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal phi_last       : std_logic_vector (1 downto 0); 
  --                      last value of phi_map
  signal phi_map_i      : std_logic_vector (1 downto 0); 
  --                      phi_map
  signal delta_phi      : std_logic_vector (1 downto 0); 
  --                      input reversed.

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  ------------------------------------------------------------------------------
  -- Delta_phi definition
  --
  --   delta_phi =   [map_in(0) | map_in(1)]  
  --  the bit order is reversed in the delta_phi generation. This is done to 
  --  conform to the 802.11 specifications.
  ------------------------------------------------------------------------------
  delta_phi(0) <= map_in(1);
  delta_phi(1) <= map_in(0);

  ------------------------------------------------------------------------------
  -- Phi Value Process
  --
  --   [map_in(0) | map_in(1)] ----------|
  --                                     |
  --                                    \/
  --               phi_last----------->(.)----> phi_map
  --                  /\               |
  --                  |---------------- 
  --
  ------------------------------------------------------------------------------

  phi_value_proc: process (clk, resetn)                              
  begin                                                              
    if resetn= '0' then                                              
      phi_last <= "00";                                              
    elsif (clk'event and clk='1') then                               
      if map_activate= '1' then                                            
        if map_first_val = '1' then -- the first value is sent  =>   
          -- phi_last (1) = 00            
          phi_last <= "00";                                     
        elsif shift_mapping = '1' then
          phi_last <= phi_map_i;          
        end if;                                                      
      end if;                                                        
    end if;                                                          
  end process; 


  phi_map_i <= angle_add (phi_last,delta_phi);  
  phi_map   <= phi_map_i; 
                                              
end RTL;
