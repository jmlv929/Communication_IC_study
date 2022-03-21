

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of cck_mod is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  --
 -- angles calculated from data_in with QPSK encoding
  signal phi1          : std_logic_vector ( 1 downto 0);
  signal phi2          : std_logic_vector ( 1 downto 0);
  signal phi3          : std_logic_vector ( 1 downto 0);
  signal phi4          : std_logic_vector ( 1 downto 0);
  
  -- 8-chip code word
  signal c0             : std_logic_vector ( 1 downto 0);
  signal c1             : std_logic_vector ( 1 downto 0);
  signal c2             : std_logic_vector ( 1 downto 0);
  signal c3             : std_logic_vector ( 1 downto 0);
  signal c4             : std_logic_vector ( 1 downto 0);
  signal c5             : std_logic_vector ( 1 downto 0);
  signal c6             : std_logic_vector ( 1 downto 0);
  signal c7             : std_logic_vector ( 1 downto 0);
  
  -- registered 8-chip code word :
  signal code_word_reg  : std_logic_vector (15 downto 0);
  
  -- for odd/even symbol phi1
  signal p              : std_logic_vector ( 1 downto 0);
  signal even_odd_n     : std_logic_vector ( 1 downto 0);

  -- wait between 2 shifts.
  signal shift_pulse_dly: std_logic;
  
  -- for functions
  constant ones         : std_logic_vector ( 1 downto 0):= "11";

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  --------------------------------------------
  -- extra 180 deg rot for odd symbols
  --------------------------------------------
  p <= "00" when (even_odd_n = "00" or even_odd_n = "11" ) else "11";
  phi1 <= angle_add (phi_map, p);
  --------------------------------------------
  -- QPSK encoding
  --------------------------------------------
  
  phi2 <= qpsk_enc (cck_mod_in(2),cck_mod_in(3));
  phi3 <= qpsk_enc (cck_mod_in(4),cck_mod_in(5));
  phi4 <= qpsk_enc (cck_mod_in(6),cck_mod_in(7));
  
  --------------------------------------------
  -- Code Word Composition
  --------------------------------------------
  c0 <= angle_add (phi1,angle_add (phi2,angle_add (phi3,phi4)));
  c1 <= angle_add (phi1,angle_add (phi3,phi4));
  c2 <= angle_add (phi1,angle_add (phi2,phi4));
  c3 <= angle_add (phi1,angle_add (phi4,ones));
  c4 <= angle_add (phi1,angle_add (phi2,phi3));
  c5 <= angle_add (phi1,phi3);
  c6 <= angle_add (phi1,angle_add (phi2,ones));
  c7 <= phi1;
  
  --------------------------------------------
  -- Sequential sending of phi_out + odd/even symbols
  --------------------------------------------
  c_reg_p : process (resetn, clk)
  begin
    if (resetn = '0') then
      code_word_reg <= (others=>'0');
    elsif clk'event and clk = '1' then
      if cck_mod_activate = '1' then
        if new_data = '1' then
          -- memorization
          code_word_reg <= c7 & c6 & c5 & c4 & c3 & c2 & c1 & c0;
        elsif shift_pulse_dly = '1' then    
          -- serialization
          code_word_reg <= "00" & code_word_reg (15 downto 2);
        end if;
      end if;
    end if;
  end process;
  
  --------------------------------------------
  -- odd/even symbols
  --------------------------------------------
  odd_even_p : process (resetn, clk)
  begin
    if (resetn = '0') then
      even_odd_n    <= "00";
    elsif clk'event and clk = '1' then
       -- first symbol is 0
      if first_data = '1' then
        even_odd_n    <= "00"; 
      elsif new_data = '1' then
        even_odd_n    <= even_odd_n + '1'; 
        -- next symbol will have inverted parity
      end if;
    end if;
  end process;
   
  --------------------------------------------
  -- Shift pulse delayed
  --------------------------------------------
  -- shift_pulse is delayed for letting time to get phi values.
  shift_pulse_dly_proc : process (clk, resetn)
  begin
    if resetn = '0' then
      shift_pulse_dly <= '0';
    elsif clk'event and clk = '1' then 
      if cck_mod_activate = '1' then
        shift_pulse_dly <= shift_pulse;
      end if;
    end if;
  end process;
  
  
  --------------------------------------------
  -- output
  --------------------------------------------
  phi_out <= code_word_reg (1 downto 0);

end RTL;
