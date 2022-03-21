

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of radioctrl_registers is


  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- Registers address
  constant RCVERSION_ADDR_CT    : std_logic_vector(5 downto 0) := "000000";  --00
  constant RCCNTL_ADDR_CT       : std_logic_vector(5 downto 0) := "000100";  --04
  constant RCWRDATA_ADDR_CT     : std_logic_vector(5 downto 0) := "001000";  --08
  constant RCRDDATA_ADDR_CT     : std_logic_vector(5 downto 0) := "001100";  --0C
  constant RCINTSTAT_ADDR_CT    : std_logic_vector(5 downto 0) := "010000";  --10
  constant RCINTACK_ADDR_CT     : std_logic_vector(5 downto 0) := "010100";  --14
  constant RCINTEN_ADDR_CT      : std_logic_vector(5 downto 0) := "011000";  --18
  constant RCTXSTARTDEL_ADDR_CT : std_logic_vector(5 downto 0) := "011100";  --1C
  constant RCRFCNTL_ADDR_CT     : std_logic_vector(5 downto 0) := "100000";  --20
  constant RCRFANACNTL_ADDR_CT  : std_logic_vector(5 downto 0) := "100100";  --24
  constant RCRFHISSCNTL_ADDR_CT : std_logic_vector(5 downto 0) := "101000";  --28
  constant RCSWRFOFFREQ_ADDR_CT : std_logic_vector(5 downto 0) := "101100";  --2C

  -- Release and upgrade number
  constant RC_RELEASE_CT : std_logic_vector(7 downto 0) := "00000000";
  constant RC_UPGRADE_CT : std_logic_vector(7 downto 0) := "00001100"; -- 12
  
  constant NULL_CT : std_logic_vector(31 downto 0) := (others => '0');
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal flavor     : std_logic_vector(1 downto 0);  -- Analog or digital interface
  signal startacc  : std_logic;         -- Start 3w access
  signal acctype   : std_logic;         -- Access type
  signal radad     : std_logic_vector(5 downto 0);  -- Register address
  signal wrdata    : std_logic_vector(15 downto 0);  -- Data to write
  signal errcnt    : std_logic_vector(7 downto 0);  -- Number of parity errors detected
  signal clkswto   : std_logic;         -- Clock switch time out
  signal readto    : std_logic;         -- Read access time out
  signal retried_parityerr : std_logic;         -- Max parity error number reached
  signal proterr   : std_logic;         -- Protocol error
  signal all_err   : std_logic;         -- Compiles all errors
  signal agc_err   : std_logic;         -- AGC parity err
  signal conflict  : std_logic;         -- Conflict : RD / RX 
  signal clksw     : std_logic;         -- Clock switch status
  signal accstat   : std_logic;         -- Access status
  signal agc_rfint : std_logic;         -- AGC RF Interrupt decoded by AGC BB
  signal rf_off_stat      : std_logic;  -- Radio is switched off

  signal agc_rfint_en   : std_logic;  -- AGC RF interrupt enable
  signal agcerrint_en   : std_logic;  -- AGC Error interrupt enable
  signal allerrint_en   : std_logic;  -- Error interrupt enable
  signal clkswint_en    : std_logic;  -- Clock switch interrupt enable
  signal accstatint_en  : std_logic;  -- Access status interrupt enable
  signal swrfoff_int_en : std_logic;  -- RF switched off interrupt enable
  signal txstartdel     : std_logic_vector(7 downto 0);  -- Cc. to wait before sending tx_onoff_conf
  signal maxresp        : std_logic_vector(5 downto 0);  -- Number of cc to wait 
                                                   -- to abort a read access
  signal txiqswap         : std_logic;      -- Swap TX I/Q lines
  signal rxiqswap         : std_logic;      -- Swap RX I/Q lines
  signal band             : std_logic;      -- Select power amplifier
  signal antforce         : std_logic;  -- Forces the use of the selected antenna
  signal useant           : std_logic;      -- Use antenna
  signal swcase           : std_logic_vector(1 downto 0);  -- RF switches
  signal forcedacon       : std_logic;      -- when high, always enable dac
  signal forceadcon       : std_logic;      -- when high, always enable adc
  signal paondel          : std_logic_vector(7 downto 0);  -- Cc. to wait before raising pan 
  signal edgemode         : std_logic;      -- Selects between dual and single edge
  signal xoen             : std_logic;      -- Enable RF crystal oscillator
  signal retry            : std_logic_vector(2 downto 0);  -- Number of trials in case of a parity error
  signal hissdisb         : std_logic;      -- disable HiSS drivers and receivers
  signal hiss_clken       : std_logic;      -- Enable HiSS clock receivers
  signal hiss_curr        : std_logic;      -- Select high-current mode for HiSS drivers
  signal forcehisspad     : std_logic;      -- Force HISS pad to be always on
  signal sw_rfoff_req     : std_logic;      -- Software request to stop RF
    -- Combinational signals for prdata buses.
  signal next_prdata  : std_logic_vector(31 downto 0);
 
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  flavor <= conv_std_logic_vector(ana_digital_g,2);
  xoen   <= '1';
            
  -------------------------------------------
  -- Registers write                         
  -------------------------------------------
  regwrite_p: process (pclk, reset_n)
  begin  
    if reset_n = '0' then               
      startacc          <= '0';
      acctype           <= '0';
      radad             <= (others => '0');
      wrdata            <= (others => '0');
      maxresp           <= "111111";
      edgemode          <= '0';
      band              <= '0';
      txiqswap          <= '0';
      rxiqswap          <= '0';
      forcehisspad      <= '0';
      hissdisb          <= '0';
      hiss_clken        <= '1';
      hiss_curr         <= '1';
      accstat           <= '0';
      clksw             <= '0';
      retried_parityerr <= '0';
      agc_err           <= '0';
      proterr           <= '0';
      readto            <= '0';
      conflict          <= '0';
      agc_rfint         <= '0';
      rf_off_stat       <= '0';
      allerrint_en      <= '0';
      agcerrint_en      <= '0';
      clkswint_en       <= '0';
      accstatint_en     <= '0';
      agc_rfint_en      <= '0';
      swrfoff_int_en    <= '0';
      paondel           <= "00000000";
      txstartdel        <= "10100011";
--      useant            <= '0';
      useant            <= '0';
      retry             <= "001";
      swcase            <= (others => '0');
      forcedacon        <= '0';
      forceadcon        <= '0';
      clkswto           <= '0';
      errcnt            <= (others => '0');
      antforce          <= '0';
      sw_rfoff_req      <= '0';
      
    elsif pclk'event and pclk = '1' then


      -- Counts up reported parity errors
      if parityerr_i = '1' then
        errcnt <= errcnt + '1';
      end if;

      -- Errors flags are set when there is a pulse on the corresponding
      agc_err           <= agcerr_i or agc_err;
      conflict          <= conflict_i or conflict;
      retried_parityerr <= retried_parityerr_i or retried_parityerr;
      proterr           <= proterr_i or proterr;
      readto            <= readto_i or readto;
      clkswto           <= clkswto_i or clkswto;
      clksw             <= clksw_i or clksw;
      accstat           <= accend_i or accstat;

      -- Mask read accesses when maxresp = 0
      if maxresp = "000000" and acctype = '0' then
        startacc  <= '0';
      else
        startacc  <= startacc and (not accend_i);
      end if;

      -- Interrupt from AGC
      agc_rfint         <= agc_rfint_i or agc_rfint;
      
      -- Interrupt from reqdata_handler when radio is really switched off
      rf_off_stat       <= rf_off_done_i or rf_off_stat;
      
      if penable_i = '1' and psel_i = '1' and pwrite_i = '1' then

        case paddr_i is
          when RCCNTL_ADDR_CT   =>
            startacc <= startacc or pwdata_i(15);
            acctype  <= pwdata_i(14);
            radad    <= pwdata_i(5 downto 0);

          when RCWRDATA_ADDR_CT =>
            wrdata <= pwdata_i(15 downto 0);
                       
          when RCINTACK_ADDR_CT =>
            -- Acknowledges interrupt sources
            sw_rfoff_req      <= sw_rfoff_req and (not pwdata_i(5));
            rf_off_stat       <= rf_off_stat and (not pwdata_i(5));
            agc_rfint         <= agc_rfint and (not pwdata_i(4));
            agc_err           <= agc_err and (not pwdata_i(3));
            retried_parityerr <= retried_parityerr and (not pwdata_i(2));
            proterr           <= proterr and (not pwdata_i(2));
            readto            <= readto and (not pwdata_i(2));
            clkswto           <= clkswto and (not pwdata_i(2));
            conflict          <= conflict and (not pwdata_i(2));
            clksw             <= clksw and (not pwdata_i(1));
            accstat           <= accstat and (not pwdata_i(0));

          when RCINTEN_ADDR_CT =>
            swrfoff_int_en  <= pwdata_i(5);
            agc_rfint_en    <= pwdata_i(4);
            agcerrint_en    <= pwdata_i(3);
            allerrint_en    <= pwdata_i(2);
            clkswint_en     <= pwdata_i(1);
            accstatint_en   <= pwdata_i(0);

          when RCTXSTARTDEL_ADDR_CT =>
            txstartdel  <= pwdata_i(7 downto 0);           
            
          when RCRFCNTL_ADDR_CT =>
            maxresp  <= pwdata_i(29 downto 24);
            txiqswap <= pwdata_i(6);
            rxiqswap <= pwdata_i(5);
            band     <= pwdata_i(4);
            antforce <= pwdata_i(3);
--            useant   <= pwdata_i(2);
            useant   <= pwdata_i(2);
            swcase   <= pwdata_i(1 downto 0);


          when RCRFANACNTL_ADDR_CT =>
            edgemode   <= pwdata_i(16);
            forcedacon <= pwdata_i(9);   
            forceadcon <= pwdata_i(8);    
            paondel    <= pwdata_i(7 downto 0);           
            
          when RCRFHISSCNTL_ADDR_CT =>
            retry        <= pwdata_i(10 downto 8);
            hissdisb     <= pwdata_i(4);
            hiss_clken   <= pwdata_i(3); 
            hiss_curr    <= pwdata_i(2);
            forcehisspad <= pwdata_i(1);
            if pwdata_i(0) = '1' then
              errcnt <= (others => '0');
            end if;
          
          when RCSWRFOFFREQ_ADDR_CT =>
            sw_rfoff_req <= pwdata_i(0);
            
          when others =>
        end case;
      end if;
    end if;
  end process regwrite_p;

  all_err <= retried_parityerr or proterr or readto  or clkswto or conflict;

  -------------------------------------------
  -- Registers read                          
  -------------------------------------------
  regread_p: process ( accstat, accstatint_en, acctype, agc_err, agc_rfint,
                       agc_rfint_en, agcerrint_en, all_err, allerrint_en,
                       antforce, b_antsel_i, band, clksw, clkswint_en, clkswto,
                       conflict, edgemode, errcnt, flavor, forceadcon,
                       forcedacon, forcehisspad, hiss_clken, hiss_curr,
                       hissdisb, maxresp, paddr_i, paondel, proterr, psel_i,
                       radad, rddata_i, readto, retried_parityerr, retry,
                       rf_off_stat, rxiqswap, sw_rfoff_req, swcase,
                       swrfoff_int_en, txiqswap, txstartdel, useant, wrdata)
  begin
    
    next_prdata <= (others => '0');

    if psel_i = '1' then
    -- Don't watch penable because of FPGAs pb, on resynchro data/penable
    -- => 2 periods to set data.  
      case paddr_i is
        when RCVERSION_ADDR_CT =>
          next_prdata <= NULL_CT(13 downto 0) &flavor & RC_RELEASE_CT & RC_UPGRADE_CT;
          
        when RCCNTL_ADDR_CT =>
          next_prdata <= NULL_CT(16 downto 0) & acctype & 
                    NULL_CT(7 downto 0) & radad;

        when RCWRDATA_ADDR_CT =>
          next_prdata <= NULL_CT (15 downto 0) & wrdata;
          
        when RCRDDATA_ADDR_CT =>
          next_prdata <= NULL_CT (15 downto 0) & rddata_i;
           
        when RCINTSTAT_ADDR_CT =>
          next_prdata <= b_antsel_i & NULL_CT (30 downto 24) & errcnt & "000" & clkswto & readto & 
                    conflict & retried_parityerr & proterr & NULL_CT (7 downto 6) & rf_off_stat & agc_rfint &
                    agc_err & all_err & clksw & accstat;

        when RCINTEN_ADDR_CT =>
          next_prdata <= NULL_CT(31 downto 6) & swrfoff_int_en & agc_rfint_en & agcerrint_en & allerrint_en & clkswint_en &
                    accstatint_en;

        when RCTXSTARTDEL_ADDR_CT =>
          next_prdata <= NULL_CT(31 downto 8)& txstartdel;
          
        when RCRFCNTL_ADDR_CT =>
          next_prdata <= "00" & maxresp & NULL_CT(23 downto 7) & 
                    txiqswap & rxiqswap & band & antforce & useant & swcase;

        when RCRFANACNTL_ADDR_CT =>
          next_prdata <= NULL_CT(31 downto 17) & edgemode & NULL_CT(15 downto 10) &
                      forcedacon & forceadcon & paondel;

        when RCRFHISSCNTL_ADDR_CT =>
          next_prdata <= NULL_CT(31 downto 11) & retry & NULL_CT(7 downto 5)
                       & hissdisb & hiss_clken & hiss_curr & forcehisspad & '0';
                       
        when RCSWRFOFFREQ_ADDR_CT =>
          next_prdata <=  NULL_CT(31 downto 2) & rf_off_stat & sw_rfoff_req;
        
        when others =>
          next_prdata <= (others => '0');
          
      end case;
    end if;
  end process regread_p;
  
  -- Register prdata_o output.
  regread_seq_p: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      prdata_o <= (others => '0');      
    elsif pclk'event and pclk = '1' then
      if psel_i = '1' then
        prdata_o <= next_prdata;
      end if;
    end if;
  end process regread_seq_p;

  -------------------------------------------
  -- Outputs                      
  -------------------------------------------
  startacc_o        <= startacc;
  acctype_o         <= acctype;
  edgemode_o        <= edgemode;
  radad_o           <= radad;
  wrdata_o          <= wrdata;
  sw_rfoff_req_o    <= sw_rfoff_req;
  -- Generate an interrupt only when the enable interrup of specific source is on.
  interrupt_o <= (rf_off_stat and swrfoff_int_en) or (agc_rfint and agc_rfint_en) or (agc_err and agcerrint_en) or
                 (all_err and allerrint_en) or (accstat and accstatint_en) or
                 (clksw and clkswint_en);
  maxresp_o      <= maxresp;
  band_o         <= band;
  txiqswap_o     <= txiqswap;
  rxiqswap_o     <= rxiqswap;
  xoen_o         <= xoen;
  forcehisspad_o <= forcehisspad;
  retry_o        <= retry;
  swcase_o       <= swcase;
  paondel_o      <= paondel;
  forcedacon_o   <= forcedacon;
  forceadcon_o   <= forceadcon;
  txstartdel_o   <= txstartdel;
  antforce_o     <= antforce;
--  useant_o       <= useant;
  useant_o       <= useant;
  hiss_biasen_o  <= not hissdisb;
  hiss_replien_o <= not hissdisb;
  hiss_clken_o   <= hiss_clken; 
  hiss_curr_o    <= hiss_curr;
  
  
end RTL;
