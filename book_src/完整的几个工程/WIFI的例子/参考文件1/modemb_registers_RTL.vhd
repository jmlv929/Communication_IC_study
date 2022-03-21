

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modemb_registers is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Modem b version register.
  signal int_build       : std_logic_vector(15 downto 0); -- Build of modemb.
  signal int_rel         : std_logic_vector( 7 downto 0); -- Release number.
  signal int_upg         : std_logic_vector( 7 downto 0); -- Upgrade number.
  -- MDMbCNTL register.
  signal int_tlockdisb   : std_logic; -- '0': use timing lock from service field
  signal int_rxc2disb    : std_logic; -- '0' to enable 2 complement.
  signal int_txc2disb    : std_logic; -- '0' to enable 2 complement.
  signal int_interpdisb  : std_logic; -- '0' to enable Interpolator.
  signal int_iqmmdisb    : std_logic; -- '0' to enable I/Q mismatch compensation.
  signal int_gaindisb    : std_logic; -- '0' to enable the gain compensation.
  signal int_precompdisb : std_logic; -- '0' to enable timing offset compensation
  signal int_dcoffdisb   : std_logic; -- '0' to enable the DC offset compensation
  signal int_compdisb    : std_logic; -- '0' to enable the compensation.
  signal int_eqdisb      : std_logic; -- '0' to enable the equalizer.
  signal int_firdisb     : std_logic; -- '0' to enable the FIR.
  signal int_spreaddisb  : std_logic; -- '0' to enable spreading.
  signal int_scrambdisb  : std_logic; -- '0' to enable scrambling.
  signal int_sfderr      : std_logic_vector( 2 downto 0); -- SFD errors allowed.
  signal int_interfildisb: std_logic;
  -- Number of preamble bits to be considered in short SFD comparison.
  signal int_sfdlen      : std_logic_vector( 2 downto 0);
  signal int_prepre      : std_logic_vector( 5 downto 0); -- pre-preamble count.

  -- MDMbPRMINIT register.
  -- Values for phase correction parameters.
  signal int_rho         : std_logic_vector( 1 downto 0);
  signal int_mu          : std_logic_vector( 1 downto 0);
  -- Values for phase feedforward equalizer parameters.
  signal int_beta        : std_logic_vector( 1 downto 0);
  signal int_alpha       : std_logic_vector( 1 downto 0);

  -- MDMbTALPHA register.
  -- TALPHAn time interval value for equalizer alpha parameter update.
  signal int_talpha3     : std_logic_vector( 3 downto 0);
  signal int_talpha2     : std_logic_vector( 3 downto 0);
  signal int_talpha1     : std_logic_vector( 3 downto 0);
  signal int_talpha0     : std_logic_vector( 3 downto 0);
    
  -- MDMbTBETA register.
  -- TBETAn time interval value for equalizer beta parameter update.
  signal int_tbeta3      : std_logic_vector( 3 downto 0);
  signal int_tbeta2      : std_logic_vector( 3 downto 0);
  signal int_tbeta1      : std_logic_vector( 3 downto 0);
  signal int_tbeta0      : std_logic_vector( 3 downto 0);
    
  -- MDMbTMU register.
  -- TMUn time interval value for phase correction and offset comp. mu param.
  signal int_tmu3        : std_logic_vector( 3 downto 0);
  signal int_tmu2        : std_logic_vector( 3 downto 0);
  signal int_tmu1        : std_logic_vector( 3 downto 0);
  signal int_tmu0        : std_logic_vector( 3 downto 0);

  -- MDMbCNTL1 register.
  signal int_rxlenchken  : std_logic;
  signal int_rxmaxlength : std_logic_vector(11  downto 0);
  
  -- MDMbRFCNTL register: AC coupling gain compensation.
  signal int_txconst     : std_logic_vector(7 downto 0);
  signal int_txenddel    : std_logic_vector(7 downto 0);
  
  -- MDMbCCA register.
  -- Signal quality threshold for CCA acquisition.
  signal int_ccamode     : std_logic_vector( 2 downto 0); -- CCA mode select.
  
  -- MDMbEQCNTL register.
  -- Delay to stop the equalizer adaptation after the last param update, in 탎.
  signal int_eqhold      : std_logic_vector(11 downto 0);
  -- Delay to start the compensation after the start of the estimation, in 탎.
  signal int_comptime    : std_logic_vector( 4 downto 0);
  -- Delay to start the estimation after the enabling of the equalizer, in 탎.
  signal int_esttime     : std_logic_vector( 4 downto 0);
  -- Delay to switch on the equalizer after the fine gain setting, in 탎.
  signal int_eqtime      : std_logic_vector( 3 downto 0);

  -- MDMbCNTL2 register.
  signal int_maxstage      : std_logic_vector(5 downto 0);
  signal int_precomp       : std_logic_vector(5 downto 0);
  signal int_synctime      : std_logic_vector(5 downto 0);
  signal int_looptime      : std_logic_vector(3 downto 0);
  
  -- Combinational signal for prdata.
  signal next_prdata : std_logic_vector(31 downto 0);

  -- Front-end signal selected or not.
  signal front_end_registers : std_logic;
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  FRONT_END_SIG_G: if radio_interface_g = 1 or radio_interface_g = 3 generate
    front_end_registers <= '1';
  end generate FRONT_END_SIG_G;
  
  NO_FRONT_END_SIG_G: if radio_interface_g = 2 generate
    front_end_registers <= '0';
  end generate NO_FRONT_END_SIG_G;

  ------------------------------------------------------------------------------
  -- Register outputs.
  ------------------------------------------------------------------------------
  -- MDMbCNTL register.
  reg_tlockdisb   <= int_tlockdisb;
  reg_rxc2disb    <= int_rxc2disb;
  reg_txc2disb    <= int_txc2disb;
  reg_interpdisb  <= int_interpdisb;
  reg_iqmmdisb    <= int_iqmmdisb;
  reg_gaindisb    <= int_gaindisb; 
  reg_precompdisb <= int_precompdisb;
  reg_dcoffdisb   <= int_dcoffdisb;
  reg_compdisb    <= int_compdisb;
  reg_eqdisb      <= int_eqdisb; 
  reg_firdisb     <= int_firdisb; 
  reg_spreaddisb  <= int_spreaddisb; 
  reg_scrambdisb  <= int_scrambdisb; 
  reg_sfderr      <= int_sfderr    ;
  reg_interfildisb<= int_interfildisb; 
  reg_sfdlen      <= int_sfdlen    ; 
  reg_prepre      <= int_prepre    ; 

  -- MDMbPRMINIT register.
  reg_rho         <= int_rho  ;
  reg_mu          <= int_mu   ;
  reg_beta        <= int_beta ;
  reg_alpha       <= int_alpha;

  -- MDMbTALPHA register.
  reg_talpha3     <= int_talpha3;   
  reg_talpha2     <= int_talpha2;   
  reg_talpha1     <= int_talpha1;   
  reg_talpha0     <= int_talpha0;   

  -- MDMbTBETA register.
  reg_tbeta3      <= int_tbeta3;
  reg_tbeta2      <= int_tbeta2;
  reg_tbeta1      <= int_tbeta1;
  reg_tbeta0      <= int_tbeta0;

  -- MDMbTMU register.
  reg_tmu3        <= int_tmu3;   
  reg_tmu2        <= int_tmu2;   
  reg_tmu1        <= int_tmu1;   
  reg_tmu0        <= int_tmu0;   

  -- MDMbCNTL1 register.
  reg_rxlenchken  <= int_rxlenchken;
  reg_rxmaxlength <= int_rxmaxlength;
  
  -- MDMbRFCNTL register.
  reg_txconst     <= int_txconst;
  reg_txenddel    <= int_txenddel;

  -- MDMbCCA register.
  reg_ccamode     <= int_ccamode ;

  -- MDMbEQCNTL register.
  reg_eqhold      <= int_eqhold;
  reg_comptime    <= int_comptime;
  reg_esttime     <= int_esttime;
  reg_eqtime      <= int_eqtime;

  -- MDMbCNTL2 register.
  reg_maxstage    <= int_maxstage;
  reg_precomp     <= int_precomp;
  reg_synctime    <= int_synctime;
  reg_looptime    <= int_looptime;
 
  ------------------------------------------------------------------------------
  -- Fixed registers.
  ------------------------------------------------------------------------------
  -- Modemb version register (1.02).
  int_build        <= "0000000000000000";
  int_rel          <= "00000001";
  int_upg          <= "00000101";

  ------------------------------------------------------------------------------
  -- Register write
  ------------------------------------------------------------------------------
  -- The write cycle follows the timing shown in page 5-5 of the AMBA
  -- Specification.
  apb_write_pr: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      -- Reset MDMbCNTL register.
      int_tlockdisb   <= '1';
      int_rxc2disb    <= '0';
      int_txc2disb    <= '0';
      int_interpdisb  <= '0';
      int_iqmmdisb    <= '0';
      int_gaindisb    <= '0';
      int_precompdisb <= '0';
      int_dcoffdisb   <= '0';
      int_compdisb    <= '0';
      int_eqdisb      <= '0';
      int_firdisb     <= '0';
      int_spreaddisb  <= '0';
      int_scrambdisb  <= '0';
      int_sfderr      <= (others => '0');
      int_interfildisb<= '0';
      int_sfdlen      <= (others => '0');
      int_prepre      <= (others => '0');

      -- Reset MDMbPRMINIT register.
      int_rho         <= (others => '0');
      int_mu          <= "01";
      int_beta        <= "10";
      int_alpha       <= "10";
      
      -- Reset MDMbTALPHA register.
      int_talpha3     <= "0110";
      int_talpha2     <= "0010";
      int_talpha1     <= "0011";
      int_talpha0     <= "0110";
      
      -- Reset MDMbTBETA register.
      int_tbeta3      <= "0110";
      int_tbeta2      <= "0010";
      int_tbeta1      <= "0011";
      int_tbeta0      <= "0110";
      
      -- Reset MDMbTMU register.
      int_tmu3        <= "0101";
      int_tmu2        <= "0101";
      int_tmu1        <= "0101";
      int_tmu0        <= "0101";

      -- Reset MDMbCNTL1 register.
      int_rxlenchken  <= '1';
      int_rxmaxlength <= "100100101010";
      
      -- MDMRFCNTL register.
      int_txconst     <= (others => '0');
      int_txenddel    <= "00110000";
  
      -- MDMbCCA register.
      int_ccamode     <= "100";
      
      -- MDMbEQCNTL register.
      int_eqhold      <= (others => '1');
      int_comptime    <= (others => '0');
      int_esttime     <= (others => '0');
      int_eqtime      <= "0001";

      -- MDMbCNTL2 register.
      int_maxstage    <= "100111";
      int_precomp     <= "111000";
      int_synctime    <= "010010";
      int_looptime    <= "0101";

    elsif pclk'event and pclk = '1' then
      if penable = '1' and psel = '1' and pwrite = '1' then
        case paddr is
          
          when MDMBCNTL_ADDR_CT    =>  -- Write MDMbCNTL register.
            if front_end_registers = '1' then
              int_tlockdisb    <= pwdata(31);
              int_rxc2disb     <= pwdata(30);
              int_interpdisb   <= pwdata(29);
              int_gaindisb     <= pwdata(27);
              int_firdisb      <= pwdata(22);
              int_interfildisb <= pwdata(11);
              int_txc2disb     <= pwdata(7);
            else
              int_tlockdisb    <= '0';
              int_rxc2disb     <= '0';
              int_interpdisb   <= '0';
              int_gaindisb     <= '0';
              int_firdisb      <= '0';
              int_interfildisb <= '0';
              int_txc2disb     <= '0';
            end if;
            int_iqmmdisb    <= pwdata(28);
            int_precompdisb <= pwdata(26);
            int_dcoffdisb   <= pwdata(25);
            int_compdisb    <= pwdata(24);
            int_eqdisb      <= pwdata(23);
            int_spreaddisb  <= pwdata(21);
            int_scrambdisb  <= pwdata(20);
            int_sfderr      <= pwdata(14 downto 12);
            int_sfdlen      <= pwdata(10 downto 8);
            int_prepre      <= pwdata( 5 downto 0);
          
          when MDMbPRMINIT_ADDR_CT =>  -- Write MDMbPRMINIT register.
            int_rho         <= pwdata(21 downto 20);
            int_mu          <= pwdata(17 downto 16);
            int_beta        <= pwdata( 5 downto 4);
            int_alpha       <= pwdata( 1 downto 0);

          when MDMbTALPHA_ADDR_CT   =>  -- Write MDMbTALPHA register.
            int_talpha3     <= pwdata(15 downto 12); 
            int_talpha2     <= pwdata(11 downto 8); 
            int_talpha1     <= pwdata( 7 downto 4); 
            int_talpha0     <= pwdata( 3 downto 0); 
            
          when MDMbTBETA_ADDR_CT   =>  -- Write MDMbTBETA register.
            int_tbeta3      <= pwdata(15 downto 12); 
            int_tbeta2      <= pwdata(11 downto 8);
            int_tbeta1      <= pwdata( 7 downto 4);
            int_tbeta0      <= pwdata( 3 downto 0);
            
          when MDMbTMU_ADDR_CT   =>  -- Write MDMbTMU register.
            int_tmu3        <= pwdata(15 downto 12); 
            int_tmu2        <= pwdata(11 downto 8); 
            int_tmu1        <= pwdata( 7 downto 4); 
            int_tmu0        <= pwdata( 3 downto 0); 

          when MDMbCNTL1_ADDR_CT  =>     -- Write MDMbCNTL1 register.
            int_rxlenchken  <= pwdata(12);
            int_rxmaxlength <= pwdata(11 downto 0);
            
          when MDMbRFCNTL_ADDR_CT  =>  -- Write MDMbRFCNTL register.
            if front_end_registers = '1'  then
              int_txconst     <= pwdata(15 downto 8);
            else
              int_txconst     <= (others => '0');
            end if;
            int_txenddel    <= pwdata(23 downto 16);
            
          when MDMbCCA_ADDR_CT       =>  -- Write MDMbCCA register.
            int_ccamode     <= pwdata(10 downto 8);
            
          when MDMbEQCNTL_ADDR_CT    =>  -- Write MDMbEQCNTL register.
            int_eqhold      <= pwdata(27 downto 16);
            int_comptime    <= pwdata(14 downto 10);
            int_esttime     <= pwdata( 9 downto 5);
            int_eqtime      <= pwdata( 3 downto 0);

          when MDMbCNTL2_ADDR_CT    =>  -- Write MDMbCNTL2 register.
            int_maxstage    <= pwdata(29 downto 24);
            int_precomp     <= pwdata(21 downto 16);
            int_synctime    <= pwdata(13 downto 8);
            int_looptime    <= pwdata(3 downto 0);
            
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
  apb_read_pr: process (front_end_registers, int_alpha, int_beta, int_build,
                        int_ccamode, int_compdisb, int_comptime, int_dcoffdisb,
                        int_eqdisb, int_eqhold, int_eqtime, int_esttime,
                        int_firdisb, int_gaindisb, int_interfildisb,
                        int_interpdisb, int_iqmmdisb, int_looptime,
                        int_maxstage, int_mu, int_precomp, int_precompdisb,
                        int_prepre, int_rel, int_rho, int_rxc2disb,
                        int_rxlenchken, int_rxmaxlength, int_scrambdisb,
                        int_sfderr, int_sfdlen, int_spreaddisb, int_synctime,
                        int_talpha0, int_talpha1, int_talpha2, int_talpha3,
                        int_tbeta0, int_tbeta1, int_tbeta2, int_tbeta3,
                        int_tlockdisb, int_tmu0, int_tmu1, int_tmu2, int_tmu3,
                        int_txc2disb, int_txconst, int_txenddel, int_upg,
                        paddr, psel, reg_dcoffseti, reg_dcoffsetq, reg_eqsumi,
                        reg_eqsumq, reg_freqoffestim, reg_iqgainestim)
  begin
    next_prdata <= (others => '0');
    
    if psel = '1' then

      case paddr is
        when MDMBCNTL_ADDR_CT    =>  -- Read MDMbCNTL register.
          if front_end_registers = '1'  then
            next_prdata(31) <= int_tlockdisb;
            next_prdata(30) <= int_rxc2disb;
            next_prdata(29) <= int_interpdisb;
            next_prdata(27) <= int_gaindisb;
            next_prdata(22) <= int_firdisb;
            next_prdata(11) <= int_interfildisb;
            next_prdata(7)  <= int_txc2disb;
          end if;
          next_prdata(28)           <= int_iqmmdisb  ;
          next_prdata(26)           <= int_precompdisb;
          next_prdata(25)           <= int_dcoffdisb ;
          next_prdata(24)           <= int_compdisb; 
          next_prdata(23)           <= int_eqdisb;
          next_prdata(21)           <= int_spreaddisb;
          next_prdata(20)           <= int_scrambdisb;
          next_prdata(14 downto 12) <= int_sfderr    ;
          next_prdata(10 downto  8) <= int_sfdlen    ;
          next_prdata( 5 downto  0) <= int_prepre    ;

        when MDMbPRMINIT_ADDR_CT =>  -- Read MDMbPRMINIT register.
          next_prdata(21 downto 20) <= int_rho;          
          next_prdata(17 downto 16) <= int_mu;          
          next_prdata( 5 downto 4)  <= int_beta ;                  
          next_prdata( 1 downto 0)  <= int_alpha;                   
                                                              
        when MDMbTALPHA_ADDR_CT   =>  -- Read MDMbTALPHA register.    
          next_prdata(15 downto 12) <= int_talpha3;
          next_prdata(11 downto 8)  <= int_talpha2;
          next_prdata( 7 downto 4)  <= int_talpha1;
          next_prdata( 3 downto 0)  <= int_talpha0;
          
        when MDMbTBETA_ADDR_CT  =>  -- Read MDMbTBETA register.   
          next_prdata(15 downto 12) <= int_tbeta3;
          next_prdata(11 downto 8)  <= int_tbeta2;
          next_prdata( 7 downto 4)  <= int_tbeta1;
          next_prdata( 3 downto 0)  <= int_tbeta0;
          
        when MDMbTMU_ADDR_CT   =>  -- Read MDMbTMU register.    
          next_prdata(15 downto 12) <= int_tmu3;
          next_prdata(11 downto 8)  <= int_tmu2;
          next_prdata( 7 downto 4)  <= int_tmu1;
          next_prdata( 3 downto 0)  <= int_tmu0;

        when MDMbCNTL1_ADDR_CT     =>       -- Read MDMbCNTLs register.
          next_prdata(12) <= int_rxlenchken;
          next_prdata(11 downto 0) <= int_rxmaxlength;
          
        when MDMbRFCNTL_ADDR_CT  =>  -- Read MDMbRFCNTL register.
          if front_end_registers = '1' then
            next_prdata(15 downto 8)  <= int_txconst;
          end if;
          next_prdata(23 downto 16) <= int_txenddel;
            
        when MDMbCCA_ADDR_CT     =>  -- Read MDMbCCA register.
          next_prdata(10 downto  8) <= int_ccamode;

        when MDMbEQCNTL_ADDR_CT  =>  -- Read MDMbEQCNTL register. 
          next_prdata(27 downto 16) <= int_eqhold;
          next_prdata(14 downto 10) <= int_comptime;
          next_prdata( 9 downto 5)  <= int_esttime;
          next_prdata( 3 downto 0)  <= int_eqtime;

        when MDMbCNTL2_ADDR_CT  =>      -- Read MDMbCNTL2 register.
          next_prdata(29 downto 24) <= int_maxstage;
          next_prdata(21 downto 16) <= int_precomp;
          next_prdata(13 downto 8) <= int_synctime;
          next_prdata(3 downto 0) <= int_looptime;
          
        when MDMbSTAT0_ADDR_CT    =>  -- Read MDMbSTAT0 register.  
          next_prdata(31 downto 24) <=  reg_eqsumq;
          next_prdata(23 downto 16) <= reg_eqsumi;
          next_prdata(13 downto 8) <= reg_dcoffsetq;
          next_prdata(5 downto 0) <= reg_dcoffseti;

        when MDMbSTAT1_ADDR_CT    =>  -- Read MDMbSTAT1 register.  
          next_prdata(14 downto 8) <=  reg_iqgainestim; 
          next_prdata(7 downto 0) <=  reg_freqoffestim;
          
        when MDMbVERSION_ADDR_CT   =>
          next_prdata <= int_build & int_rel & int_upg;
          
        when others =>
          next_prdata <= (others => '0');
          
      end case;
      
    end if;
  end process apb_read_pr;

  prdata_seq_pr: process (pclk, reset_n)
  begin
    if reset_n = '0' then
      prdata <= (others => '0');
    elsif pclk'event and pclk = '1' then
      if psel = '1' then
        prdata <= next_prdata;
      end if;
    end if;
  end process prdata_seq_pr;

end RTL;
