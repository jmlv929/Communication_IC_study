

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of iq_compensation is

  ------------------------------------------------------------------------------
  -- Signals 
  ------------------------------------------------------------------------------
  -- NOTATION:
  --  * the postfix 'nr' means not-registered signal
  --  * the postfix 'ff' means delayed signal
  --  * no postfix  means registered signal
  --  * the postfix 'v' means variable

  -- Registered signals for phase compensation.
  signal i_in_ff             : std_logic_vector(iq_i_width_g-1 downto 0);
  signal q_in_ff             : std_logic_vector(iq_i_width_g-1 downto 0);
  -- Signals for phase compensation.
  signal i_phase1_nr         : std_logic_vector(iq_i_width_g+phase_width_g-9 downto 0);
  signal q_phase1_nr         : std_logic_vector(iq_i_width_g+phase_width_g-9 downto 0);
  -- Registered Signals with compensated phase.
  signal i_phase1            : std_logic_vector(iq_i_width_g+phase_width_g-9 downto 0);
  signal q_phase1            : std_logic_vector(iq_i_width_g+phase_width_g-9 downto 0);
  -- Signals with compensated phase.
  signal i_phase2_nr         : std_logic_vector(iq_i_width_g+phase_width_g-6 downto 0);
  signal q_phase2_nr         : std_logic_vector(iq_i_width_g+phase_width_g-7 downto 0);
  -- Registered signals with compensated phase.
  -- I Phase in longer as the last bit is required for division
  signal i_phase2            : std_logic_vector(iq_i_width_g+phase_width_g-6 downto 0);
  signal q_phase2            : std_logic_vector(iq_i_width_g+phase_width_g-7 downto 0);
  signal i_phase2_7lsb       : std_logic_vector(iq_i_width_g+phase_width_g+1 downto 0);
  -- Signals for amplitude compensation.
  signal q_ampl_nr           : std_logic_vector(iq_o_width_g-1 downto 0);
  signal i_ampl_nr           : std_logic_vector(iq_i_width_g+phase_width_g+1 downto 0);
  signal i_amplsat_nr        : std_logic_vector(iq_o_width_g-1 downto 0);
  -- Registered signals for amplitude compensation.
  signal q_ampl              : std_logic_vector(iq_o_width_g-1 downto 0);
  -- registers to compensate the Q divider delay.
  signal q_ampl_ff1          : std_logic_vector(iq_o_width_g-1 downto 0);
  signal q_ampl_ff2          : std_logic_vector(iq_o_width_g-1 downto 0);
  signal q_ampl_ff3          : std_logic_vector(iq_o_width_g-1 downto 0);
  signal q_ampl_ff4          : std_logic_vector(iq_o_width_g-1 downto 0);
  -- Signals for data_valid_o
  signal data_valid_ff_pulse : std_logic;
  signal data_valid_ff       : std_logic;
  signal valid_enable        : std_logic;
  signal valid_enable_ff     : std_logic;
  signal data_valid_out      : std_logic;
  

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------     NO SYNCHRONOUS RESET     ------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  NO_SYNC_RESET_GEN : if use_sync_reset_g = 0 generate

  -- =================================================================
  -- Phase Compensation processes
  -- =================================================================

  -------------------------------------------------------------------
  -- Phase Compensation 1
  -------------------------------------------------------------------
  --            i_phase1 = (i_in * phase_i)/2^(n_shift), with n_shift = 9
  --            q_phase1 = (q_in * phase_i)/2^(n_shift)
  phase_comp1_p : process (i_in, phase_i, q_in)
    variable mult_i_v       : std_logic_vector(iq_i_width_g+phase_width_g-1 downto 0);
    variable mult_q_v       : std_logic_vector(iq_i_width_g+phase_width_g-1 downto 0);
    variable mult_i_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-8 downto 0);
    variable mult_q_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-8 downto 0);
  begin

    -- Multiply.
    mult_i_v := signed(i_in) * signed(phase_i);
    mult_q_v := signed(q_in) * signed(phase_i);

    mult_i_trunc_v := mult_i_v (mult_i_v'high downto 7) + '1';
    mult_q_trunc_v := mult_q_v (mult_q_v'high downto 7) + '1';
    
    -- Truncation - remove 8 LSBs - round precision
    i_phase1_nr <= mult_i_trunc_v(mult_i_trunc_v'high downto 1);
    q_phase1_nr <= mult_q_trunc_v(mult_q_trunc_v'high downto 1);
                   
  end process phase_comp1_p;

  -- memorize result and input
  phase_comp1_seq_p: process (clk, reset_n)
  begin  -- process phase_comp1_seq_p
    if reset_n = '0' then               
      i_in_ff <= (others => '0');
      q_in_ff <= (others => '0');
      i_phase1 <= (others => '0');
      q_phase1 <= (others => '0');
    elsif clk'event and clk = '1' then  
      i_in_ff  <= i_in; 
      q_in_ff  <= q_in;
      i_phase1 <= i_phase1_nr;
      q_phase1 <= q_phase1_nr;
    end if;
  end process phase_comp1_seq_p;

  -------------------------------------------------------------------
  -- Phase Compensation 2
  -------------------------------------------------------------------
  --        i_phase2 = i_in + q_phase1
  --        q_phase2 = q_in + i_phase1
  -- The computation is done with one more precision LSB and
  -- rounded to the nearest value.
  phase_comp2_p : process (i_in_ff, i_phase1, q_in_ff, q_phase1)
    variable i_add_v : std_logic_vector(iq_i_width_g+phase_width_g-5 downto 0);
    variable q_add_v : std_logic_vector(iq_i_width_g+phase_width_g-5 downto 0);
  begin

    -- Add.
    i_add_v := sxt((i_in_ff & '0'),iq_i_width_g+phase_width_g-4)
             + sxt(q_phase1,iq_i_width_g+phase_width_g-4);
             
    q_add_v := sxt((q_in_ff & '0'),iq_i_width_g+phase_width_g-4)
             + sxt(i_phase1,iq_i_width_g+phase_width_g-4);

    -- Rounding only on q - keep LSB precision for i calculation 
    --q_phase2_nr <= q_add_v(q_add_v'high downto 1) + q_add_v(0);
    q_phase2_nr <= sat_round_signed_slv(q_add_v,1,1);
    --i_phase2_nr <= i_add_v;
    i_phase2_nr <= sat_signed_slv(i_add_v,1);

  end process phase_comp2_p;

  -- memorize result 
  phase_comp2_seq_p: process (clk, reset_n)
  begin  -- process phase_comp2_seq_p
    if reset_n = '0' then               
      i_phase2 <= (others => '0');
      q_phase2 <= (others => '0');
    elsif clk'event and clk = '1' then  
      i_phase2 <= i_phase2_nr;
      q_phase2 <= q_phase2_nr;
    end if;
  end process phase_comp2_seq_p;
  
  -- =================================================================
  -- End of Phase Compensation processes
  -- ================================================================= 

  -- =================================================================
  -- Amplitude Compensation processes
  -- =================================================================
  -- Purpose : compensation of the amplitude mismatch.

  --------------------------------------------------------------------
  -- Amplitude Compensation Q
  --------------------------------------------------------------------
  --            i_ampl = i_phase2 * ampl_i
  ampl_compi_p : process (ampl_i, q_phase2)
    variable mult_v       : std_logic_vector(iq_i_width_g+phase_width_g-5+ampl_width_g-1 downto 0);
    variable mult_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-14+ampl_width_g-1 downto 0);
  begin

    -- Multiply.
    mult_v := signed(q_phase2) * unsigned(ampl_i);

    -- MSB of multiplication is never significative => can be removed
    -- Cast result to output data size : 8-bits truncation + 1 bit saturation
    mult_trunc_v := mult_v(mult_v'high-1 downto 8);
    q_ampl_nr    <= sat_signed_slv(mult_trunc_v,1);

  end process ampl_compi_p;

  --------------------------------------------------------------------
  -- Amplitude Compensation I
  --------------------------------------------------------------------
  --            q_ampl = qint / ampl_i
  -- Pipeline delay of 2 clock cycles.

  -- Add 8 LSB before sending to divider
  i_phase2_7lsb <= i_phase2 & "0000000";

  -- Instantiate euclidian divider
  eucl_divider_top_1 : eucl_divider_top
    generic map (
      nb_stage_g => 4,
      dsize_g    => ampl_width_g,   -- 9
      zsize_g    => iq_i_width_g+phase_width_g+2, --19
      qsize_g    => iq_i_width_g+phase_width_g+2, -- 19
      d_neg_g    => 0,
      z_neg_g    => 1
      )
    port map (
      reset_n => reset_n,
      clk     => clk,
      z_in    => i_phase2_7lsb,
      d_in    => ampl_i,
      q_out   => i_ampl_nr
      );

  -- saturate : remove 8 MSB
  i_amplsat_nr <= sat_signed_slv(i_ampl_nr,8);

  -----------------------------------------------------------------------------
  -- Memorize result
  -----------------------------------------------------------------------------
  registers_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      -- Pipeline registers in amplitude compensation processes.
      q_ampl              <= (others => '0');
      q_ampl_ff1          <= (others => '0');
      q_ampl_ff2          <= (others => '0');
      q_ampl_ff3          <= (others => '0');
      q_ampl_ff4          <= (others => '0');
      -- Outputs.
      i_out               <= (others => '0');
      q_out               <= (others => '0');
      data_valid_ff       <= '0';
      data_valid_ff_pulse <= '0';
      data_valid_out      <= '0';
    elsif clk'event and clk = '1' then
      data_valid_ff <= data_valid_i;
      if toggle_in_g = 0 then
        -- data_valid_i is a pulse 
        data_valid_ff_pulse <= data_valid_i;
      else
        -- data_valid_i is a toggle
        if data_valid_i /= data_valid_ff then
          data_valid_ff_pulse <= '1'; -- tog => pulse
        else
          data_valid_ff_pulse <= '0';
        end if;
      end if;
      
      if toggle_out_g = 0 then
        -- data_valid_o is a pulse 
        data_valid_out  <= data_valid_ff_pulse and valid_enable_ff;
      else
        -- data_valid_o is a toggle
        if data_valid_ff_pulse = '1' and valid_enable_ff = '1'  then
          data_valid_out <= not data_valid_out;
        end if;
          
      end if;
      -- Pipeline registers in amplitude compensation processes.
      q_ampl      <= q_ampl_nr;
      q_ampl_ff1  <= q_ampl;
      q_ampl_ff2  <= q_ampl_ff1;
      q_ampl_ff3  <= q_ampl_ff2;
      q_ampl_ff4  <= q_ampl_ff3;
      -- Outputs.
      i_out       <= i_amplsat_nr;
      q_out       <= q_ampl_ff4;
    end if;
  end process registers_p;

  data_valid_o <= data_valid_out;
  
  -- =================================================================
  -- End of Amplitude Compensation processes
  -- =================================================================

    
  -- This process generates an enable for data_valid_o.
  -- data_valid_i is a signal at 20 MHz. The clock is at 80 MHz. The compensated
  -- data is ready in 8 clock cycles. data_valid_o must be enabled after the
  -- second data_valid_i.
  data_valid_cnt: process (clk, reset_n)
  begin
    if reset_n = '0' then
      valid_enable    <= '0';
      valid_enable_ff <= '0';
    elsif clk'event and clk = '1' then
      if data_valid_ff_pulse = '1' then
        valid_enable    <= '1';
        valid_enable_ff <= valid_enable;
      end if;
    end if;
  end process data_valid_cnt;


  end generate NO_SYNC_RESET_GEN;


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  ------------------------     SYNCHRONOUS RESET     --------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  SYNC_RESET_GEN : if use_sync_reset_g = 1 generate

  -- =================================================================
  -- Phase Compensation processes
  -- =================================================================

  -------------------------------------------------------------------
  -- Phase Compensation 1
  -------------------------------------------------------------------
  --            i_phase1 = (i_in * phase_i)/2^(n_shift), with n_shift = 9
  --            q_phase1 = (q_in * phase_i)/2^(n_shift)
  phase_comp1_p : process (i_in, phase_i, q_in)
    variable mult_i_v       : std_logic_vector(iq_i_width_g+phase_width_g-1 downto 0);
    variable mult_q_v       : std_logic_vector(iq_i_width_g+phase_width_g-1 downto 0);
    variable mult_i_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-8 downto 0);
    variable mult_q_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-8 downto 0);
  begin

    -- Multiply.
    mult_i_v := signed(i_in) * signed(phase_i);
    mult_q_v := signed(q_in) * signed(phase_i);

    mult_i_trunc_v := mult_i_v (mult_i_v'high downto 7) + '1';
    mult_q_trunc_v := mult_q_v (mult_q_v'high downto 7) + '1';
    
    -- Truncation - remove 8 LSBs - round precision
    i_phase1_nr <= mult_i_trunc_v(mult_i_trunc_v'high downto 1);
    q_phase1_nr <= mult_q_trunc_v(mult_q_trunc_v'high downto 1);
                   
  end process phase_comp1_p;

  -- memorize result and input
  phase_comp1_seq_p: process (clk, reset_n)
  begin  -- process phase_comp1_seq_p
    if reset_n = '0' then               
      i_in_ff <= (others => '0');
      q_in_ff <= (others => '0');
      i_phase1 <= (others => '0');
      q_phase1 <= (others => '0');
    elsif clk'event and clk = '1' then  
      if sync_reset_n = '0' then
        i_in_ff  <= (others => '0');
        q_in_ff  <= (others => '0');
        i_phase1 <= (others => '0');
        q_phase1 <= (others => '0');
      else
        i_in_ff  <= i_in; 
        q_in_ff  <= q_in;
        i_phase1 <= i_phase1_nr;
        q_phase1 <= q_phase1_nr;
      end if;
    end if;
  end process phase_comp1_seq_p;

  -------------------------------------------------------------------
  -- Phase Compensation 2
  -------------------------------------------------------------------
  --        i_phase2 = i_in + q_phase1
  --        q_phase2 = q_in + i_phase1
  -- The computation is done with one more precision LSB and
  -- rounded to the nearest value.
  phase_comp2_p : process (i_in_ff, i_phase1, q_in_ff, q_phase1)
    variable i_add_v : std_logic_vector(iq_i_width_g+phase_width_g-5 downto 0);
    variable q_add_v : std_logic_vector(iq_i_width_g+phase_width_g-5 downto 0);
  begin

    -- Add.
    i_add_v := sxt((i_in_ff & '0'),iq_i_width_g+phase_width_g-4)
             + sxt(q_phase1,iq_i_width_g+phase_width_g-4);
             
    q_add_v := sxt((q_in_ff & '0'),iq_i_width_g+phase_width_g-4)
             + sxt(i_phase1,iq_i_width_g+phase_width_g-4);

    -- Rounding only on q - keep LSB precision for i calculation 
    --q_phase2_nr <= q_add_v(q_add_v'high downto 1) + q_add_v(0);
    q_phase2_nr <= sat_round_signed_slv(q_add_v,1,1);
    --i_phase2_nr <= i_add_v;
    i_phase2_nr <= sat_signed_slv(i_add_v,1);

  end process phase_comp2_p;

  -- memorize result 
  phase_comp2_seq_p: process (clk, reset_n)
  begin  -- process phase_comp2_seq_p
    if reset_n = '0' then               
      i_phase2 <= (others => '0');
      q_phase2 <= (others => '0');
    elsif clk'event and clk = '1' then  
      if sync_reset_n = '0' then
        i_phase2 <= (others => '0');
        q_phase2 <= (others => '0');
      else
        i_phase2 <= i_phase2_nr;
        q_phase2 <= q_phase2_nr;
      end if;
    end if;
  end process phase_comp2_seq_p;
  
  -- =================================================================
  -- End of Phase Compensation processes
  -- ================================================================= 

  -- =================================================================
  -- Amplitude Compensation processes
  -- =================================================================
  -- Purpose : compensation of the amplitude mismatch.

  --------------------------------------------------------------------
  -- Amplitude Compensation Q
  --------------------------------------------------------------------
  --            i_ampl = i_phase2 * ampl_i
  ampl_compi_p : process (ampl_i, q_phase2)
    variable mult_v       : std_logic_vector(iq_i_width_g+phase_width_g-5+ampl_width_g-1 downto 0);
    variable mult_trunc_v : std_logic_vector(iq_i_width_g+phase_width_g-14+ampl_width_g-1 downto 0);
  begin

    -- Multiply.
    mult_v := signed(q_phase2) * unsigned(ampl_i);

    -- MSB of multiplication is never significative => can be removed
    -- Cast result to output data size : 8-bits truncation + 1 bit saturation
    mult_trunc_v := mult_v(mult_v'high-1 downto 8);
    q_ampl_nr    <= sat_signed_slv(mult_trunc_v,1);

  end process ampl_compi_p;

  --------------------------------------------------------------------
  -- Amplitude Compensation I
  --------------------------------------------------------------------
  --            q_ampl = qint / ampl_i
  -- Pipeline delay of 2 clock cycles.

  -- Add 8 LSB before sending to divider
  i_phase2_7lsb <= i_phase2 & "0000000";

  -- Instantiate euclidian divider
  eucl_divider_top_1 : eucl_divider_top
    generic map (
      nb_stage_g => 4,
      dsize_g    => ampl_width_g,   -- 9
      zsize_g    => iq_i_width_g+phase_width_g+2, --19
      qsize_g    => iq_i_width_g+phase_width_g+2, -- 19
      d_neg_g    => 0,
      z_neg_g    => 1
      )
    port map (
      reset_n => reset_n,
      clk     => clk,
      z_in    => i_phase2_7lsb,
      d_in    => ampl_i,
      q_out   => i_ampl_nr
      );

  -- saturate : remove 8 MSB
  i_amplsat_nr <= sat_signed_slv(i_ampl_nr,8);

  -----------------------------------------------------------------------------
  -- Memorize result
  -----------------------------------------------------------------------------
  registers_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      -- Pipeline registers in amplitude compensation processes.
      q_ampl              <= (others => '0');
      q_ampl_ff1          <= (others => '0');
      q_ampl_ff2          <= (others => '0');
      q_ampl_ff3          <= (others => '0');
      q_ampl_ff4          <= (others => '0');
      -- Outputs.
      i_out               <= (others => '0');
      q_out               <= (others => '0');
      data_valid_ff       <= '0';
      data_valid_ff_pulse <= '0';
      data_valid_out      <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        -- Pipeline registers in amplitude compensation processes.
        q_ampl              <= (others => '0');
        q_ampl_ff1          <= (others => '0');
        q_ampl_ff2          <= (others => '0');
        q_ampl_ff3          <= (others => '0');
        q_ampl_ff4          <= (others => '0');
        -- Outputs.
        i_out               <= (others => '0');
        q_out               <= (others => '0');
        data_valid_ff       <= '0';
        data_valid_ff_pulse <= '0';
        data_valid_out      <= '0';
      else
        data_valid_ff <= data_valid_i;
        if toggle_in_g = 0 then
          -- data_valid_i is a pulse 
          data_valid_ff_pulse <= data_valid_i;
        else
          -- data_valid_i is a toggle
          if data_valid_i /= data_valid_ff then
            data_valid_ff_pulse <= '1'; -- tog => pulse
          else
            data_valid_ff_pulse <= '0';
          end if;
        end if;
        
        if toggle_out_g = 0 then
          -- data_valid_o is a pulse 
          data_valid_out  <= data_valid_ff_pulse and valid_enable_ff;
        else
          -- data_valid_o is a toggle
          if data_valid_ff_pulse = '1' and valid_enable_ff = '1'  then
            data_valid_out <= not data_valid_out;
          end if;
            
        end if;
        -- Pipeline registers in amplitude compensation processes.
        q_ampl      <= q_ampl_nr;
        q_ampl_ff1  <= q_ampl;
        q_ampl_ff2  <= q_ampl_ff1;
        q_ampl_ff3  <= q_ampl_ff2;
        q_ampl_ff4  <= q_ampl_ff3;
        -- Outputs.
        i_out       <= i_amplsat_nr;
        q_out       <= q_ampl_ff4;
      end if;
    end if;
  end process registers_p;

  data_valid_o <= data_valid_out;
  
  -- =================================================================
  -- End of Amplitude Compensation processes
  -- =================================================================

    
  -- This process generates an enable for data_valid_o.
  -- data_valid_i is a signal at 20 MHz. The clock is at 80 MHz. The compensated
  -- data is ready in 8 clock cycles. data_valid_o must be enabled after the
  -- second data_valid_i.
  data_valid_cnt: process (clk, reset_n)
  begin
    if reset_n = '0' then
      valid_enable    <= '0';
      valid_enable_ff <= '0';
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' then
        valid_enable    <= '0';
        valid_enable_ff <= '0';
      elsif data_valid_ff_pulse = '1' then
        valid_enable    <= '1';
        valid_enable_ff <= valid_enable;
      end if;
    end if;
  end process data_valid_cnt;
  
  end generate SYNC_RESET_GEN;

end RTL;
