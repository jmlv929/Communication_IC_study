

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of iq_mism_g_est is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant IQ_ACCU_SIZE_CT     : integer := iq_accum_width_g;
  constant G_EST_SIZE_CT       : integer := gain_width_g;
  constant G_PSET_SIZE_CT      : integer := preset_width_g;
  constant AV_G_SIZE_CT        : integer := 20;
  constant ZEROS_AV_G_M_ACC_CT : std_logic_vector(AV_G_SIZE_CT-IQ_ACCU_SIZE_CT-1 downto 0)
                                   := (others => '0');
  constant STEP_SIZE_CT        : integer := 8;
  constant ZEROS_PSET_PAD_CT   : std_logic_vector(AV_G_SIZE_CT-G_PSET_SIZE_CT-1 downto 0)
                                   := (others => '0');
  constant AV_G_RESET_CT       : std_logic_vector(AV_G_SIZE_CT-1 downto 0)
                                   := ('1', others => '0');
                                   --conv_std_logic_vector(1, AV_G_SIZE_CT-(AV_G_SIZE_CT-G_PSET_SIZE_CT))
                                     --   & ZEROS_PSET_PAD_CT;

  constant AV_G_MAX_CT         : std_logic_vector(AV_G_SIZE_CT-1 downto 0) := (others => '1');
  constant AV_G_MIN_CT         : std_logic_vector(AV_G_SIZE_CT-1 downto 0) := (others => '0');

  constant G_EST_SEL_CT          : integer := AV_G_SIZE_CT-G_EST_SIZE_CT;
  constant ZEROS_AV_G_M_G_EST_CT : std_logic_vector(G_EST_SEL_CT-1 downto 0)
                                     := (others => '0');
  
  constant ZEROS_G_EST_M1_CT   : std_logic_vector(G_EST_SIZE_CT-2 downto 0) := (others => '0');

  constant ZEROS_G_EST_SIZEM1_CT   : std_logic_vector(G_EST_SIZE_CT-2 downto 0)
                                       := (others => '0');
  constant G_EST_INIT_CT           : std_logic_vector(G_EST_SIZE_CT-1 downto 0)
                                       := '1' & ZEROS_G_EST_SIZEM1_CT;
  
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal x_reg          : std_logic_vector(IQ_ACCU_SIZE_CT-1 downto 0);
  signal y_reg          : std_logic_vector(AV_G_SIZE_CT-1 downto 0);
  signal sum_xy_bit     : std_logic;  
  signal sum_xy_reg     : std_logic_vector(AV_G_SIZE_CT downto 0);
  signal av_g_reg       : std_logic_vector(AV_G_SIZE_CT-1 downto 0);

  signal bit_equal      : std_logic; -- bit-wise equal
  signal bit_greater    : std_logic; -- bit-wise greater than
  signal equal          : std_logic; -- equal result for whole words
  signal greater        : std_logic; -- greater than result for whole words
  signal next_equal     : std_logic;
  signal next_greater   : std_logic;
  signal i_ge_q         : std_logic;

  signal g_step         : std_logic_vector(STEP_SIZE_CT downto 0);
  signal g_step_inv     : std_logic_vector(STEP_SIZE_CT downto 0);
  signal add_g_step     : std_logic;
  signal sum_start      : std_logic;
  signal av_g_valid     : std_logic;
  signal g_est_rnd_word : std_logic_vector(G_EST_SIZE_CT-1 downto 0);
  signal g_est_rnd      : std_logic;
  signal g_est_sat_word : std_logic_vector(G_EST_SIZE_CT-1 downto 0);
  signal g_est_sat      : std_logic;
  signal g_est_psat     : std_logic_vector(G_EST_SIZE_CT-1 downto 0);
  
  
begin  -- rtl

  ------------------------------------------------------------------------------
  -- Gain mismatch estimation (320 cycles to complete)
  ------------------------------------------------------------------------------

  -- SumI >= SumQ 
  -- Implementation of bit-serial greater than or equal to using two registers
  -- and a handful of gates.
  ge_regs_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      equal   <= '1';
      greater <= '0';
    elsif clk'event and clk = '1' then
      if est_en = '1' then              -- estimation enabled
        if est_start = '1' then
          equal   <= '1';
          greater <= '0';
        else
          equal   <= next_equal;
          greater <= next_greater;
        end if;
      end if;
    end if;
  end process ge_regs_p;

  bit_equal   <= not(x_reg(0) xor y_reg(0));
  bit_greater <= x_reg(0) and (not y_reg(0));

  next_equal   <= bit_equal and equal;
  next_greater <= bit_greater or (bit_equal and greater);

  i_ge_q <= greater or equal;

  -- Select positive or negative step
  g_step_inv <= not ('0' & g_step_in) + '1';
  g_step     <= '0' & g_step_in when i_ge_q = '1' else g_step_inv;

  -- Build g_est rounding word
  g_est_rnd_word <= ZEROS_G_EST_M1_CT & av_g_reg(G_EST_SEL_CT-1);
    
  -- Bit-serial adder to perform av_g_reg + g_step and g_est rounding
  adder_1 : bit_ser_adder
    port map (
      clk        => clk,
      reset_n    => reset_n,
      sync_reset => sum_start,
      x_in       => x_reg(0),
      y_in       => y_reg(0),
      sum_out    => sum_xy_bit);


  -- Control process for adder addend shift registers 
  add_ctl_p : process (clk, reset_n)
  begin  -- process add0_ctl_p
    if reset_n = '0' then
      x_reg      <= (others => '0');
      y_reg      <= (others => '0');
      sum_xy_reg <= (others => '0');
    elsif clk'event and clk = '1' then
      if est_en = '1' or initialise = '1' then  -- estimation enabled or initialising
        
        if est_start = '1' then
          -- load registers for greater than or equal to evaluation
          x_reg <= i_accum;
          y_reg <= ZEROS_AV_G_M_ACC_CT & q_accum;
        elsif add_g_step = '1' then
          -- Load registers for addition of g_step
          x_reg <= sxt(g_step,IQ_ACCU_SIZE_CT);
          y_reg <= av_g_reg;
        elsif g_est_rnd = '1' then
          -- Load registers for g_est rounding 
          x_reg <= sxt(g_est_rnd_word,IQ_ACCU_SIZE_CT);
          y_reg <= ZEROS_AV_G_M_G_EST_CT & av_g_reg(AV_G_SIZE_CT-1 downto G_EST_SEL_CT);
        else
          -- Shift registers right 1-bit at a time to load bit-serial
          -- adder or perform greater than or equal to operation. Sign
          -- extension is performed on x_reg (g_step), but not y_reg.
          x_reg <= x_reg(IQ_ACCU_SIZE_CT-1) & x_reg(IQ_ACCU_SIZE_CT-1 downto 1);
          y_reg <= '0' & y_reg(AV_G_SIZE_CT-1 downto 1);
          -- sum appears from adder 1 bit at a time LSB first
          sum_xy_reg <= sum_xy_bit & sum_xy_reg(AV_G_SIZE_CT downto 1);
        end if;

      end if;
    end if;
  end process add_ctl_p;


  -- Timing derived control signals
  add_g_step <= '1' when ctrl_cnt = "001010" else '0';  -- 10
  av_g_valid <= '1' when ctrl_cnt = "100000" else '0';  -- 32
  g_est_rnd  <= '1' when ctrl_cnt = "100001" else '0';  -- 33
  g_est_sat  <= '1' when ctrl_cnt = "101100" else '0';  -- 44

  -- Initialise adder
  sum_start <= add_g_step or g_est_rnd;

  -- Build g_est_psat (pre-saturation) and g_est_sat_word, this is ORed with
  -- the pre-saturation value. This can be done because the rounding addition
  -- can only move the value in a positive direction.
  g_est_psat     <= sum_xy_reg(AV_G_SIZE_CT-1 downto G_EST_SEL_CT);
  g_est_sat_word <= (others => sum_xy_reg(AV_G_SIZE_CT));
  
  g_est_reg_p: process (clk, reset_n)
  begin  -- process g_est_reg_p
    if reset_n = '0' then
      g_est_valid <= '0';
      g_est       <= G_EST_INIT_CT;
      av_g_reg    <= AV_G_RESET_CT;
    elsif clk'event and clk = '1' then
      if est_reset = '1' then
        -- load av_g_reg preset estimate  
        av_g_reg <= g_pset & ZEROS_PSET_PAD_CT;
      else
        
        if av_g_valid = '1' and initialise = '0' then
          -- Detect overflow/underflow
          if sum_xy_reg(AV_G_SIZE_CT) = '1' then
            -- x_reg is sign extended g_step
            if x_reg(0) = '0' then
              -- Adding g_step so overflow
              av_g_reg <= AV_G_MAX_CT;
            else
              -- Subtracting g_step so underflow
              av_g_reg <= AV_G_MIN_CT;
            end if;
          else
            -- Load av_g_reg with new estimate
            av_g_reg <= sum_xy_reg(AV_G_SIZE_CT-1 downto 0);
          end if;          
        end if;

        -- g_est is simply the 9 MSBs of av_g_reg, rounded
        if g_est_sat = '1' then 
          g_est <= g_est_psat or g_est_sat_word;
        end if;

        g_est_valid <= g_est_sat;
        
      end if;
    end if;
  end process g_est_reg_p;

    
  -- Gain mismatch estimate assignment  
  gain_accum  <= av_g_reg(AV_G_SIZE_CT-1 downto AV_G_SIZE_CT-G_PSET_SIZE_CT);

  
end rtl;
