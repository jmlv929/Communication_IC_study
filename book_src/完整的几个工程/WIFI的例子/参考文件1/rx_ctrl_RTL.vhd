
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of rx_ctrl is

  --------------------------------------------
  -- Constants
  --------------------------------------------
  constant ONE_US_CT          : std_logic_vector(5 downto 0) := "101011";
  constant IQ_COMP_ENABLE_CT  : std_logic_vector(8 downto 0) 
                  := conv_std_logic_vector(50, 9);
  constant IQ_ESTIM_DISABLE_CT : std_logic_vector(8 downto 0) 
                  := conv_std_logic_vector(400, 9);
  constant IQ_ESTIM_EN_COUNT_CT : std_logic_vector(5 downto 0) := "101010";  --44(d)=2C(h)
  --------------------------------------------
  -- Types
  --------------------------------------------

  -- IQ mismatch state machine
  type IQMM_STATE_TYPE is (idle_state,          -- idle state  
                           iq_enable_state);    -- enable iq estim and comp   

  type IQ_EN_COUNT_TYPE is (idle_state,         -- idle state
                            count_state,        -- start counter of 1us
                            enable_state);       -- enable iq_estim
  
  -- equalizer activation state machine
  type EQTIME_STATE_TYPE is (idle_state,          -- idle state  
                             wait_activate_state, -- wait for eq activation   
                             wait_init_state,     -- wait for eq init  
                             wait_enable_state);  -- wait for eq enable
                             
  -- equalizer parameters update state machine
  type EQPARAM_UPDATE_STATE_TYPE is (idle_state,     -- idle state  
                                     interval_state, -- wait for end of interval
                                     hold_state);    -- wait for end of hold 

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal energy_detect_ff1       : std_logic;
  signal energy_detect_pulse     : std_logic;
  -- phase estimation counter
  signal phase_estim_enable_o    : std_logic;
  signal phase_estim_cnt_enable  : std_logic;
  signal phase_estim_cnt         : std_logic_vector(3 downto 0);
  --precompensation counter
  signal precomp_cnt_enable      : std_logic;
  signal precomp_cnt             : std_logic_vector(5 downto 0);
  -- SFD detection counter
  signal sfd_cnt_enable          : std_logic;
  signal sfd_cnt                 : std_logic_vector(4 downto 0);
  --synchronization time counter
  signal synctime_cnt_enable     : std_logic;
  signal synctime_cnt            : std_logic_vector(5 downto 0);
  -- equalizer activation signals
  signal eqtime_state            : EQTIME_STATE_TYPE; -- equalizer timing sm
  signal eqtime_cnt_enable       : std_logic;
  signal eqtime_cnt              : std_logic_vector(3 downto 0);
  signal equalizer_activate_o    : std_logic;
  signal equalizer_init_n_o      : std_logic;
  signal equalizer_init_n_ff_o   : std_logic;
  -- iq mismatch signals
  signal iqmm_state              : IQMM_STATE_TYPE; -- alpha update sm
  signal iqmm_cnt_enable         : std_logic;
  signal iqmm_cnt                : std_logic_vector(8 downto 0);
  signal iq_estim_enable_int     : std_logic; -- iq mismatch estimation enable
  signal iq_en_state             : IQ_EN_COUNT_TYPE;
  -- alpha parameter signals
  signal alpha_update_state      : EQPARAM_UPDATE_STATE_TYPE; -- alpha update sm
  signal alpha_param_cnt_enable  : std_logic;
  signal alpha_param_10us_cnt    : std_logic_vector(3 downto 0);
  signal alpha_param_cnt         : std_logic_vector(11 downto 0);
  signal max_alpha_param_cnt     : std_logic_vector(3 downto 0);
  signal next_max_alpha_param_cnt: std_logic_vector(3 downto 0);
  signal alpha_num_interval      : std_logic_vector(1 downto 0);
  -- beta parameter signals
  signal beta_update_state       : EQPARAM_UPDATE_STATE_TYPE; -- beta update sm
  signal beta_param_cnt_enable   : std_logic;
  signal beta_param_10us_cnt     : std_logic_vector(3 downto 0);
  signal beta_param_cnt          : std_logic_vector(11 downto 0);
  signal max_beta_param_cnt      : std_logic_vector(3 downto 0);
  signal next_max_beta_param_cnt : std_logic_vector(3 downto 0);
  signal beta_num_interval       : std_logic_vector(1 downto 0);
  -- mu parameter signals
  signal mu_update_state         : EQPARAM_UPDATE_STATE_TYPE; -- beta update sm
  signal mu_param_cnt_enable     : std_logic;
  signal mu_param_10us_cnt       : std_logic_vector(3 downto 0);
  signal mu_param_cnt            : std_logic_vector(11 downto 0);
  signal max_mu_param_cnt        : std_logic_vector(3 downto 0);
  signal next_max_mu_param_cnt   : std_logic_vector(3 downto 0);
  signal mu_num_interval         : std_logic_vector(1 downto 0);
  
  -- applied equalizer parameters
  signal applied_alpha_o         : std_logic_vector(2 downto 0);
  signal applied_beta_o          : std_logic_vector(2 downto 0);
  signal applied_mu_o            : std_logic_vector(2 downto 0);

  -- one us counter
  signal one_us_cnt              : std_logic_vector(5 downto 0);
  signal one_us_it               : std_logic; -- pulse every 1 us
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------

begin

  equalizer_activate <= equalizer_activate_o;
  phase_estim_enable <= phase_estim_enable_o;
  applied_alpha      <= applied_alpha_o;
  applied_beta       <= applied_beta_o;
  applied_mu         <= applied_mu_o;
  equalizer_init_n   <= equalizer_init_n_ff_o;
  
  --------------------------------------------
  -- generate a pulse on rising edge of energy_detect
  --------------------------------------------
  ed_pulse_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      energy_detect_ff1   <= '0';
      energy_detect_pulse <= '0';
    elsif (hclk'event and hclk = '1') then
      energy_detect_ff1 <= energy_detect;
      if (energy_detect_ff1 = '0') and (energy_detect = '1') then
        energy_detect_pulse <= '1';
      else
        energy_detect_pulse <= '0';
      end if;
    end if;    
  end process ed_pulse_p;

  --------------------------------------------
  -- 1us counter
  --------------------------------------------
  one_us_cnt_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      one_us_cnt <= (others => '0');
      one_us_it  <= '0';
    elsif (hclk'event and hclk = '1') then
      -- initialize counter when end of AGC processing detected
      if (agcproc_end = '1') then
        one_us_cnt <= (others => '0');
        one_us_it  <= '0';
      else
        one_us_cnt <= one_us_cnt + '1';
        if (one_us_cnt = ONE_US_CT) then
          one_us_it  <= '1';
          one_us_cnt <= (others => '0');
        else
          one_us_it  <= '0';
        end if;
      end if;
    end if;
  end process one_us_cnt_p;
    

  --------------------------------------------
  -- The following process updates the alpha
  -- equalizer parameter according to the
  -- initial value and the update intervals.
  --------------------------------------------
  iq_mm_enable_p : process(hresetn, hclk)
  begin
    if (hresetn = '0') then
      iqmm_state      <= idle_state;
      iqmm_cnt        <= (others => '0');
      iqmm_cnt_enable <= '0';
      iq_comp_enable  <= '0';
      iq_estim_enable_int <= '0';
    elsif (hclk'event and hclk = '1') then
      case iqmm_state is
        -- idle state : wait for QPSK activation
        when idle_state =>
          iq_comp_enable  <= '0';
          iq_estim_enable_int <= '0';
          iqmm_cnt        <= (others => '0');
          iqmm_cnt_enable <= '0';
          if (rx_psk_mode = '1') and (iqmm_disb = '0') and
             (rx_idle_state = '0') then
            iqmm_state      <= iq_enable_state;
            iqmm_cnt_enable <= '1';
            iq_estim_enable_int <= '1';
          end if;
          
        when iq_enable_state =>
          if (iqmm_cnt_enable = '1') and (one_us_it = '1') then
            iqmm_cnt      <= iqmm_cnt + '1';
          end if;
      
          -- enable iq mismatch compensation
          if (iqmm_cnt = IQ_COMP_ENABLE_CT) then             
            iq_comp_enable  <= '1';
          end if;
            
          -- disable iq mismatch estimation
          if (iqmm_cnt = IQ_ESTIM_DISABLE_CT) then
            iq_estim_enable_int <= '0';
            iqmm_cnt_enable <= '0';
          end if;
          
          if (rx_idle_state = '1') then
            iqmm_state      <= idle_state;
          end if;

        when others =>
      end case;
    end if;
  end process iq_mm_enable_p;

  --------------------------------------------
  -- Wait 1 us after iq_estim_enable_int = 1
  -- to set iq_estim_enable to 1.
  --------------------------------------------
  iq_estim_1us_p: process (hclk, hresetn)
    variable iq_estim_en_count : std_logic_vector(5 downto 0);
  begin
    if hresetn = '0' then
      iq_estim_en_count := (others => '0');
      iq_estim_enable <= '0';
      iq_en_state <= idle_state;
    elsif hclk'event and hclk = '1' then
      case iq_en_state is
        
        when idle_state =>
          if iq_estim_enable_int='1' then
            iq_estim_en_count := (others => '0');
            iq_estim_enable <= '0';          
            iq_en_state <= count_state;
          end if;

        when count_state =>
          if (iq_estim_en_count=IQ_ESTIM_EN_COUNT_CT) then
            iq_estim_enable <= '1';
            iq_estim_en_count := (others => '0');
            iq_en_state <= enable_state;
          else
            iq_estim_en_count := iq_estim_en_count + '1';
          end if;

        when enable_state =>
          if iq_estim_enable_int='0' then
            iq_estim_enable <= '0';
            iq_en_state <= idle_state;            
          end if;
          
        when others => null;
      end case;
    end if;
  end process iq_estim_1us_p;
  
  --------------------------------------------
  -- Eqtime counter. This counter counts a delay
  -- before enabling the equalizer after the end
  -- of the AGC setting.
  --------------------------------------------
  eqtime_sm_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      eqtime_cnt         <= (others => '0');
      equalizer_activate_o <= '0';
      equalizer_init_n_o   <= '0';
      equalizer_init_n_ff_o   <= '0';
      equalizer_disb       <= '1';
      gain_enable          <= '0';
      eqtime_cnt_enable    <= '0';
      eqtime_state         <= idle_state;
    elsif (hclk'event and hclk = '1') then
      equalizer_init_n_ff_o   <= equalizer_init_n_o;
      case eqtime_state is
        when idle_state =>
          eqtime_cnt        <= (others => '0');
          eqtime_cnt_enable <= '0';
          gain_enable       <= '0';
          -- start counter when end of AGC processing detected
          if (agcproc_end = '1') then
            eqtime_cnt_enable <= '1';
            eqtime_state      <= wait_activate_state;
          end if;
          
        when wait_activate_state =>
          -- activate equalizer enable when end of counter
          if (eqtime_cnt = eqtime) then
            equalizer_activate_o <= '1';
            eqtime_cnt         <= (others => '0');
            eqtime_state       <= wait_init_state;
          end if;
          -- equalizer disable
          if (energy_detect = '0') then
            equalizer_activate_o <= '0';
            gain_enable          <= '0';
            equalizer_init_n_o   <= '0';
            equalizer_disb       <= '1';
            eqtime_state         <= idle_state;
          end if;
      
        when wait_init_state =>
          -- enable equalizer coeff computation when end of counter
          if (eqtime_cnt = 15) then
            if (gain_disb = '0') then
              gain_enable <= '1';
            end if;
            if (eq_disb = '0') then
              equalizer_init_n_o <= '1';
            end if;
            eqtime_cnt       <= (others => '0');
            eqtime_state     <= wait_enable_state;
          end if;
          -- equalizer disable
          if (energy_detect = '0') then
            equalizer_activate_o <= '0';
            gain_enable          <= '0';
            equalizer_init_n_o   <= '0';
            equalizer_disb       <= '1';
            eqtime_state         <= idle_state;
          end if;
      
        when wait_enable_state =>
          -- apply coeff on equalizer output when end of counter
          if (eqtime_cnt = 15) then
            if (eq_disb = '0') then
              equalizer_disb <= '0';
            end if;
            eqtime_cnt_enable  <= '0';
            eqtime_cnt     <= (others => '0');
          end if;
          if (rx_idle_state = '1') then
            equalizer_activate_o <= '0';
            gain_enable          <= '0';
            equalizer_init_n_o   <= '0';
            equalizer_disb       <= '1';
            eqtime_state         <= idle_state;
          end if;
            
        when others =>
          eqtime_state   <= idle_state;
      end case;

      if (one_us_it = '1') and (eqtime_cnt_enable = '1') then
        eqtime_cnt <= eqtime_cnt + '1';
      end if;
      
      
    end if;    
  end process eqtime_sm_p;

                     
  --------------------------------------------
  -- precomp counter. This counter counts a delay
  -- before enabling the frequency precompensation 
  -- after the energy threshold detection.
  --------------------------------------------
  precomp_cnt_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      precomp_cnt        <= (others => '0');
      precomp_cnt_enable <= '0';
      precomp_enable     <= '0';
    elsif (hclk'event and hclk = '1') then
      -- start counter when end of AGC processing detected
      if (agcproc_end = '1') and (precomp_disb = '0') then
        precomp_cnt        <= (others => '0');
        precomp_cnt_enable <= '1';
      end if;
      if (precomp_cnt_enable = '1') and (one_us_it = '1') then
        precomp_cnt <= precomp_cnt + '1';
      end if;
      
      -- precompensation disable
      if (energy_detect = '0') and (rx_idle_state = '1') then
        precomp_enable <= '0';
        precomp_cnt        <= (others => '0');
        precomp_cnt_enable <= '0';
      end if;
      
      -- precompensation enable when end of counter
      if (precomp_cnt = precomp) and (precomp_cnt_enable = '1') then
        precomp_enable <= '1';
        precomp_cnt        <= (others => '0');
      end if;
    end if;    
  end process precomp_cnt_p;
                            
                             
  --------------------------------------------
  -- SFD detect enable. The SFD detection is activated
  -- 25us after the end of the AGC procedure to
  -- avoid detecting the SFD pattern in the noise signal.
  --------------------------------------------
  sfd_detect_p : process(hresetn, hclk)
  begin
    if (hresetn = '0') then
      sfd_cnt           <= (others => '0');
      sfd_cnt_enable    <= '0';
      sfd_detect_enable <= '0';
    elsif (hclk'event and hclk = '1') then
      -- start counter when end of AGC processing detected
      if (agcproc_end = '1') then
        sfd_cnt        <= (others => '0');
        sfd_cnt_enable <= '1';
      end if;
      
      -- increment the counter every us.
      if (sfd_cnt_enable = '1') and (one_us_it = '1') then
        sfd_cnt <= sfd_cnt + '1';
      end if;
      
      -- disable counter on idle
      if (rx_idle_state = '1') then
        sfd_detect_enable <= '0';
        sfd_cnt           <= (others => '0');
        sfd_cnt_enable    <= '0';
      end if;
      
      -- enable SFD detection when end of counter
      if (sfd_cnt = 25) and (sfd_cnt_enable = '1') then
        sfd_detect_enable <= '1';
        sfd_cnt           <= (others => '0');
      end if;
    end if;    
  end process sfd_detect_p;
                            
                             
  --------------------------------------------
  -- synctime counter. This counter counts a delay
  -- before disabling the timing synchronization
  -- after the energy threshold detection.
  --------------------------------------------
  synctime_cnt_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      synctime_cnt        <= (others => '0');
      synctime_cnt_enable <= '0';
      synctime_enable     <= '0';
    elsif (hclk'event and hclk = '1') then
      -- start counter when end of AGC processing detected
      if (energy_detect_pulse = '1') then
        synctime_enable     <= '1';
      end if;
      if (agcproc_end = '1') then
        synctime_cnt        <= (others => '0');
        synctime_cnt_enable <= '1';
      end if;
      if (synctime_cnt_enable = '1') and (one_us_it = '1') then
        synctime_cnt <= synctime_cnt + '1';
      end if;
      
      -- precompensation disable
      if (energy_detect = '0') and (rx_idle_state = '1') then
        synctime_enable <= '0';
        synctime_cnt        <= (others => '0');
        synctime_cnt_enable <= '0';
      end if;
      
      -- precompensation enable when end of counter
      if (synctime_cnt = synctime) and (synctime_cnt_enable = '1') then
        synctime_enable <= '0';
        synctime_cnt    <= (others => '0');
      end if;
    end if;    
  end process synctime_cnt_p;
                            
                             
  --------------------------------------------
  -- phase estimation enable counter.
  -- This counter counts a delay before enabling 
  -- the phase correction
  -- after the energy threshold detection.
  --------------------------------------------
  phase_estim_cnt_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      phase_estim_cnt        <= (others => '0');
      phase_estim_cnt_enable <= '0';
      phase_estim_enable_o     <= '0';
    elsif (hclk'event and hclk = '1') then
      -- start counter when end of AGC processing detected
      if (agcproc_end = '1') and (comp_disb = '0') then
        phase_estim_cnt        <= (others => '0');
        phase_estim_cnt_enable <= '1';
      end if;
      if (phase_estim_cnt_enable = '1') and (one_us_it = '1') then
        phase_estim_cnt <= phase_estim_cnt + '1';
      end if;
      
      -- phase estimation disable
      if (energy_detect = '0') and (rx_idle_state = '1') then
        phase_estim_enable_o <= '0';
        phase_estim_cnt        <= (others => '0');
        phase_estim_cnt_enable <= '0';
      end if;
      
      -- phase estimation enable when end of counter
      if (phase_estim_cnt = looptime) and (phase_estim_cnt_enable = '1') then
        phase_estim_enable_o <= '1';
        phase_estim_cnt        <= (others => '0');
      end if;
    end if;    
  end process phase_estim_cnt_p;

  --------------------------------------------
  -- The following process computes the current
  -- interval length needed before update the
  -- alpha equalizer parameter.
  --------------------------------------------
  max_alpha_param_cnt_p : process(alpha_num_interval,
                                  talpha0, talpha1, talpha2, talpha3)
  begin
    case conv_integer(alpha_num_interval) is  
      when 0 =>                            
        max_alpha_param_cnt <= talpha0;
        next_max_alpha_param_cnt <= talpha1;
      when 1 =>                            
        max_alpha_param_cnt <= talpha1;  
        next_max_alpha_param_cnt <= talpha2;         
      when 2 =>                            
        max_alpha_param_cnt <= talpha2; 
        next_max_alpha_param_cnt <= talpha3;          
      when 3 =>                            
        max_alpha_param_cnt <= talpha3;  
        next_max_alpha_param_cnt <= talpha0;         
      when others =>                       
        max_alpha_param_cnt <= talpha0; 
        next_max_alpha_param_cnt <= talpha1;          
    end case;                              
    
  end process max_alpha_param_cnt_p;
  
  --------------------------------------------
  -- The following process computes the current
  -- interval length needed before update the
  -- beta equalizer parameter.
  --------------------------------------------
  max_beta_param_cnt_p : process(beta_num_interval,
                                  tbeta0, tbeta1, tbeta2, tbeta3)
  begin
    case conv_integer(beta_num_interval) is  
      when 0 =>                            
        max_beta_param_cnt <= tbeta0;
        next_max_beta_param_cnt <= tbeta1; 
      when 1 =>                            
        max_beta_param_cnt <= tbeta1;  
        next_max_beta_param_cnt <= tbeta2;          
      when 2 =>                            
        max_beta_param_cnt <= tbeta2;
        next_max_beta_param_cnt <= tbeta3;            
      when 3 =>                            
        max_beta_param_cnt <= tbeta3; 
        next_max_beta_param_cnt <= tbeta0;           
      when others =>                       
        max_beta_param_cnt <= tbeta0; 
        next_max_beta_param_cnt <= tbeta1;           
    end case;                              
    
  end process max_beta_param_cnt_p;
  
  --------------------------------------------
  -- The following process computes the current
  -- interval length needed before update the
  -- mu phase correction parameter.
  --------------------------------------------
  max_mu_param_cnt_p : process(mu_num_interval,
                                  tmu0, tmu1, tmu2, tmu3)
  begin
    case conv_integer(mu_num_interval) is  
      when 0 =>                            
        max_mu_param_cnt <= tmu0;
        next_max_mu_param_cnt <= tmu1;
      when 1 =>                            
        max_mu_param_cnt <= tmu1; 
        next_max_mu_param_cnt <= tmu2;          
      when 2 =>                            
        max_mu_param_cnt <= tmu2; 
        next_max_mu_param_cnt <= tmu3;          
      when 3 =>                            
        max_mu_param_cnt <= tmu3;
        next_max_mu_param_cnt <= tmu0;           
      when others =>                       
        max_mu_param_cnt <= tmu0; 
        next_max_mu_param_cnt <= tmu1;          
    end case;                              
    
  end process max_mu_param_cnt_p;
  
  --------------------------------------------
  -- The following process updates the alpha
  -- equalizer parameter according to the
  -- initial value and the update intervals.
  --------------------------------------------
  alpha_update_param_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      alpha_update_state     <= idle_state;
      alpha_param_cnt        <= (others => '0');
      alpha_param_10us_cnt   <= (others => '0');
      alpha_param_cnt_enable <= '0';
      alpha_num_interval     <= (others => '0');
      applied_alpha_o        <= (others => '0');
      alpha_accu_disb        <= '0';
    elsif (hclk'event and hclk = '1') then
      case alpha_update_state is
        -- idle state : wait for equalizer activation
        when idle_state =>
          alpha_num_interval <= (others => '0');
          alpha_param_cnt_enable <= '0';
          alpha_param_cnt        <= (others => '0');
          if (equalizer_init_n_o = '1') then
            applied_alpha_o        <= '0' & alpha;
            alpha_param_cnt        <= (others => '0');
            alpha_param_10us_cnt   <= (others => '0');
            alpha_param_cnt_enable <= '1';
            alpha_update_state     <= interval_state;
          end if;
          
        -- interval state : wait for end of intervals
        when interval_state =>
          if (alpha_param_cnt_enable = '1') and (one_us_it = '1') then
            alpha_param_10us_cnt <= alpha_param_10us_cnt + '1';
            if (alpha_param_10us_cnt = "1001") then
              alpha_param_10us_cnt <= (others => '0');
              alpha_param_cnt <= alpha_param_cnt + '1';
            end if;
          end if;
      
          if (alpha_param_cnt = max_alpha_param_cnt) then             
            alpha_num_interval <= alpha_num_interval + '1';     
            alpha_param_cnt    <= (others => '0');            
            if (applied_alpha_o /= "111") then                  
              applied_alpha_o <= applied_alpha_o + '1';    
            end if;                                        
            if (alpha_num_interval = 3 or next_max_alpha_param_cnt="0000") then
              alpha_update_state <= hold_state;
            end if;                                     
          end if;                                          
          if (rx_idle_state = '1') then
            alpha_accu_disb    <= '0';
            alpha_num_interval <= (others => '0');
            alpha_update_state <= idle_state;
          end if;

        -- hold state : wait for end of hold time
        when hold_state =>
          if (alpha_param_cnt_enable = '1') and (one_us_it = '1') then
            alpha_param_cnt <= alpha_param_cnt + '1';
          end if;
          if (alpha_param_cnt = eqhold) then             
            alpha_param_cnt        <= (others => '0');
            alpha_param_cnt_enable <= '0';
            alpha_accu_disb        <= '1';
          end if;                                     
          if (rx_idle_state = '1') then
            alpha_accu_disb    <= '0';
            alpha_num_interval <= (others => '0');
            alpha_update_state <= idle_state;
          end if;
            
        when others =>
          alpha_update_state <= idle_state;
      end case;
    end if;    
  end process alpha_update_param_p;
    
  --------------------------------------------
  -- The following process updates the beta
  -- equalizer parameter according to the
  -- initial value and the update intervals.
  --------------------------------------------
  beta_update_param_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      beta_update_state     <= idle_state;
      beta_param_cnt        <= (others => '0');
      beta_param_10us_cnt   <= (others => '0');
      beta_param_cnt_enable <= '0';
      beta_num_interval     <= (others => '0');
      applied_beta_o        <= (others => '0');
      beta_accu_disb        <= '0';
    elsif (hclk'event and hclk = '1') then
      case beta_update_state is
        -- idle state : wait for equalizer activation
        when idle_state =>
          beta_param_cnt        <= (others => '0');
          beta_param_cnt_enable <= '0';
          if (equalizer_init_n_o = '1') then
            applied_beta_o        <= '0' & beta;
            beta_param_cnt        <= (others => '0');
            beta_param_10us_cnt   <= (others => '0');
            beta_param_cnt_enable <= '1';
            beta_update_state     <= interval_state;
          end if;
          
        -- interval state : wait for end of intervals
        when interval_state =>
          if (beta_param_cnt_enable = '1') and (one_us_it = '1') then
            beta_param_10us_cnt <= beta_param_10us_cnt + '1';
            if (beta_param_10us_cnt = "1001") then
              beta_param_10us_cnt <= (others => '0');
              beta_param_cnt <= beta_param_cnt + '1';
            end if;
          end if;
      
          if (beta_param_cnt = max_beta_param_cnt) then             
            beta_num_interval <= beta_num_interval + '1';     
            beta_param_cnt    <= (others => '0');            
            if (applied_beta_o /= "111") then                  
              applied_beta_o <= applied_beta_o + '1';    
            end if;                                        
            if (beta_num_interval = 3 or next_max_beta_param_cnt="0000") then
              beta_update_state <= hold_state;
            end if;                                     
          end if;                                          
          if (rx_idle_state = '1') then
            beta_accu_disb        <= '0';
            beta_num_interval     <= (others => '0');
            beta_update_state     <= idle_state;
          end if;

        -- hold state : wait for end of hold time
        when hold_state =>
          if (beta_param_cnt_enable = '1') and (one_us_it = '1') then
            beta_param_cnt <= beta_param_cnt + '1';
          end if;
          if (beta_param_cnt = eqhold) then             
            beta_param_cnt        <= (others => '0');
            beta_param_cnt_enable <= '0';
            beta_accu_disb        <= '1';
          end if;                                     
          if (rx_idle_state = '1') then
            beta_accu_disb        <= '0';
            beta_num_interval     <= (others => '0');
            beta_update_state     <= idle_state;
          end if;
          
        when others =>
          beta_update_state <= idle_state;
      end case;
    end if;    
  end process beta_update_param_p;
    
  --------------------------------------------
  -- The following process updates the mu
  -- phase compensation parameter according to the
  -- initial value and the update intervals.
  --------------------------------------------
  mu_update_param_p : process(hresetn, hclk)
  begin
    if hresetn = '0' then
      mu_update_state     <= idle_state;
      mu_param_cnt        <= (others => '0');
      mu_param_10us_cnt   <= (others => '0');
      mu_param_cnt_enable <= '0';
      mu_num_interval     <= (others => '0');
      applied_mu_o        <= (others => '0');
    elsif (hclk'event and hclk = '1') then
      case mu_update_state is
        -- idle state : wait for equalizer activation
        when idle_state =>
          mu_num_interval     <= (others => '0');
          mu_param_cnt_enable <= '0';
          mu_param_cnt        <= (others => '0');
          if (phase_estim_enable_o = '1') then
            applied_mu_o        <= '0' & mu;
            mu_param_10us_cnt   <= (others => '0');
            mu_param_cnt        <= (others => '0');
            mu_param_cnt_enable <= '1';
            mu_update_state     <= interval_state;
          end if;
          
        -- interval state : wait for end of intervals
        when interval_state =>
          if (mu_param_cnt_enable = '1') and (one_us_it = '1') then
            mu_param_10us_cnt <= mu_param_10us_cnt + '1';
            if (mu_param_10us_cnt = "1001") then
              mu_param_10us_cnt <= (others => '0');
              mu_param_cnt <= mu_param_cnt + '1';
            end if;
          end if;
      
          if (mu_param_cnt = max_mu_param_cnt) then             
            mu_num_interval <= mu_num_interval + '1';     
            mu_param_cnt    <= (others => '0');            
            if (applied_mu_o /= "111") then                  
              applied_mu_o <= applied_mu_o + '1';    
            end if;                                        
            if (mu_num_interval = 3 or next_max_mu_param_cnt="0000") then
              mu_param_cnt_enable <= '0';
            end if;
          end if;                                          
          if (rx_idle_state = '1') then
            mu_update_state <= idle_state;
            mu_num_interval <= (others => '0');
          end if;                                     
          
        when others =>
          mu_update_state <= idle_state;
      end case;
    end if;    
  end process mu_update_param_p;
    

    
end RTL;
