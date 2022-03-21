

--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of aes_ccm is

------------------------------------------------------------- Signal declaration
-- Control lines
signal key_load4       : std_logic; -- Signal to save the first 4 key bytes.
signal key_load8       : std_logic; -- Signal to save the last 4 key bytes.
signal start_expand    : std_logic; -- Positive edge starts Key expansion.
signal expand_done     : std_logic; -- Key expansion done.
signal start_cipher    : std_logic; -- Positive edge starts encryption round.
signal cipher_done     : std_logic; -- Encryption/decryption round done.
signal ciph_done_early : std_logic; -- Flag set 2 cycles before cipher_done.
signal aes_opmode      : std_logic; -- High to set AES cipher in encryption mode
signal aes_ksize       : std_logic_vector( 5 downto 0); -- Size of the key.
-- Data state sent to the AES block cipher for encryption or decryption.
signal aes_state_w0    : std_logic_vector(31 downto 0);
signal aes_state_w1    : std_logic_vector(31 downto 0);
signal aes_state_w2    : std_logic_vector(31 downto 0);
signal aes_state_w3    : std_logic_vector(31 downto 0);
-- AES blockcipher result words.
signal result_w0       : std_logic_vector(31 downto 0);
signal result_w1       : std_logic_vector(31 downto 0);
signal result_w2       : std_logic_vector(31 downto 0);
signal result_w3       : std_logic_vector(31 downto 0);
-- Diagnostic port from control sub-block.
signal aes_ctrl_diag   : std_logic_vector(7 downto 0);

------------------------------------------------------ End of Signal declaration

begin
  
  -------------------------------------------------------------- Diagnostic port
  aes_diag <= start_expand & expand_done & start_cipher & cipher_done &
              aes_ctrl_diag(3 downto 0) ;
  ------------------------------------------------------- End of diagnostic port

  ----------------------------------------------- Port map for AES control block
  aes_control_1 : aes_control
    generic map (
      addrmax_g      => addrmax_g
      )
    port map (
      -- Clocks & Reset
      clk            => clk,            -- AHB clock.                    (IN)
      reset_n        => reset_n,        -- AHB reset. Inverted logic.    (IN)
      -- Interrupts  
      process_done   => process_done,   -- High when operation finished. (IN)
      mic_int        => mic_int,        -- Indicates an AES MIC error.   (IN)
      -- Control structure
      opmode         => opmode,         -- Indicates Rx(0) or Tx(1) mode.(IN)
      aes_msize      => aes_msize,      -- MAC header size.              (IN)
      priority       => priority,       -- Priority field.               (IN)
      aes_csaddr     => aes_csaddr,     -- Control structure address.    (IN)
      aes_saddr      => aes_saddr,      -- Source address.               (IN)
      aes_daddr      => aes_daddr,      -- Destination address.          (IN)
      aes_maddr      => aes_maddr,      -- MAC header address.           (IN)
      enablecrypt    => enablecrypt,    -- Enables(1) the en/decryption. (IN)
      aes_kaddr      => aes_kaddr,      -- Key address.                  (IN)
      aes_bsize      => aes_bsize,      -- Size of data buffer.          (IN)
      state_number   => state_number,   -- Nb of 16-byte data states.    (IN)
      aes_packet_num => aes_packet_num, -- Packet number.                (IN)
      -- Registers
      startop        => startop,        -- Start the en/decryption.      (IN)
      stopop         => stopop,         -- Stop the en/decryption.       (IN)
      -- Read Interface:
      start_read     => start_read,     -- Start reading data.           (OUT)
      read_size      => read_size,      -- Size of data to read.         (OUT)
      read_addr      => read_addr,      -- Address of data to read.      (OUT)
      --
      read_done      => read_done,      -- All data read.                (IN)
      read_word0     => read_word0,     -- Read word 0.                  (IN)
      read_word1     => read_word1,     -- Read word 1.                  (IN)
      read_word2     => read_word2,     -- Read word 2.                  (IN)
      read_word3     => read_word3,     -- Read word 3.                  (IN)
      -- Write Interface
      start_write    => start_write,    -- Start writing data.           (OUT)
      write_size     => write_size,     -- Size of data to write.        (OUT)
      write_addr     => write_addr,     -- Write address                 (OUT)
      write_word0    => write_word0,    -- Word 0 to be written.         (OUT)
      write_word1    => write_word1,    -- Word 1 to be written.         (OUT)
      write_word2    => write_word2,    -- Word 2 to be written.         (OUT)
      write_word3    => write_word3,    -- Word 3 to be written.         (OUT)
      --
      write_done     => write_done,     -- All data written.             (IN)
      -- Controls
      key_load4      => key_load4,     -- Save the first 4 key bytes.    (OUT)
      start_expand   => start_expand,  -- Starts Key expansion.          (OUT)
      start_cipher   => start_cipher,  -- Starts encryption round        (OUT)
      --
      expand_done    => expand_done,   -- Key expansion done.            (IN)
      cipher_done    => cipher_done,   -- En/decryption round done.      (IN)
      ciph_done_early=> ciph_done_early,-- Flag 2 cc before cipher_done.  (IN)
      -- AES block cipher interface
      -- Data to AES block cipher.
      aes_state_w0  => aes_state_w0, --                                (OUT)
      aes_state_w1  => aes_state_w1, --                                (OUT)
      aes_state_w2  => aes_state_w2, --                                (OUT)
      aes_state_w3  => aes_state_w3, --                                (OUT)
      -- Result from AES block cipher.
      result_w0      => result_w0,     --                                (IN)
      result_w1      => result_w1,     --                                (IN)
      result_w2      => result_w2,     --                                (IN)
      result_w3      => result_w3,     --                                (IN)
      -- Diagnostic port.
      aes_ctrl_diag  => aes_ctrl_diag  --                                (OUT)
      );
  ---------------------------------------- End of port map for AES control block

  ------------------------------------------------- Port map for AES_BlockCipher
  -- In CCM, the key size is always 16 bytes.
  aes_ksize  <= "010000";
  key_load8  <= '0';
  -- In CCM, the AES blockcipher is always used in encryption mode.
  aes_opmode <= '1';
  
  aes_blockcipher_1: aes_blockcipher
  generic map (
    ccm_mode_g   => 1                   -- 1 to use the AES cipher in CCM mode.
  )
  port map(
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk          => clk,                -- AHB clock.                    (IN)
    reset_n      => reset_n,            -- AHB reset. Inverted logic.    (IN)
    --------------------------------------
    -- Control lines
    --------------------------------------
    opmode       => aes_opmode,         -- Indicates Rx(0) or Tx(1) mode.(IN)
    aes_ksize    => aes_ksize,          -- Size of the key in bytes.     (IN)
    key_load4    => key_load4,          -- Save the first 4 key bytes.   (IN)
    key_load8    => key_load8,          -- Save the last 4 key bytes.    (IN)
    start_expand => start_expand,       -- To start Key Schedule.        (IN)
    start_cipher => start_cipher,       -- To encrypt/decrypt one state. (IN)
    --
    expand_done  => expand_done,        -- Key Schedule done.            (OUT)
    cipher_done  => cipher_done,        -- Encryption/decryption done.   (OUT)
    ciph_done_early => ciph_done_early, -- Flag 2 cc before cipher_done. (IN)
    --------------------------------------
    -- Interrupt
    --------------------------------------
    stopop       => stopop,             -- Stops the encryption/decryption(IN)
    --------------------------------------
    -- Key words
    --------------------------------------
    init_key_w0  => read_word0,         -- Initial key word no.0.        (IN)
    init_key_w1  => read_word1,         -- Initial key word no.1.        (IN)
    init_key_w2  => read_word2,         -- Initial key word no.2.        (IN)
    init_key_w3  => read_word3,         -- Initial key word no.3.        (IN)
    init_key_w4  => read_word0,         -- Initial key word no.4.        (IN)
    init_key_w5  => read_word1,         -- Initial key word no.5.        (IN)
    init_key_w6  => read_word2,         -- Initial key word no.6.        (IN)
    init_key_w7  => read_word3,         -- Initial key word no.7.        (IN)
    --------------------------------------
    -- Data state to encrypt/decrypt
    --------------------------------------
    init_state_w0 => aes_state_w0,      -- Initial State word no.0.      (IN)
    init_state_w1 => aes_state_w1,      -- Initial State word no.1.      (IN)
    init_state_w2 => aes_state_w2,      -- Initial State word no.2.      (IN)
    init_state_w3 => aes_state_w3,      -- Initial State word no.3.      (IN)
    --------------------------------------
    -- Result (Encrypted/decrypted State)
    --------------------------------------
    result_w0    => result_w0,          -- Result word 0.                (OUT)
    result_w1    => result_w1,          -- Result word 1.                (OUT)
    result_w2    => result_w2,          -- Result word 2.                (OUT)
    result_w3    => result_w3,          -- Result word 3.                (OUT)
    --------------------------------------
    -- AES SRAM Interface
    --------------------------------------
    sram_wdata   => sram_wdata,         -- Data to be written.           (OUT)
    sram_address => sram_addr,          -- Address to write the data.    (OUT)
    sram_wen     => sram_wen,           -- Write Enable.                 (OUT)
    sram_cen     => sram_cen,           -- Chip Enable. Inverted logic.  (OUT)
    --
    sram_rdata   => sram_rdata          -- Data read from the SRAM.      (IN)
  );
  ------------------------------------------ End of Port map for AES_BlockCipher

end RTL;
