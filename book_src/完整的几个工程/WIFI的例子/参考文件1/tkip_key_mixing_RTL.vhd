

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of tkip_key_mixing is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- S-boxes interface.
  signal sbox_addr1         : std_logic_vector(15 downto 0); -- Phase 1 address.
  signal sbox_addr2         : std_logic_vector(15 downto 0); -- Phase 2 address.
  signal sbox_data          : std_logic_vector(15 downto 0); -- S-Box data.
  signal loop_cnt           : std_logic_vector(2 downto 0);  -- Loop counter.
  signal state_cnt          : std_logic_vector(2 downto 0);  -- State counter.
  signal in_even_state      : std_logic; -- High when the FSM is in even state.
  -- Values to update the registers
  signal next_keymix1_reg_w : std_logic_vector(15 downto 0); -- From phase 1.
  signal next_keymix2_reg_w : std_logic_vector(15 downto 0); -- From phase 2.
  -- Internal registers, to store the TTAK in phase 1 and the PPK in phase 2.
  signal keymix_reg_w5      : std_logic_vector(15 downto 0);
  signal keymix_reg_w4      : std_logic_vector(15 downto 0);
  signal keymix_reg_w3      : std_logic_vector(15 downto 0);
  signal keymix_reg_w2      : std_logic_vector(15 downto 0);
  signal keymix_reg_w1      : std_logic_vector(15 downto 0);
  signal keymix_reg_w0      : std_logic_vector(15 downto 0);


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  --------------------------------------------
  -- Port map for TKIP key mixing, phase 1.
  --------------------------------------------
  keymix_phase1_1: keymix_phase1
    port map (
      -- Controls
      loop_cnt            => loop_cnt,
      state_cnt           => state_cnt,
      in_even_state       => in_even_state,
      -- S-Box interface
      sbox_addr           => sbox_addr1,
      sbox_data           => sbox_data,
      -- Temporal key (128 bits)
      temp_key_w3         => temp_key_w3,
      temp_key_w2         => temp_key_w2,
      temp_key_w1         => temp_key_w1,
      temp_key_w0         => temp_key_w0,
      -- Internal registers, storing the TTAK during phase 1
      keymix_reg_w4       => keymix_reg_w4,
      keymix_reg_w3       => keymix_reg_w3,
      keymix_reg_w2       => keymix_reg_w2,
      keymix_reg_w1       => keymix_reg_w1,
      keymix_reg_w0       => keymix_reg_w0,
      -- Value to update the registers.
      next_keymix_reg_w   => next_keymix1_reg_w
      );


  --------------------------------------------
  -- Port map for TKIP key mixing, phase 2.
  --------------------------------------------
  keymix_phase2_1: keymix_phase2
    port map (
      -- Clocks & Reset
      reset_n             => reset_n,
      clk                 => clk,
      -- Controls
      loop_cnt            => loop_cnt,
      in_even_state       => in_even_state,
      -- S-Box interface
      sbox_addr           => sbox_addr2,
      sbox_data           => sbox_data,
      -- Sequence counter.
      tsc_lsb             => tsc(15 downto 0),
      -- Temporal key (128 bits)
      temp_key_w3         => temp_key_w3,
      temp_key_w2         => temp_key_w2,
      temp_key_w1         => temp_key_w1,
      temp_key_w0         => temp_key_w0,
      -- Internal registers, storing the PPK during phase 2
      keymix_reg_w5       => keymix_reg_w5,
      keymix_reg_w4       => keymix_reg_w4,
      keymix_reg_w3       => keymix_reg_w3,
      keymix_reg_w2       => keymix_reg_w2,
      keymix_reg_w1       => keymix_reg_w1,
      keymix_reg_w0       => keymix_reg_w0,
      -- Value to update the registers.
      next_keymix_reg_w   => next_keymix2_reg_w,
      -- TKIP key.
      tkip_key_w3         => tkip_key_w3,
      tkip_key_w2         => tkip_key_w2,
      tkip_key_w1         => tkip_key_w1,
      tkip_key_w0         => tkip_key_w0
      );  


  --------------------------------------------
  -- Port map for TKIP key mixing state machine.
  --------------------------------------------
  key_mixing_sm_1: key_mixing_sm
    port map (
      -- Clocks & Reset
      reset_n             => reset_n,
      clk                 => clk,
      -- Controls
      key1_key2n          => key1_key2n,
      start_keymix        => start_keymix,
      --
      keymix1_done        => keymix1_done,
      keymix2_done        => keymix2_done,
      loop_cnt            => loop_cnt,
      state_cnt           => state_cnt,
      in_even_state       => in_even_state,
      -- S-Box interface
      sbox_addr1          => sbox_addr1,
      sbox_addr2          => sbox_addr2,
      --
      sbox_data           => sbox_data,
      -- Data
      address2            => address2,
      tsc                 => tsc,
      -- Values to update internal registers.
      next_keymix1_reg_w  => next_keymix1_reg_w,
      next_keymix2_reg_w  => next_keymix2_reg_w,
      -- Registers out.
      keymix_reg_w5       => keymix_reg_w5,
      keymix_reg_w4       => keymix_reg_w4,
      keymix_reg_w3       => keymix_reg_w3,
      keymix_reg_w2       => keymix_reg_w2,
      keymix_reg_w1       => keymix_reg_w1,
      keymix_reg_w0       => keymix_reg_w0
      );


end RTL;
