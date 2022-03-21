

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of iq_estimation is
  
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant G_EST_SIZE_CT       : integer := gain_width_g;
  constant PH_EST_SIZE_CT      : integer := phase_width_g;
  constant PSET_SIZE_CT        : integer := preset_width_g;
  constant G_IQ_ACCUM_SIZE_CT  : integer := 10;
  constant PH_IQ_ACCUM_SIZE_CT : integer := 14;

  constant ZEROS_G_EST_SIZEM1_CT   : std_logic_vector(G_EST_SIZE_CT-2 downto 0)
                                       := (others => '0');
  constant G_EST_INIT_CT           : std_logic_vector(G_EST_SIZE_CT-1 downto 0)
                                       := '1' & ZEROS_G_EST_SIZEM1_CT;
  constant ONE_PH_IQ_ACCUM_SIZE_CT : std_logic_vector(PH_IQ_ACCUM_SIZE_CT-1 downto 0)
                                       := (0 => '1', others => '0');
   
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal i_5bit_reg       : std_logic_vector(4 downto 0);
  signal q_5bit_reg       : std_logic_vector(4 downto 0);
  signal samp_cnt_reg     : std_logic_vector(6 downto 0);
  signal i_accum_reg      : std_logic_vector(G_IQ_ACCUM_SIZE_CT-1 downto 0);
  signal q_accum_reg      : std_logic_vector(G_IQ_ACCUM_SIZE_CT-1 downto 0);
  signal iq_prod_reg      : std_logic_vector((2*5)-1 downto 0);
  signal iq_accum_reg     : std_logic_vector(PH_IQ_ACCUM_SIZE_CT-1 downto 0);
  signal iq_accum_sat     : std_logic_vector((PH_IQ_ACCUM_SIZE_CT/2)-1 downto 0);

  signal iq_accum_ovflow_pos : std_logic;
  signal iq_accum_ovflow_neg : std_logic;
  signal iq_accum_ovflow     : std_logic;

  signal i_u : std_logic_vector(G_IQ_ACCUM_SIZE_CT downto 0);
  signal q_u : std_logic_vector(G_IQ_ACCUM_SIZE_CT downto 0);

  signal i_5bit_u   : std_logic_vector(4 downto 0);
  signal q_5bit_u   : std_logic_vector(4 downto 0);

  signal iq_prod_ovflow : std_logic;
  signal iq_prod_sat_wd : std_logic_vector((PH_IQ_ACCUM_SIZE_CT/2)-2 downto 0);
  signal iq_prod_sat    : std_logic_vector((PH_IQ_ACCUM_SIZE_CT/2)-2 downto 0);
  signal iq_prod_one    : std_logic_vector((PH_IQ_ACCUM_SIZE_CT/2)-1 downto 0);
  signal iq_prod_signed : std_logic_vector((PH_IQ_ACCUM_SIZE_CT/2)-1 downto 0);
  
  signal samp_cnt_nxt   : std_logic_vector(6 downto 0);
  signal sym_per_done   : std_logic;
  signal reset_g_accum  : std_logic;
  signal reset_ph_accum : std_logic;

  signal est_start    : std_logic;
  signal g_est_start  : std_logic;
  signal ph_est_start : std_logic;
  signal ctrl_cnt_en  : std_logic;
  signal ctrl_cnt     : std_logic_vector(5 downto 0);
  signal initialise   : std_logic;

  signal g_est_valid  : std_logic;
  signal ph_est_valid : std_logic;
  signal g_est        : std_logic_vector(G_EST_SIZE_CT-1 downto 0);
  signal ph_est       : std_logic_vector(PH_EST_SIZE_CT-1 downto 0);

  signal rnd     : std_logic;
  signal sat     : std_logic;
  signal rnd_i   : std_logic;
  signal rnd_q   : std_logic;
  signal sign_i  : std_logic;
  signal sign_q  : std_logic;
  signal sign_iq : std_logic;
  
  signal end_of_packet : std_logic;
  
begin


  -- Reset estimation done
  reset_estim_done_p: process (clk, reset_n)
  begin  -- process reset_estim_done_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      iqmm_reset_done <= '0';
    elsif clk'event and clk = '1' then
      if rx_iqmm_reset = '1' then
        iqmm_reset_done <= '1';
      else
        iqmm_reset_done <= '0';
      end if;
    end if;
  end process reset_estim_done_p;
  
  

  -- Register i_in and q_in data inputs on data_valid_in
  -- and increment sample_cnt.
  reg_data_p: process (clk, reset_n)
    variable i_sat_v : std_logic;
    variable q_sat_v : std_logic;
  begin  -- process reg_data_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      rnd            <= '0';
      sat            <= '0';
      rnd_i          <= '0';
      rnd_q          <= '0';
      sign_i         <= '0';
      sign_q         <= '0';
      i_5bit_reg     <= (others => '0');
      q_5bit_reg     <= (others => '0');
      samp_cnt_reg   <= (others => '0');
      reset_g_accum  <= '0';
      reset_ph_accum <= '0';
      i_sat_v        := '0';
      q_sat_v        := '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if rx_iqmm_reset = '1' or rx_iqmm_est_en = '0' then 
          rnd_i          <= '0';
          rnd_q          <= '0';
          sign_i         <= '0';
          sign_q         <= '0';
          i_5bit_reg     <= (others => '0');
          q_5bit_reg     <= (others => '0');
          samp_cnt_reg   <= (others => '0');
          reset_g_accum  <= '0';
          reset_ph_accum <= '0';
      elsif rx_iqmm_est_en = '1' then   -- estimation enabled

        rnd <= data_valid_in;
        sat <= rnd;
               
        if data_valid_in = '1' then -- register input i and q data
          rnd_i <= i_in(5);
          rnd_q <= q_in(5);
          i_5bit_reg     <= i_in(iq_i_width_g-1 downto 6);
          q_5bit_reg     <= q_in(iq_i_width_g-1 downto 6);          
          samp_cnt_reg   <= samp_cnt_nxt;
          -- reset gain and phase accumulators at start of symbol period
          reset_g_accum  <= sym_per_done;
          reset_ph_accum <= reset_g_accum;
        elsif rnd = '1' then -- round
          sign_i     <= i_5bit_reg(4);
          sign_q     <= q_5bit_reg(4);
          i_5bit_reg <= i_5bit_reg + rnd_i;
          q_5bit_reg <= q_5bit_reg + rnd_q;
        elsif sat = '1' then -- saturate
          -- Addition of 1 can only cause overflow in +ve direction
          i_sat_v := ((not sign_i) and i_5bit_reg(4));
          q_sat_v := ((not sign_q) and q_5bit_reg(4));
          if i_sat_v = '1' then i_5bit_reg <= "01111"; end if;
          if q_sat_v = '1' then q_5bit_reg <= "01111"; end if;
        end if;

      end if;
    end if;
  end process reg_data_p;


  -- Count 80 samples = 1 symbol period
  sym_per_done <= '1' when samp_cnt_reg = "1010000" else '0';
  samp_cnt_nxt <= samp_cnt_reg + "0000001" when sym_per_done = '0' else
                  "0000001";

    
  -- Get absolute values of I and Q for GAIN MISMATCH ESTIMATE
  -- and extend to 10-bits for the accumulator addition.
  i_u <= sxt(abs(signed(i_5bit_reg)), G_IQ_ACCUM_SIZE_CT+1);
  q_u <= sxt(abs(signed(q_5bit_reg)), G_IQ_ACCUM_SIZE_CT+1);

  -- Perform accumulation of absolute values of I and Q for GAIN
  -- MISMATCH ESTIMATE with saturation.
  iq_accum_p: process (clk, reset_n)   
    variable i_accum_v  : std_logic_vector(G_IQ_ACCUM_SIZE_CT downto 0);
    variable q_accum_v  : std_logic_vector(G_IQ_ACCUM_SIZE_CT downto 0);
    variable i_sat_v    : std_logic_vector(G_IQ_ACCUM_SIZE_CT-1 downto 0);
    variable q_sat_v    : std_logic_vector(G_IQ_ACCUM_SIZE_CT-1 downto 0);
  begin  -- process iq_accum_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      i_accum_v   := (others => '0');
      q_accum_v   := (others => '0');
      i_sat_v     := (others => '0');
      q_sat_v     := (others => '0');
      i_accum_reg <= (others => '0');
      q_accum_reg <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if rx_iqmm_reset = '1' or rx_iqmm_est_en = '0' then
          i_accum_v   := (others => '0');
          q_accum_v   := (others => '0');
          i_sat_v     := (others => '0');
          q_sat_v     := (others => '0');
          i_accum_reg <= (others => '0');
          q_accum_reg <= (others => '0');
      elsif rx_iqmm_est_en = '1' then   -- estimation enabled
             
        if data_valid_in = '1' then -- accumulate

          if reset_g_accum = '1' then -- reset accumulators
            i_accum_v   := i_u;
            q_accum_v   := q_u;
          else
            i_accum_v   := ('0' & i_accum_reg) + i_u;
            q_accum_v   := ('0' & q_accum_reg) + q_u;
          end if;

          -- build saturation words
          i_sat_v     := (others => i_accum_v(G_IQ_ACCUM_SIZE_CT));
          q_sat_v     := (others => q_accum_v(G_IQ_ACCUM_SIZE_CT));
          i_accum_reg <= i_accum_v(G_IQ_ACCUM_SIZE_CT-1 downto 0);
          q_accum_reg <= q_accum_v(G_IQ_ACCUM_SIZE_CT-1 downto 0);

        elsif sat = '1' then -- saturate
          i_accum_reg <= i_accum_reg or i_sat_v;
          q_accum_reg <= q_accum_reg or q_sat_v;
        end if;     

      end if;
    end if;
  end process iq_accum_p;

  
  -- Perform signed multiplication and accumulation of I and Q for 
  -- PHASE MISMATCH ESTIMATE with saturation.
  i_5bit_u <= i_u(4 downto 0);
  q_5bit_u <= q_u(4 downto 0);  

  -- saturate iq_prod on overflow ...
  iq_prod_ovflow <= or_reduce(iq_prod_reg((2*5)-1 downto (PH_IQ_ACCUM_SIZE_CT/2)-1));
  iq_prod_sat_wd <= (others => iq_prod_ovflow);
  iq_prod_sat    <= iq_prod_reg((PH_IQ_ACCUM_SIZE_CT/2)-2 downto 0) or iq_prod_sat_wd;
  -- ... and re-sign
  iq_prod_one    <= (0 => not iq_prod_ovflow, others => '0');
  iq_prod_signed <= '0' & iq_prod_sat when sign_iq = '0' else 
                    not ('0' & iq_prod_sat) + iq_prod_one;

  -- saturate iq_accum on overflow
  iq_accum_ovflow_pos <= ((not iq_accum_reg(PH_IQ_ACCUM_SIZE_CT-1)) and
                          or_reduce(iq_accum_reg(PH_IQ_ACCUM_SIZE_CT-2 downto (PH_IQ_ACCUM_SIZE_CT/2)-1)));
  iq_accum_ovflow_neg <= iq_accum_reg(PH_IQ_ACCUM_SIZE_CT-1) and
                          nand_reduce(iq_accum_reg(PH_IQ_ACCUM_SIZE_CT-2 downto (PH_IQ_ACCUM_SIZE_CT/2)-1));

  iq_accum_ovflow <= iq_accum_ovflow_pos or iq_accum_ovflow_neg;
  
  iq_accum_sat <= "1000000" when iq_accum_ovflow_neg = '1' else "0111111";
  
  iq_mac_p: process (clk, reset_n)
  begin 
    if reset_n = '0' then               -- asynchronous reset (active low)
      iq_prod_reg      <= (others => '0');
      iq_accum_reg     <= (others => '0');
      sign_iq          <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge   
      if rx_iqmm_reset = '1' or rx_iqmm_est_en = '0' then 
        iq_prod_reg    <= (others => '0');
        iq_accum_reg   <= (others => '0');
        sign_iq        <= '0';
      elsif rx_iqmm_est_en = '1' then   -- estimation enabled

        if data_valid_in = '1' then -- multiply and accumulate
      
          sign_iq     <= i_5bit_reg(4) xor q_5bit_reg(4); -- determine sign
          iq_prod_reg <= i_5bit_u * q_5bit_u;             -- multiply

          if reset_ph_accum = '1' then -- reset accumulator
            iq_accum_reg <= sxt(iq_prod_signed, PH_IQ_ACCUM_SIZE_CT);
          else
            -- sign extend product and accumulate
            iq_accum_reg <= iq_accum_reg + sxt(iq_prod_signed, PH_IQ_ACCUM_SIZE_CT);
          end if;

        end if;
      end if;
    end if;
  end process iq_mac_p;

  -- Start estimates at start of new symbol period
  est_start   <= reset_g_accum and data_valid_in;
  -- Start with gain estimate
  g_est_start <= est_start and (not end_of_packet);
  -- Start phase estimate one sample period later due to accumulator pipeline
  ph_est_start <= '1' when ctrl_cnt = "000011" else '0';

  -- Counter for timing derived control signals within gain and phase
  -- mismatch estimation sub-blocks.
  control_p: process (clk, reset_n)
  begin  -- process counter_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      ctrl_cnt_en   <= '0';
      ctrl_cnt      <= (others => '0');
      end_of_packet <= '0';
      initialise    <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if rx_iqmm_reset = '1' then
        -- Control count started part way into the count to get initial
        -- values for gain and pahse estimates.
        ctrl_cnt_en   <= '1';
        ctrl_cnt      <= "011010";     -- 26 (ph_conv_start)
        end_of_packet <= '0';
        initialise    <= '1';
      elsif rx_iqmm_est_en = '1' or initialise = '1' then  -- estimation enabled
                                                           -- or initialising

        -- Prevent post-processing of data from last symbol in a packet
        end_of_packet <= rx_packet_end
                           or (end_of_packet and (not (est_start)));
        
        -- Disable counter after phase mismatch estimate completed (phase  
        -- estimate takes longer than gain estimate).
        ctrl_cnt_en <= g_est_start
                         or (ctrl_cnt_en and
                           (not (g_est_valid or rx_iqmm_reset)));

        -- initialise goes LOW when g_est_valid goes HIGH
        initialise  <= initialise and (not g_est_valid);
        
        if g_est_start = '1' then
          ctrl_cnt    <= (others => '0');
        elsif ctrl_cnt_en = '1' then
          ctrl_cnt <= ctrl_cnt + '1'; 
        end if;
      end if;
    end if;
  end process control_p;

  
  -----------------------------------------------------------------------------
  -- Gain mismatch estimation sub-block
  -----------------------------------------------------------------------------
  iq_mism_g_est_1 : iq_mism_g_est
    generic map (
      iq_accum_width_g => G_IQ_ACCUM_SIZE_CT,
      gain_width_g     => G_EST_SIZE_CT,
      preset_width_g   => PSET_SIZE_CT)

    port map (
      clk         => clk,
      reset_n     => reset_n,
      i_accum     => i_accum_reg,
      q_accum     => q_accum_reg,
      iqmm_est    => rx_iqmm_est,
      est_start   => g_est_start,
      est_en      => rx_iqmm_est_en,
      est_reset   => rx_iqmm_reset,
      g_pset      => rx_iqmm_g_pset,
      g_step_in   => rx_iqmm_g_step,
      ctrl_cnt    => ctrl_cnt,
      initialise  => initialise,
      g_est_valid => g_est_valid,
      g_est       => g_est,
      gain_accum  => gain_accum);

  
  -----------------------------------------------------------------------------
  -- Phase mismatch estimation sub-block
  -----------------------------------------------------------------------------
  iq_mism_ph_est_1 : iq_mism_ph_est
    generic map (
      iq_accum_width_g => PH_IQ_ACCUM_SIZE_CT/2,
      phase_width_g    => PH_EST_SIZE_CT,
      preset_width_g   => PSET_SIZE_CT)

    port map (
      clk          => clk,
      reset_n      => reset_n,
      iq_accum     => iq_accum_reg(PH_IQ_ACCUM_SIZE_CT-1 downto PH_IQ_ACCUM_SIZE_CT/2),
      iqmm_est     => rx_iqmm_est,
      est_start    => ph_est_start,
      est_en       => rx_iqmm_est_en,
      est_reset    => rx_iqmm_reset,
      ph_pset      => rx_iqmm_ph_pset,
      ph_step_in   => rx_iqmm_ph_step,
      ctrl_cnt     => ctrl_cnt,
      initialise   => initialise,
      ph_est_valid => ph_est_valid,
      ph_est       => ph_est,
      phase_accum  => phase_accum);

  
  -----------------------------------------------------------------------------
  -- Output assignments
  --
  -- The current estimate at the end of each packet is used in the I/Q mismatch
  -- compensation block and applied to all symbols of the following packet...
  -----------------------------------------------------------------------------
  est_regs_p: process (clk, reset_n)
  begin
    if reset_n = '0' then               -- asynchronous reset (active low)
      rx_iqmm_g_est  <= G_EST_INIT_CT;
      rx_iqmm_ph_est <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- Update gain and phase estimates to I/Q mismatch compensation block
      -- at the end of a packet or initialise the estimates after the
      -- presets have been loaded.
      if (rx_packet_end = '1' and rx_iqmm_out_dis = '0') or 
         (initialise = '1' and g_est_valid = '1') then
        rx_iqmm_g_est  <= g_est;
        rx_iqmm_ph_est <= ph_est;
      end if;     
    end if;
  end process est_regs_p;

  
end rtl;
