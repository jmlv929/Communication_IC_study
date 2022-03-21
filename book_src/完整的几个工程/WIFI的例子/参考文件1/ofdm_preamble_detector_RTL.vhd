

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of ofdm_preamble_detector is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal phy_cca_ind_ff1         : std_logic;
  signal cp2_detected_saved      : std_logic;
  signal ofdmcoex_int            : std_logic_vector(7 downto 0);
  
  signal cp2_detected_ff1_resync : std_logic;
  signal cp2_detected_ff2_resync : std_logic;
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin


  detection_p : process (clk,reset_n)
  begin
    if reset_n = '0' then
      phy_cca_ind_ff1         <= '0';
      cp2_detected_saved      <= '0';
      cp2_detected_ff1_resync <= '0';
      cp2_detected_ff2_resync <= '0';
      ofdmcoex_int            <= (others => '0');
    elsif clk'event and clk ='1' then
      phy_cca_ind_ff1 <= phy_cca_ind;
      cp2_detected_ff1_resync <= cp2_detected;
      cp2_detected_ff2_resync <= cp2_detected_ff1_resync;
      
      if cp2_detected_ff2_resync = '1' and cp2_detected_saved = '0' then
        cp2_detected_saved <= '1';
      end if;  

      if phy_cca_ind_ff1 = '1' and phy_cca_ind = '0' then
        if a_b_mode = '0' and (cp2_detected_saved = '0' or rxe_errorstat = "01") then
          if ofdmcoex_int /= "11111111" then
            ofdmcoex_int <= ofdmcoex_int + '1'; 
          end if;
        end if;
        cp2_detected_saved <= '0';
      end if;
        
      if reg_rstoecnt = '1' then  
        ofdmcoex_int    <= (others => '0');
      end if;

    end if;
  end process detection_p;
  
  ofdmcoex <= ofdmcoex_int;

end RTL;
