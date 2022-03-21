

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of ramp_phase_rot is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type PHASE_STATETYPE_T is (idle,
                             run_ramp,
                             symbol_end);

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- detail : 2^4 + 2^3 + 2^2 + 2^1 + 2^0 , 2^-1 + 2^-2 + 2^-3 ...
  -- We have 5 bits of whole value and 13 bits of fractionnal value
  constant TWO_PI_CT : std_logic_vector(17 downto 0) := "001100100100001111";-- 2*pi
  constant PI_CT     : std_logic_vector(17 downto 0) := "000110010010000111";-- pi
  constant INV_PI_CT : std_logic_vector(17 downto 0) := "111001101101111001";-- -pi

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Phase calculation
  signal phase             : std_logic_vector(21 downto 0); -- before saturation
  signal d_phase           : std_logic_vector(21 downto 0);
  signal phase_sat         : std_logic_vector(17 downto 0); -- after saturation
  signal phase_unwrap      : std_logic_vector(17 downto 0); -- after unwrapping
  signal cordic_phase_sat  : std_logic_vector(11 downto 0); -- cordic phase after saturation

  -- Cordic
  signal cordic_x_out      : std_logic_vector(13 downto 0);
  signal cordic_y_out      : std_logic_vector(13 downto 0);

  signal coef_cordic_norm  : std_logic_vector(12 downto 0);

  signal cordic_x_mul      : std_logic_vector(26 downto 0);
  signal cordic_y_mul      : std_logic_vector(26 downto 0);

  -- Carrier value
  signal carrier_cnt       : std_logic_vector(5 downto 0);
  signal d_carrier_cnt     : std_logic_vector(5 downto 0);
  signal init_carrier_cnt  : std_logic;
  signal carrier_value_n   : std_logic_vector(21 downto 0);
  signal carrier_value     : std_logic_vector(21 downto 0);
  signal d_carrier_value   : std_logic_vector(21 downto 0);

  -- Flow control
  signal data_valid_ff1      : std_logic;
  signal data_valid_ff2      : std_logic;
  signal data_valid_ff3      : std_logic;
  signal data_valid_ff4      : std_logic;
  signal data_ready_ff1      : std_logic;
  signal start_of_symbol_ff1 : std_logic;
  signal start_of_symbol_o_s : std_logic;
  signal start_of_symbol_o_s1: std_logic;
  signal start_of_symbol_o_s2: std_logic;
  signal start_of_symbol_o_s3: std_logic;
  -- phase calculation
  signal estimate_done     : std_logic;
  signal cpe               : std_logic_vector(16 downto 0);
  signal d_cpe             : std_logic_vector(16 downto 0);
  signal sto               : std_logic_vector(16 downto 0);
  signal d_sto             : std_logic_vector(16 downto 0);
  signal init_phase        : std_logic;

  -- phase calculation algorithm
  signal phase_state       : PHASE_STATETYPE_T;
  signal next_phase_state  : PHASE_STATETYPE_T;

  -- first symbol of each burst : phase at 0
  signal first_symbol      : std_logic;
  -- second symbol of each burst : wait until signal_valid_i
  signal second_symbol     : std_logic;

  -- Zero signal for unused cordic inputs
  signal all_zero          : std_logic_vector(11 downto 0);

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -------------------------------------------------------------------
  -- Phase calculation algorithm synchronisation
  -------------------------------------------------------------------
  phasealgo_statemachine_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      phase_state <= idle;
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        phase_state <= idle;
      elsif start_of_burst_i = '1' then
        phase_state <= idle;
      elsif start_of_symbol_i = '1'  and 
            start_of_symbol_ff1 = '0'and 
            estimate_done_i = '0'    and
            estimate_done = '0'      then
        phase_state <= idle;
      else
        phase_state <= next_phase_state;
      end if;
    end if;
  end process phasealgo_statemachine_p; 


  -------------------------------------------------------------------
  -- Control signals assignment
  -------------------------------------------------------------------
  signal_value_p : process (clk, reset_n)
  begin

    -- control signals reset
    if reset_n = '0' then
      init_carrier_cnt    <= '1';
      init_phase          <= '1';
      start_of_symbol_ff1 <= '0';
      data_ready_ff1      <= '0';
      
    elsif clk'event and clk = '1' then

      start_of_symbol_ff1 <= start_of_symbol_i;
      data_ready_ff1      <= data_ready_i;
      
      if sync_reset_n = '0' then
        init_carrier_cnt <= '1';
        init_phase       <= '1';
      
      elsif start_of_burst_i = '1' then
        init_carrier_cnt <= '1';
        init_phase       <= '0';

      elsif start_of_symbol_i = '1' and start_of_symbol_ff1 = '0' then
        init_carrier_cnt <= '1';
        init_phase       <= '0';
     
      else

        case next_phase_state is

          -- state idle : outputs null
          when idle =>
            init_carrier_cnt <= '1';
            init_phase       <= '0';

          -- state run_ramp : calculation can operate
          when run_ramp =>
            init_carrier_cnt <= '0';
            init_phase       <= '0';

          -- state symbol_end : last rotation of the symbol
          when symbol_end =>
            init_carrier_cnt <= '0';
            init_phase       <= '0';

          when others =>
            null;
          
        end case;
      end if;
    end if;
  end process signal_value_p;


  -------------------------------------------------------------------
  -- State changement
  -------------------------------------------------------------------
  state_change_p : process (carrier_cnt,
                            estimate_done,
                            phase_state,
                            data_ready_i,
                            first_symbol,
                            start_of_symbol_ff1)
  begin
    
    next_phase_state <= phase_state;
    
    case phase_state is

      -- state idle : wait for estimate_done set
      when idle =>
        if (estimate_done = '1') or 
           (start_of_symbol_ff1 = '1' and first_symbol = '1') then
          next_phase_state <= run_ramp;
        end if;

      -- state run_ramp : run the calculation
      when run_ramp =>
          if carrier_cnt = "011010" then
            next_phase_state <= symbol_end;
          end if;

      -- state symbol_end : wait for the last sample of the symbol
      when symbol_end =>
        if data_ready_i = '1' then
          next_phase_state <= idle;
        end if;

      when others =>
        next_phase_state <= idle;

    end case;
  end process state_change_p;
  
  
  -------------------------------------------------------------------
  -- Phase calculation parameters sampling
  -------------------------------------------------------------------
  parameters_sampling_comb_p : process (estimate_done, cpe, sto,
                                        cpe_i, sto_i)
  begin
    d_cpe <= cpe;
    d_sto <= sto;
    if estimate_done = '1' then -- sampling parameters
      d_cpe <= cpe_i;
      d_sto <= sto_i;
    end if;
  end process parameters_sampling_comb_p;
   
  
  parameters_sampling_seq_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      cpe           <= (others => '0');
      sto           <= (others => '0');
      estimate_done <= '0'; -- for state machine: one clock delayed
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        cpe           <= (others => '0');
        sto           <= (others => '0');
        estimate_done <= '0';
      else
        cpe           <= d_cpe;
        sto           <= d_sto;
        estimate_done <= estimate_done_i;
      end if;
    end if;
  end process parameters_sampling_seq_p;


  -------------------------------------------------------------------
  -- Carrier calculation : carrier_cnt = -26....-1 0 1 ....26
  -------------------------------------------------------------------

  -- multiply by 26 : x^4 + x^3 + x^1
  carrier_value_n <= (sxt(d_sto & "0", carrier_value_n'length)    +
                      sxt(d_sto & "000", carrier_value_n'length)) +
                      sxt(d_sto & "0000", carrier_value_n'length);

  carrier_value_comb_p : process(carrier_cnt, carrier_value, 
                                 init_carrier_cnt, data_valid_i,
                                 d_sto, carrier_value_n,
                                 data_ready_i, pilot_valid_i)
  begin
    d_carrier_cnt     <= carrier_cnt;
    d_carrier_value   <= carrier_value;
    if init_carrier_cnt = '1' then
      d_carrier_cnt     <= "100110";
      d_carrier_value   <= not(carrier_value_n) + '1';
    elsif (data_valid_i = '1' or pilot_valid_i = '1') and
           data_ready_i = '1' then
      d_carrier_cnt   <= signed(carrier_cnt) + '1';
      d_carrier_value <= carrier_value + sxt(d_sto, carrier_value'length);
    end if;
  end process carrier_value_comb_p;

  
  carrier_value_seq_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      carrier_cnt     <= (others => '0');
      carrier_value   <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        carrier_cnt     <= (others => '0');
        carrier_value   <= (others => '0');
      else  
        carrier_cnt     <= d_carrier_cnt;
        carrier_value   <= d_carrier_value;
      end if;
    end if;
  end process carrier_value_seq_p;


  -------------------------------------------------------------------
  -- Signal detection : first symbol
  -------------------------------------------------------------------
  first_symbol_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      first_symbol   <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        first_symbol   <= '0';
      elsif start_of_burst_i = '1' then
        first_symbol   <= '1';
      elsif start_of_symbol_i = '1' and start_of_symbol_ff1 = '0' then
        first_symbol   <= '0';
      end if;
    end if;
  end process first_symbol_p;
  
  second_symbol_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      second_symbol   <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        second_symbol   <= '0';
      elsif start_of_burst_i = '1' then
        second_symbol   <= '0';
      elsif start_of_symbol_i = '1' and start_of_symbol_ff1 = '0' and
            first_symbol = '1' then
        second_symbol   <= '1';
      elsif start_of_symbol_i = '1' and start_of_symbol_ff1 = '0' then
        second_symbol   <= '0';
      end if;
    end if;
  end process second_symbol_p;
  
  
  -------------------------------------------------------------------
  -- Phase calculation : Phase = cpe + n*sto
  -------------------------------------------------------------------
  phase_value_comb_p : process(d_cpe, d_carrier_value, 
                               init_phase)
  begin
    if init_phase = '1' then
      d_phase <= (others => '0');
    else
      d_phase <=  not(sxt (d_cpe, d_phase'length) + sxt (d_carrier_value, d_phase'length)) + '1';
    end if;
  end process phase_value_comb_p;

  phase_value_seq_p : process(clk, reset_n)
  begin
    if reset_n = '0' then
      phase <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        phase <= (others => '0');
      else  
        phase <= d_phase;
      end if;
    end if;
  end process phase_value_seq_p;
  
  -------------------------------------------------------------------
  -- Phase saturation on 18-bit
  -------------------------------------------------------------------
  phase_sat <= sat_signed_slv(d_phase,4);

  -------------------------------------------------------------------
  -- Phase unwrapping : -pi < phase_sat < pi
  -------------------------------------------------------------------
   phase_sat_p : process(phase_unwrap, phase_sat)
   begin
     if signed(phase_sat) > signed(PI_CT) then
       phase_unwrap <= phase_sat - TWO_PI_CT;
     elsif signed(phase_sat) < signed(INV_PI_CT) then
       phase_unwrap <= phase_sat + TWO_PI_CT;
     else
       phase_unwrap <= phase_sat;
     end if;
   end process phase_sat_p;

  -------------------------------------------------------------------
  -- Cordic phase saturation on 12-bit
  -------------------------------------------------------------------
  cordic_phase_sat <= sat_signed_slv(phase_unwrap(17 downto 4),2);

  -------------------------------------------------------------------
  -- Cordic
  -------------------------------------------------------------------
  all_zero <= (others => '0'); -- for unused inputs

  cordic_1 : cordic
  generic map(
    -- number of bits for the complex data :
    data_length_g   => 12,
    -- number of bits for the input angle z_in :
    angle_length_g  => 12,
    -- number of microrotation stages in a combinational path :
    nbr_combstage_g => 4, -- must be > 0
    -- number of pipes
    nbr_pipe_g      => 3,  -- must be > 0
    -- NOTE : the total number of microrotations is nbr_combstage_g * nbr_pipe_g
    -- number of input used
    nbr_input_g     => 1,  -- must be > 0
    scaling_g       => 0
  )
  port map(
        clk      => clk,
        reset_n  => reset_n,
        enable   => data_ready_i,
        -- angle with which the inputs must be rotated :
        z_in     => cordic_phase_sat,
        -- inputs to be rotated :
        x0_in    => data_i_i,
        y0_in    => data_q_i,
        x1_in    => all_zero,
        y1_in    => all_zero,
        x2_in    => all_zero,
        y2_in    => all_zero,
        x3_in    => all_zero,
        y3_in    => all_zero,
        -- rotated output. They have been rotated of z_in :
        x0_out   => cordic_x_out,
        y0_out   => cordic_y_out,
        x1_out   => open,
        y1_out   => open,
        x2_out   => open,
        y2_out   => open,
        x3_out   => open,
        y3_out   => open
        );

  -- Cordic normalization : multiply by 0.607177734 = 0.100110110111
  coef_cordic_norm <= "0100110110111";
  cordic_x_mul     <= signed(cordic_x_out) * signed(coef_cordic_norm);
  cordic_y_mul     <= signed(cordic_y_out) * signed(coef_cordic_norm);
  


  -------------------------------------------------------------------
  -- Outputs
  -------------------------------------------------------------------
  data_ready_o <= data_ready_i when 
        (next_phase_state = run_ramp or next_phase_state = symbol_end)
            else '0';
  
  data_valid_ff_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      data_valid_ff1 <= '0';
      data_valid_ff2 <= '0';
      data_valid_ff3 <= '0';
      data_valid_ff4 <= '0';
      data_valid_o   <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        data_valid_ff1 <= '0';
        data_valid_ff2 <= '0';
        data_valid_ff3 <= '0';
        data_valid_ff4 <= '0';
        data_valid_o   <= '0';
      else
        if (data_ready_i = '1') then
          if first_symbol = '1' then
            data_valid_o <= data_valid_i;
            data_valid_ff1 <= '0'; -- to prevent errors in signal symbol after first_symbol is deasserted
          else
            data_valid_ff1 <= data_valid_i;
            data_valid_ff2 <= data_valid_ff1;
            data_valid_ff3 <= data_valid_ff2;
            data_valid_ff4 <= data_valid_ff3;
            data_valid_o   <= data_valid_ff4;
          end if;
        end if;
      end if;
    end if;
  end process data_valid_ff_p;

  --  data_valid_o <= data_valid_ff5;

  -- Data output
  data_out_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_i_o <= (others => '0');
      data_q_o <= (others => '0');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        data_i_o <= (others => '0');
        data_q_o <= (others => '0');
      else
        if (data_ready_i = '1') then
          if first_symbol = '1' then
            data_i_o <= data_i_i;
            data_q_o <= data_q_i;
          else
            data_i_o <= sat_signed_slv(cordic_x_mul(26 downto 12),3);
            data_q_o <= sat_signed_slv(cordic_y_mul(26 downto 12),3);
          end if;
        end if;
      end if;
    end if;
  end process data_out_p;
  

  -- Start of burst & symbol control
  start_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      start_of_burst_o     <= '0';
      start_of_symbol_o    <= '0';
      start_of_symbol_o_s  <= '0';
      start_of_symbol_o_s1 <= '0';
      start_of_symbol_o_s2 <= '0'; 
      start_of_symbol_o_s3 <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        start_of_burst_o     <= '0';
        start_of_symbol_o    <= '0';
        start_of_symbol_o_s  <= '0';
        start_of_symbol_o_s1 <= '0';
        start_of_symbol_o_s2 <= '0'; 
        start_of_symbol_o_s3 <= '0';
      else
        start_of_burst_o  <= start_of_burst_i;
        --start_of_symbol_o_s <= start_of_symbol_i;
        if (start_of_symbol_i = '1') then
          if (start_of_burst_i = '1') or
             (signal_valid_i = '1' and second_symbol = '1') or
             (estimate_done_i = '1' and second_symbol = '0') then
            start_of_symbol_o_s <= '1';
          else
            start_of_symbol_o_s <= '0';
          end if; 
        else
          start_of_symbol_o_s <= '0';
        end if;
        
        IF first_symbol = '1' THEN
          start_of_symbol_o <= start_of_symbol_o_s;
        ELSE
          start_of_symbol_o_s1 <= start_of_symbol_o_s;
          start_of_symbol_o_s2 <= start_of_symbol_o_s1;
          start_of_symbol_o_s3 <= start_of_symbol_o_s2;
          start_of_symbol_o    <= start_of_symbol_o_s3;          
        END IF;
        
        
      end if;
    end if;
  end process start_p;


end RTL;
