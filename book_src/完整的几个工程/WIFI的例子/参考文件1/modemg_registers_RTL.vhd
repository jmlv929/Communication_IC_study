

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modemg_registers is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Modem g version register.
  signal int_build       : std_logic_vector(15 downto 0); -- Build of modemg.
  signal int_rel         : std_logic_vector( 7 downto 0); -- Release number.
  signal int_upg         : std_logic_vector( 7 downto 0); -- Upgrade number.
  -- MDMgCNTL register.
  signal int_modeabg     : std_logic_vector(1 downto 0);  -- "00": 802.11g mode
                                                          -- "01": 802.11a mode
                                                          -- "10": 802.11b mode
                                                          -- "11": reserved
  signal int_tx_iqswap   : std_logic;                     -- Swap I/Q in Tx
  signal int_rx_iqswap   : std_logic;                     -- Swap I/Q in Rx
  -- MDMgAGCCCA register.
  signal int_agc_disb    : std_logic;  -- AGC disable
  signal int_modeant     : std_logic;  -- Antenna diversity mode.
  signal int_deldc2      : std_logic_vector(4 downto 0);  -- DC waiting period.
  signal int_longslot    : std_logic;  -- Slot type.
  signal int_cs_max      : std_logic_vector(3 downto 0);  -- Carrier Sense waiting period.
  signal int_sig_max     : std_logic_vector(3 downto 0);  -- Signal valid on waiting period.

  signal int_edtransmode : std_logic;  -- CCA on Energy Detect Transitional Mode
  signal int_edmode      : std_logic;  -- Energy Detect Mode.

  -- MDMgADDESTMDUR register.
  signal int_addestimdura : std_logic_vector(3 downto 0); -- additional time duration 11a
  signal int_addestimdurb : std_logic_vector(3 downto 0); -- additional time duration 11b
  signal int_rampdown     : std_logic_vector(2 downto 0); -- ramp-down time duration

  -- MDMg11hCNTL register.
  signal int_rstoecnt    : std_logic;                     -- Reset OFDM Preamble Existence cnounter



  -- Combinational signals for prdata buses.
  signal next_prdata     : std_logic_vector(31 downto 0);
  signal edtransmode_reset_resync : std_logic;
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  ------------------------------------------------------------------------------
  -- Register outputs.
  ------------------------------------------------------------------------------
  -- MDMgCNTL register.
  reg_modeabg      <= int_modeabg;
  reg_tx_iqswap    <= int_tx_iqswap;
  reg_rx_iqswap    <= int_rx_iqswap;
  -- MDMgAGCCCA register.
  reg_deldc2       <= int_deldc2;
  reg_agc_disb     <= int_agc_disb; 
  reg_modeant      <= int_modeant; 
  reg_longslot     <= int_longslot;
  reg_cs_max       <= int_cs_max;  
  reg_sig_max      <= int_sig_max;
  reg_edtransmode  <= int_edtransmode;
  reg_edmode       <= int_edmode;     
  -- MDMgADDESTMDUR register.
  reg_addestimdura <= int_addestimdura;
  reg_addestimdurb <= int_addestimdurb;
  reg_rampdown     <= int_rampdown;
  -- MDMg11hCNTL register.
  reg_rstoecnt     <= int_rstoecnt;
      
  ------------------------------------------------------------------------------
  -- Fixed registers.
  ------------------------------------------------------------------------------
  -- Modemg version register (0.12).
  int_build        <= "0000000000000000";
  int_rel          <= "00000000";
  int_upg          <= "00001100";

  ------------------------------------------------------------------------------
  -- Register write
  ------------------------------------------------------------------------------
  -- The write cycle follows the timing shown in page 5-5 of the AMBA
  -- Specification.
  apb_write_pr: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      -- Reset MDMgCNTL register.
      int_modeabg   <= (others => '0');
      int_tx_iqswap <= '0';
      int_rx_iqswap <= '0';
      -- Reset MDMgAGCCCA register.
      int_deldc2      <= "11001";
      int_agc_disb    <= '1';
      int_modeant     <= '0';
      int_longslot    <= '0';
      int_cs_max      <= "1100";
      int_sig_max     <= "1100";
      int_edtransmode <= '0';
      int_edmode      <= '0';
      -- Reset MDMgADDESTMDUR register.
      int_addestimdura <= "1011"; 
      int_addestimdurb <= "1101"; 
      int_rampdown     <= "010"; 
      -- Reset MDMg11hCNTL register.
      int_rstoecnt <= '0';
    elsif pclk'event and pclk = '1' then
      int_rstoecnt <= '0';

      if edtransmode_reset_resync = '1' then
        int_edtransmode <= '0';
      end if;  
      
      if penable = '1' and psel = '1' and pwrite = '1' then
        case paddr is
          
          when MDMgCNTL_ADDR_CT    =>    -- Write MDMgCNTL register.
            int_modeabg <= pwdata(1 downto 0);
            int_tx_iqswap <= pwdata(2);
            int_rx_iqswap <= pwdata(3);
          
          when MDMgAGCCCA_ADDR_CT    =>  -- Write MDMgAGCCCA register.
            int_agc_disb    <= pwdata(0);
            int_modeant     <= pwdata(1);
            int_longslot    <= pwdata(2);
            int_deldc2      <= pwdata(12 downto 8);
            int_cs_max      <= pwdata(19 downto 16);
            int_sig_max     <= pwdata(27 downto 24);
            int_edtransmode <= pwdata(30);
            int_edmode      <= pwdata(31);

          when MDMgADDESTMDUR_ADDR_CT =>  -- Write MDMgADDESTMDUR register.
            int_addestimdura <= pwdata( 3 downto 0);
            int_addestimdurb <= pwdata(11 downto 8);
            int_rampdown     <= pwdata(18 downto 16);

          when MDMg11hCNTL_ADDR_CT   =>  -- Write MDMg11hCNTL register.
            int_rstoecnt <= pwdata(0);

          when others => null;
          
        end case;
      end if;
    end if;
  end process apb_write_pr;

  ------------------------------------------------------------------------------
  -- Registers read
  ------------------------------------------------------------------------------
  -- The read cycle follows the timing shown in page 5-6 of the AMBA
  -- Specification.
  -- psel is used to detect the beginning of the two-clock-cycle-long APB
  -- read access. This way, the second cycle can be used to register prdata
  -- and comply with interfaces timing requirements.
  apb_read_comb_pr: process (int_edtransmode, int_edmode, int_modeabg, int_build, int_rel, int_upg,
                        int_deldc2, int_agc_disb, int_modeant, int_longslot,
                        int_cs_max, int_sig_max, int_tx_iqswap, int_rx_iqswap,
                        int_rampdown, ofdmcoex, int_addestimdura, int_addestimdurb,
                        paddr, penable, psel, pwrite)
  begin
    next_prdata <= (others => '0');
    
    if psel = '1' then

      case paddr is

        when MDMgVERSION_ADDR_CT   =>  -- Read MDMgVERSION register.
          next_prdata               <= int_build & int_rel & int_upg;
          
        when MDMgCNTL_ADDR_CT    =>    -- Read MDMgCNTL register.
          next_prdata(1 downto 0)   <= int_modeabg;
          next_prdata(2)            <= int_tx_iqswap;
          next_prdata(3)            <= int_rx_iqswap;

        when MDMgAGCCCA_ADDR_CT    =>  -- Read MDMgAGCCCA register.
          next_prdata(0)            <= int_agc_disb;
          next_prdata(1)            <= int_modeant ;
          next_prdata(2)            <= int_longslot;
          next_prdata(12 downto 8)  <= int_deldc2;
          next_prdata(19 downto 16) <= int_cs_max;
          next_prdata(27 downto 24) <= int_sig_max;
          next_prdata(30)           <= int_edtransmode;
          next_prdata(31)           <= int_edmode;
          
        when MDMgADDESTMDUR_ADDR_CT => -- Read MDMgADDESTMDUR register.
          next_prdata( 3 downto  0) <= int_addestimdura;
          next_prdata(11 downto  8) <= int_addestimdurb;
          next_prdata(18 downto 16) <= int_rampdown;

        when MDMg11hSTAT_ADDR_CT   =>  -- Read MDMg11hSTAT register.
          next_prdata(7 downto 0)   <= ofdmcoex;
        
        when others =>
          next_prdata <= (others => '0');
          
      end case;
      
    end if;
  end process apb_read_comb_pr;

  -- Register prdata output.
  apb_read_seq_pr: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      prdata <= (others => '0');      
    elsif pclk'event and pclk = '1' then
      if psel = '1' then
        prdata <= next_prdata;
      end if;
    end if;
  end process apb_read_seq_pr;




  resynchro_p : process (pclk, reset_n)
  begin
    if reset_n = '0' then
      edtransmode_reset_resync <= '0';
    elsif pclk'event and pclk = '1' then
      edtransmode_reset_resync <= edtransmode_reset;
    end if;
  end process resynchro_p;

end RTL;
