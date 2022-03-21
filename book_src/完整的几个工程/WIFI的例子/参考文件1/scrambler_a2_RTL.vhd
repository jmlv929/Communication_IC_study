

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of scrambler_a2 is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type SCRAMBLER_STATE_T is (init_state,
                             signal_state,
                             service_state,
                             tailbits_state,
                             padbits_state);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- States of the scrambler FSM.
  signal scramb_state      : SCRAMBLER_STATE_T;
  signal next_scramb_state : SCRAMBLER_STATE_T;

  -- Pseudo-noise generator shift register.
  signal pn_shift          : std_logic_vector(6 downto 0);
  signal pn_scrambled      : std_logic; -- pn generator scrambled input value.
  signal pn_shift_init     : std_logic_vector(6 downto 0);
  signal pn_scrambled_init : std_logic; -- pn generator scrambled input value.
  signal scram_enable      : std_logic; -- '1' when the pn-generator is working.
  signal tail_ctrl         : std_logic; -- '1' during the tail-bits insertion.
  signal no_out_marker     : std_logic; -- '1' to disable marker_o.

  signal force_init        : std_logic; -- '1' to force new init of the scrambler.
  signal force_pulse_rise  : std_logic;
  signal force_init_ff1    : std_logic;
  signal force_pulse_fall  : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------------
  -- Init. scrambler pseudo-noise generator
  --------------------------------------------

  -- Input scrambled value for the pseudo-noise generator.
  pn_scrambled_init <= pn_shift_init(1) xor pn_shift_init(6);

  -- Pseudo noise generator for the scrambler: S(x) = x7+x+1
  pn_init_generator_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      pn_shift_init <= "0000001"; -- Scrambler init value.
    elsif clk'event and clk = '1' then
      if enable_i = '1' then
        -- Load seed init value
        if scrmode_i = '1' then
          pn_shift_init <= scrinitval_i;
        -- Scramble init. pattern
        elsif force_pulse_fall = '1' then
          pn_shift_init(6 downto 1) <= pn_shift_init(5 downto 0);
          pn_shift_init(0)          <= pn_scrambled_init;
        end if;
      end if;
    end if;
  end process pn_init_generator_p;


  --------------------------------------------
  -- Scrambler pseudo-noise generator
  --------------------------------------------

  -- Input scrambled value for the pseudo-noise generator.
  pn_scrambled <= pn_shift(6) xor pn_shift(3);

  -- Pseudo noise generator for the scrambler: S(x) = x7+x4+1
  pn_generator_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      pn_shift       <= "1010110"; -- Scrambler init value.
      tx_scrambler_o <= "1010110"; -- Scrambler init value for debug.
    elsif clk'event and clk = '1' then
      if enable_i = '1' then
        -- Scramble pattern, except in signal_state (scram_enable=0).
        if scram_enable = '1'
          and data_valid_i = '1' and data_ready_i = '1' then
          pn_shift(6 downto 1)  <= pn_shift(5 downto 0);
          pn_shift(0)           <= pn_scrambled;
        elsif force_pulse_rise = '1' then
          pn_shift <= pn_shift_init;
          -- Scrambler init value for debug.
          tx_scrambler_o <= pn_shift_init;
        end if;
      end if;
    end if;
  end process pn_generator_p;
  
  -- Generate pulse
  force_pulse_rise <= force_init and not force_init_ff1;
  force_pulse_fall <= not force_init and force_init_ff1;

  --------------------------------------------
  -- Scrambler state machine
  --------------------------------------------

  -- Combinational process
  scr_fsm_comb_p : process (marker_i, scramb_state)
  begin

    case scramb_state is

      when init_state =>
        if marker_i = '1' then
          next_scramb_state  <= signal_state;
        else
          next_scramb_state  <= init_state;
        end if;

      when signal_state =>                   -- SIGNAL Field
        if marker_i = '1' then
          next_scramb_state  <= service_state;
        else
          next_scramb_state  <= signal_state;
        end if;

      when service_state =>                  -- DATA Field
        if marker_i = '1' then
          next_scramb_state  <= tailbits_state;
        else
          next_scramb_state  <= service_state;
        end if;

      when tailbits_state =>                 -- Tail bits
        if marker_i = '1' then
          next_scramb_state  <= padbits_state;
        else
          next_scramb_state  <= tailbits_state;
        end if;

      when padbits_state =>                  -- Pad bits
        if marker_i = '1' then
          next_scramb_state  <= init_state;
        else
          next_scramb_state  <= padbits_state;
        end if;

      when others =>
        next_scramb_state  <= scramb_state;

    end case;
  end process scr_fsm_comb_p;

  -- Sequential process.
  scr_fsm_seq_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      scramb_state  <= init_state;
    elsif clk'event and clk = '1' then
      if enable_i = '0' then
        scramb_state  <= init_state;
      else
        if data_ready_i = '1' then
          scramb_state  <= next_scramb_state;
        end if;
      end if;
    end if;
  end process scr_fsm_seq_p;

  --------------------------------------------
  -- Scrambler control signals
  --------------------------------------------

  -- Control signals.
  ctrl_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      scram_enable   <= '0';
      tail_ctrl      <= '0';
      no_out_marker  <= '0';
      force_init     <= '0';
      force_init_ff1 <= '0';
    elsif clk'event and clk = '1' then
      force_init_ff1 <= force_init;

      if enable_i = '0' then
        scram_enable   <= '0';
        tail_ctrl      <= '0';
        no_out_marker  <= '0';
        force_init     <= '0';
      else
        if data_ready_i = '1' then

        case next_scramb_state is

          when init_state =>
            force_init     <= '0';

          when signal_state =>
            scram_enable   <= '0';
            force_init     <= '1';

          when service_state =>
            scram_enable   <= '1';
            no_out_marker  <= '1';
            force_init     <= '0';

          when tailbits_state =>
            tail_ctrl      <= '1';
            force_init     <= '0';

          when padbits_state =>
            tail_ctrl      <= '0';
            no_out_marker  <= '0';
            force_init     <= '0';

          when others => null;

        end case;

        end if;
      end if;
    end if;
  end process ctrl_p;


  --------------------------------------------
  -- Scrambler output signals
  --------------------------------------------

  -- Scramble the incomming data with the pseudo noise.
  data_o <= ( data_i xor pn_scrambled )
            when ( scram_enable = '1' and tail_ctrl = '0' )
            else data_i;

  -- Send control signals to the next block.
  data_valid_o <= data_valid_i;
  data_ready_o <= data_ready_i;
  -- Do not send tail and pad bits markers to the encoder.
  marker_o     <= marker_i when no_out_marker = '0' else '0';


end RTL;
