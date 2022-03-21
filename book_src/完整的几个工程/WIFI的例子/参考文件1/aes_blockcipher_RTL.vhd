

--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of aes_blockcipher is

------------------------------------------------------------ Signals declaration
-- Inverted opmode signal, used to gate the decryption block.
signal opmode_n        : std_logic;
-- Signals from the state machine.
signal decoded_state   : std_logic_vector(3 downto 0); -- AES current state.
signal next_dec_state  : std_logic_vector(3 downto 0); -- AES next state.
signal number_rounds   : std_logic_vector(4 downto 0); -- Nb of rounds in AES.
signal round           : std_logic_vector(4 downto 0); -- Current round number.
signal int_expand_done : std_logic; -- Internal signal for Key expansion done.
-- Encryption state
signal state_w0        : std_logic_vector(31 downto 0);
signal state_w1        : std_logic_vector(31 downto 0);
signal state_w2        : std_logic_vector(31 downto 0);
signal state_w3        : std_logic_vector(31 downto 0);
-- Decryption state
signal invstate_w0     : std_logic_vector(31 downto 0);
signal invstate_w1     : std_logic_vector(31 downto 0);
signal invstate_w2     : std_logic_vector(31 downto 0);
signal invstate_w3     : std_logic_vector(31 downto 0);
-- Signals for the KeySchedule / Encryption block interface.
signal keyword         : std_logic_vector(31 downto 0); -- Key word to SubByte.
signal key_subbyte_rs  : std_logic_vector(31 downto 0); -- SubByte result word.
-- SRAM interface for key words storage.
signal wr_memo_address :std_logic_vector( 3 downto 0); -- Address.
signal wr_memo_wen     : std_logic; -- Write enable.
----------------------------------------------------- End of Signals declaration

begin

  ---------------------------------------------------------- Assign output ports
  expand_done <= int_expand_done;
  --------------------------------------------------- End of assign output ports

  ----------------------------------------------- Port map for AES state machine
  aes_sm_1 : aes_sm
  generic map (
    ccm_mode_g      => ccm_mode_g  -- 1 to use the AES cipher in CCM mode.
  )
  port map (
    -- Clocks and resets
    clk             => clk,             -- AHB clock.                     (IN) 
    reset_n         => reset_n,         -- AHB reset. Inverted logic.     (IN)
    -- Control lines                                                      
    opmode          => opmode,          -- Indicates Rx or Tx mode.       (IN) 
    aes_ksize       => aes_ksize,       -- Key size in bytes.             (IN) 
    start_expand    => start_expand,    -- Pulse to start Key Schedule.   (IN) 
    start_cipher    => start_cipher,    -- Pulse to en/decrypt one state. (IN) 
    expand_done     => int_expand_done, -- Indicates key Schedule done.   (IN) 
    cipher_done     => cipher_done,     -- Indicates en/decryption done.  (OUT)
    ciph_done_early => ciph_done_early, -- Flag 2 cc before cipher_done.  (OUT)
    number_rounds   => number_rounds,   -- Nb of rounds in AES.           (OUT)
    round           => round,           -- Current round number.          (OUT)
    decoded_state   => decoded_state,   -- Current AES state.             (OUT)
    next_dec_state  => next_dec_state,  -- Next AES state.                (OUT) 
    -- Interrupt                                                           
    stopop          => stopop,          -- Stops the en/decryption.       (IN) 
    -- Encryption states
    state_w0        => state_w0,        --                                (IN)
    state_w1        => state_w1,        --                                (IN)
    state_w2        => state_w2,        --                                (IN)
    state_w3        => state_w3,        --                                (IN)
    -- Decryption state
    invstate_w0     => invstate_w0,     --                                (IN)
    invstate_w1     => invstate_w1,     --                                (IN)
    invstate_w2     => invstate_w2,     --                                (IN)
    invstate_w3     => invstate_w3,     --                                (IN)
    -- Result (Encrypted/decrypted state)
    result_w0       => result_w0,       --                                (OUT)
    result_w1       => result_w1,       --                                (OUT)
    result_w2       => result_w2,       --                                (OUT)
    result_w3       => result_w3,       --                                (OUT)
    -- SRAM controls from KeySchedule block
    wr_memo_address => wr_memo_address, -- Address to save key.           (IN) 
    wr_memo_wen     => wr_memo_wen,     -- Write enable.                  (IN)
    -- AES SRAM interface                                                  
    sram_address    => sram_address,    -- Address.                       (OUT)
    sram_wen        => sram_wen,        -- Write Enable. Inverted logic.  (OUT)
    sram_cen        => sram_cen         -- Chip Enable. Inverted logic.   (OUT)
    );
  ---------------------------------------- End of Port map for AES state machine

  ------------------------------------------------- Port map for AES_KeySchedule
  aes_keyschedule_1: aes_keyschedule
  port map(
    -- Clocks and resets
    clk          => clk,                -- System clock.                  (IN)
    reset_n      => reset_n,            -- System reset. Inverted logic.  (IN)
    -- Flags:
    key_load4    => key_load4,          -- Save the first 4 key bytes.    (IN)
    key_load8    => key_load8,          -- Save the last 4 key bytes.     (IN)
    start_expand => start_expand,       -- Starts the key expansion.      (IN)
    expand_done  => int_expand_done,    -- Flag indicating expansion done.(OUT)
    -- Registers:
    aes_ksize    => aes_ksize,          -- Size of key in bytes (Nk)      (IN)
    -- Interrupt:
    stopop       => stopop,             -- Stops the keyschedule.         (IN)
    -- Initial Key values:
    init_key_w0  => init_key_w0,        -- Initial key word no.0.         (IN)
    init_key_w1  => init_key_w1,        -- Initial key word no.1.         (IN)
    init_key_w2  => init_key_w2,        -- Initial key word no.2.         (IN)
    init_key_w3  => init_key_w3,        -- Initial key word no.3.         (IN)
    init_key_w4  => init_key_w4,        -- Initial key word no.4.         (IN)
    init_key_w5  => init_key_w5,        -- Initial key word no.5.         (IN)
    init_key_w6  => init_key_w6,        -- Initial key word no.6.         (IN)
    init_key_w7  => init_key_w7,        -- Initial key word no.7.         (IN)
    -- Key Storage Memory:
    memo_wrdata  => sram_wdata,         -- KeyWord to save in memo.       (OUT)
    memo_address => wr_memo_address,    -- Address to save KeyWord.       (OUT)
    memo_wen     => wr_memo_wen,        -- Memo Write Enable line.        (OUT)
    -- AES_SubByte block:
    subword      => key_subbyte_rs,     -- SubBlock result key word.      (IN)
    keyword      => keyword             -- Key word to SubBlock.          (OUT)
  );
  ------------------------------------------ End of Port map for AES_KeySchedule

  -------------------------------------------------- Port map for AES encryption
  aes_encrypt_1 : aes_encrypt
    port map (
      -- Clocks and resets
      clk             => clk,            -- AHB clock.                    (IN) 
      reset_n         => reset_n,        -- AHB reset. Inverted logic.    (IN) 
      -- Interface to share SubByte block with the KeySchedule block     
      keyword         => keyword,        -- Word to SubByte block         (IN) 
      key_subbyte_rs  => key_subbyte_rs, -- SubByte result word.          (OUT)
      -- Data to encrypt
      init_state_w0   => init_state_w0,  --                               (IN)
      init_state_w1   => init_state_w1,  --                               (IN)
      init_state_w2   => init_state_w2,  --                               (IN)
      init_state_w3   => init_state_w3,  --                               (IN)
      -- Result state
      state_w0        => state_w0,       --                               (OUT)
      state_w1        => state_w1,       --                               (OUT)
      state_w2        => state_w2,       --                               (OUT)
      state_w3        => state_w3,       --                               (OUT)
      -- Controls
      enable          => opmode,         -- Enable the encryption block.  (IN) 
      number_rounds   => number_rounds,  -- Nb of rounds in AES.          (IN) 
      round           => round,          -- Current round number.         (IN) 
      decoded_state   => decoded_state,  -- Current AES state.            (IN) 
      next_dec_state  => next_dec_state, -- Next AES state.               (IN) 
      -- AES SRAM
      sram_rdata      => sram_rdata      -- Data read.                    (IN) 
      );
  ------------------------------------------- End of Port map for AES encryption

  -------------------------------------------------- Port map for AES decryption
  no_ccm_mode_gen : if ccm_mode_g = 0 generate

    -- Active high enable signal for the decryption block.
    opmode_n <= not(opmode);

    aes_decrypt_1 : aes_decrypt
      port map (
        -- Clocks and resets
        clk             => clk,          -- AHB clock.                    (IN)
        reset_n         => reset_n,      -- AHB reset. Inverted logic.    (IN)
        -- Data to decrypt
        init_state_w0   => init_state_w0,  --                             (IN)
        init_state_w1   => init_state_w1,  --                             (IN)
        init_state_w2   => init_state_w2,  --                             (IN)
        init_state_w3   => init_state_w3,  --                             (IN)
        -- Result state
        invstate_w0     => invstate_w0,    --                             (OUT)
        invstate_w1     => invstate_w1,    --                             (OUT)
        invstate_w2     => invstate_w2,    --                             (OUT)
        invstate_w3     => invstate_w3,    --                             (OUT)
        -- Controls
        enable          => opmode_n,       -- Enable the decryption block.(IN) 
        number_rounds   => number_rounds,  -- Nb of rounds in AES.        (IN) 
        round           => round,          -- Current round number.       (IN) 
        decoded_state   => decoded_state,  -- Current AES state.          (IN) 
        next_dec_state  => next_dec_state, -- Next AES state.             (IN)  
        -- AES SRAM
        sram_rdata      => sram_rdata      -- Data read.                  (IN) 
        );
  end generate no_ccm_mode_gen;

  -- In CCM mode, the decryption block is not used.
  ccm_mode_gen : if ccm_mode_g = 1 generate
    opmode_n    <= '0';
    invstate_w0 <= (others => '0');
    invstate_w1 <= (others => '0');
    invstate_w2 <= (others => '0');
    invstate_w3 <= (others => '0');
  end generate ccm_mode_gen;
  ------------------------------------------- End of Port map for AES decryption


end RTL;
