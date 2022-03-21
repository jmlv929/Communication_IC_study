

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of spreading is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant BARKER_SEQ_CT : std_logic_vector (10 downto 0)  
                        := "01001000111"; --(right dibit first)
                        -- +1-1+1+1-1+1+1+1-1-1-1   (802.11 b spec)
                        
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal barker_int     : std_logic_vector (10 downto 0); 
  --                      internal barker reg.
  signal barker_operand : std_logic;
  --                      value to add with phi_map.
  signal phi_out_reg    : std_logic_vector (1 downto 0);
  --                      registered output.
   
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  --------------------------------------------
  -- Barker sequence Process + output
  --------------------------------------------
  barker_proc: process (clk, resetn)                              
  begin                                                              
    if resetn= '0' then                 -- reset barker reg.
      barker_int   <= BARKER_SEQ_CT;
      phi_out_reg  <= (others => '0');
    elsif (clk'event and clk='1') then                               
      if spread_activate= '1' then            -- if block activated
        if spread_disb = '1' then
          -- spreading disabled : output = phi_map registered
          phi_out_reg <= phi_map;
        else
          -- angle add : angle addition function (2 bits . 2 bits => 2 bits)
          -- phi_map (.) barker seq = phi_out 
          phi_out_reg <= angle_add_barker (barker_operand, phi_map);
        end if;
         
        -- registered output at each period.
        if spread_init = '1' then           -- if initialization asked 
          barker_int <= BARKER_SEQ_CT;  
        elsif shift_pulse = '1' then          
          barker_int <= barker_int(9 downto 0) & barker_int (10);
          -- rotative shift of barker sequence.
        end if;                                                      
      end if;                                                        
    end if;                                                          
  end process; 
  
  barker_operand <= barker_int (10);
  -- value to add with phi_map.
  
  phi_out        <= phi_out_reg;
  -- the output is registered
  
end RTL;
