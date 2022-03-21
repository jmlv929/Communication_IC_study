

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of iq_mism_ph_est is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant STEP_SIZE_CT        : integer := 8;
  constant ADDEND_SIZE_CT      : integer := STEP_SIZE_CT+1;
  constant IQ_ACCU_SIZE_CT     : integer := iq_accum_width_g;
  constant PH_EST_SIZE_CT      : integer := phase_width_g;
  constant PH_PSET_SIZE_CT     : integer := preset_width_g;
  constant AV_PH_SIZE_CT       : integer := 20;-- internal accumulator size

  constant AV_PH_MAX_CT         : std_logic_vector(AV_PH_SIZE_CT-1 downto 0) := (others => '1');
  constant AV_PH_MIN_CT         : std_logic_vector(AV_PH_SIZE_CT-1 downto 0) := (others => '0');

  constant PH_EST_SEL_CT       : integer := AV_PH_SIZE_CT-PH_EST_SIZE_CT;
  constant ZEROS_AV_PH_M_G_EST_CT : std_logic_vector(PH_EST_SEL_CT-1 downto 0)
                                     := (others => '0');
  constant ZEROS_PSET_PAD_CT   : std_logic_vector(AV_PH_SIZE_CT-PH_PSET_SIZE_CT-1 downto 0)
                                   := (others => '0');
  constant ZEROS_STEP_SIZE_CT  : std_logic_vector(STEP_SIZE_CT-1 downto 0)
                                   := (others => '0');
  constant ZEROS_AV_PH_SIZE_CT : std_logic_vector(AV_PH_SIZE_CT-1 downto 0)
                                   := (others => '0');
  constant ZEROS_PH_EST_M1_CT : std_logic_vector(PH_EST_SIZE_CT-2 downto 0)
                                   := (others => '0');

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal av_ph_reg       : std_logic_vector(AV_PH_SIZE_CT-1 downto 0);
  signal ph_est_psat     : std_logic_vector(PH_EST_SIZE_CT-1 downto 0);
  signal ph_est_rnd_word : std_logic_vector(PH_EST_SIZE_CT-1 downto 0);
  signal ph_est_sat_word : std_logic_vector(PH_EST_SIZE_CT-1 downto 0);

  signal av_ph_valid     : std_logic;
  signal ph_est_sat      : std_logic;
  signal ph_est_rnd      : std_logic;
  signal sum_start       : std_logic;
  
  signal x_reg           : std_logic_vector(ADDEND_SIZE_CT-1 downto 0);
  signal y_reg           : std_logic_vector(AV_PH_SIZE_CT-1 downto 0);
  signal sum_xy_bit      : std_logic;  
  signal sum_xy_reg      : std_logic_vector(AV_PH_SIZE_CT downto 0);
  signal ph_step         : std_logic_vector(STEP_SIZE_CT downto 0);
  signal ph_step_inv     : std_logic_vector(STEP_SIZE_CT downto 0);

  
begin  -- rtl

  ------------------------------------------------------------------------------
  -- Phase mismatch estimation (320 cycles to complete)
  ------------------------------------------------------------------------------

  -- Select positive or negative step
  ph_step_inv <= not ('0' & ph_step_in) + '1';
  ph_step <= '0' & ph_step_in when iq_accum(IQ_ACCU_SIZE_CT-1) = '1' else ph_step_inv;
  
  -- Build g_est rounding word
  ph_est_rnd_word <= ZEROS_PH_EST_M1_CT & av_ph_reg(PH_EST_SEL_CT-1);

  -- Bit-serial adder to perform av_ph_reg + ph_step and rounding of ph_est
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
  begin
    if reset_n = '0' then
      x_reg      <= (others => '0');
      y_reg      <= (others => '0');
      sum_xy_reg <= (others => '0');
    elsif clk'event and clk = '1' then
      if est_en = '1' or initialise = '1' then  -- estimation enabled or initialising

        if est_start = '1' then
          -- load for addition of ph_step
          x_reg <= sxt(ph_step,ADDEND_SIZE_CT);
          y_reg <= av_ph_reg;
        elsif ph_est_rnd = '1' then
          -- Load registers for ph_est rounding 
          x_reg <= sxt(ph_est_rnd_word,ADDEND_SIZE_CT);
          y_reg <= ZEROS_AV_PH_M_G_EST_CT & av_ph_reg(AV_PH_SIZE_CT-1 downto PH_EST_SEL_CT);
        else
          -- addends supplied to adder 1 bit at a time LSB first
          x_reg <= x_reg(ADDEND_SIZE_CT-1)                -- sign extended
                            & x_reg(ADDEND_SIZE_CT-1 downto 1);
          y_reg <= y_reg(AV_PH_SIZE_CT-1)     -- sign extended 
                            & y_reg(AV_PH_SIZE_CT-1 downto 1);          
          -- sum appears from arithmetic 1 bit at a time LSB first
          sum_xy_reg <= sum_xy_bit & sum_xy_reg(AV_PH_SIZE_CT downto 1);
        end if;
      end if;
    end if;
  end process add_ctl_p;


  -- Timing derived control signals
  av_ph_valid   <= '1' when ctrl_cnt = "011001" else '0';  -- 25
  ph_est_rnd    <= '1' when ctrl_cnt = "011010" else '0';  -- 26
  ph_est_sat    <= '1' when ctrl_cnt = "100010" else '0';  -- 34

  -- Initialise adder
  sum_start  <= est_start or ph_est_rnd;
  
  -- Build ph_est_psat (pre-saturation) and ph_est_sat_word, this is ORed with
  -- the pre-saturation value. This can be done because the rounding addition
  -- can only move the value in a positive direction.
  ph_est_psat     <= sum_xy_reg(AV_PH_SIZE_CT-1 downto PH_EST_SEL_CT);
  ph_est_sat_word <= (others => sum_xy_reg(AV_PH_SIZE_CT));
 

  ph_est_reg_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      ph_est_valid <= '0';
      ph_est       <= (others => '0');
      av_ph_reg    <= (others => '0');
    elsif clk'event and clk = '1' then
      if est_reset = '1' then
        -- load av_g_reg preset estimate  
        av_ph_reg <= ph_pset & ZEROS_PSET_PAD_CT;
      else
        
        if av_ph_valid = '1' and initialise = '0' then
          -- Detect overflow/underflow
          if sum_xy_reg(AV_PH_SIZE_CT) = '1' then
            -- x_reg is sign extended g_step
            if x_reg(0) = '0' then
              -- Adding ph_step so overflow
              av_ph_reg <= AV_PH_MAX_CT;
            else
              -- Subtracting ph_step so underflow
              av_ph_reg <= AV_PH_MIN_CT;
            end if;
          else
            -- Load av_ph_reg with new estimate
            av_ph_reg <= sum_xy_reg(AV_PH_SIZE_CT-1 downto 0);
          end if;          
        end if;

        -- ph_est is simply the 6 MSBs of av_ph_reg, rounded
        if ph_est_sat = '1' then 
          ph_est <= ph_est_psat or ph_est_sat_word;
        end if;

        ph_est_valid <= ph_est_sat;
        
      end if;
    end if;
  end process ph_est_reg_p;

    
  -- Phase mismatch estimate assignment  
  phase_accum  <= av_ph_reg(AV_PH_SIZE_CT-1 downto AV_PH_SIZE_CT-PH_PSET_SIZE_CT);

  
end rtl;
