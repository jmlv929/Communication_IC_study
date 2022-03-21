
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of rc4_crc is

------------------------------------------------------------- Signal declaration
signal logic0             : std_logic;-- Zero.
-- Output signal used internally.
signal int_read_size      : std_logic_vector( 3 downto 0);-- Read size in bytes
--------------------------------------
-- Commands for the different sub-blocks.
--------------------------------------
signal start_sbinit       : std_logic;      -- Positive edge starts S-box init.
signal sbinit_done        : std_logic;      -- S-Box initialisation done.
signal start_keymix       : std_logic;      -- Start TKIP key mixing.
signal key1_key2n         : std_logic;      -- TKIP key mixing phase ( 1 or 2).
signal keymix1_done       : std_logic;      -- TKIP key mixing phase 1 done.
signal keymix2_done       : std_logic;      -- TKIP key mixing phase 2 done.
signal start_keyload      : std_logic;      -- Positive edge starts key loading.
signal keyload_done       : std_logic;      -- High when Key is stored in SRAM.
signal start_sboxgen      : std_logic;      -- Pos. edge starts S-box generation
signal sboxgen_done       : std_logic;      -- S-Box generation done.
signal init_keystr        : std_logic;      -- Initialises Key Stream.
signal start_keystr       : std_logic;      -- Starts Key Stream.
signal kstr_done          : std_logic;      -- Indicates Key Stream calculated.
signal kstr_done_early    : std_logic;      -- Flag two cycles before kstr_done.
signal start_michael      : std_logic;      -- Starts the Michael block function
signal michael_done       : std_logic;      -- Michael block function done.
signal start_s2b          : std_logic;      -- Starts the state to byte for CRC
signal s2b_done           : std_logic;      -- Flag indicating CRC calculated.
signal s2b_done_early     : std_logic;      -- Flag two cycles before s2b_done.
signal crc_ld_init        : std_logic;      -- Initialises CRC calculation.
signal crc_calc           : std_logic;      -- Pulse to compute CRC byte.
--------------------------------------
-- SRAM lines from the different sub-blocks
--------------------------------------
-- S_Box initialisation
signal sboxinit_address   : std_logic_vector( 7 downto 0);-- Address bus.
signal sboxinit_wdata     : std_logic_vector( 7 downto 0);-- Write data.
signal sboxinit_wen       : std_logic;      -- Write enable.
signal sboxinit_cen       : std_logic;      -- Chip enable.
-- Key loading
signal key_sr_address     : std_logic_vector( 8 downto 0);-- Address bus.
signal key_sr_wdata       : std_logic_vector( 7 downto 0);-- Write data.
signal key_sr_wen         : std_logic;      -- Write enable.
signal key_sr_cen         : std_logic;      -- Chip enable.
-- S-Box Generation
signal sboxgen_address    : std_logic_vector( 8 downto 0);-- Address bus.
signal sboxgen_wdata      : std_logic_vector( 7 downto 0);-- Write data.
signal sboxgen_wen        : std_logic;      -- Write enable.
signal sboxgen_cen        : std_logic;      -- Chip enable.
-- Key Stream block
signal kstr_sr_address    : std_logic_vector( 8 downto 0);-- Address bus.
signal kstr_sr_wdata      : std_logic_vector( 7 downto 0);-- Write data.
signal kstr_sr_wen        : std_logic;      -- Write enable.
signal kstr_sr_cen        : std_logic;      -- Chip enable.
--------------------------------------
-- Key loading read controls
--------------------------------------
signal keyload_start_read : std_logic;      -- Positive edge starts read process
signal keyload_rd_size    : std_logic_vector( 3 downto 0);-- Size of read data.
signal keyload_rd_addr    : std_logic_vector(31 downto 0);-- Add to read data.
--------------------------------------
-- Key Stream data
--------------------------------------
signal kstr_word0         : std_logic_vector(31 downto 0);
signal kstr_word1         : std_logic_vector(31 downto 0);
signal kstr_word2         : std_logic_vector(31 downto 0);
signal kstr_word3         : std_logic_vector(31 downto 0);
signal kstr_size          : std_logic_vector( 3 downto 0);
--------------------------------------
-- Michael data processing
--------------------------------------
signal l_michael_in       : std_logic_vector(31 downto 0); -- L Michael input.
signal r_michael_in       : std_logic_vector(31 downto 0); -- R Michael input.
signal l_michael_out      : std_logic_vector(31 downto 0); -- L Michael result.
signal r_michael_out      : std_logic_vector(31 downto 0); -- R Michael result.
--------------------------------------
-- CRC processing
--------------------------------------
-- Number of bytes to serialize
signal state2byte_size    : std_logic_vector( 3 downto 0);
-- Data fed to the state to byte serializer.
signal data2crc_w0        : std_logic_vector(31 downto 0);
signal data2crc_w1        : std_logic_vector(31 downto 0);
signal data2crc_w2        : std_logic_vector(31 downto 0);
signal data2crc_w3        : std_logic_vector(31 downto 0);
-- Data byte fed to the CRC block.
signal byte_to_crc        : std_logic_vector( 7 downto 0);
-- CRC results.
signal crc_out_1st        : std_logic_vector( 7 downto 0);
signal crc_out_2nd        : std_logic_vector( 7 downto 0);
signal crc_out_3rd        : std_logic_vector( 7 downto 0);
signal crc_out_4th        : std_logic_vector( 7 downto 0);
--------------------------------------------
-- Signals for TKIP key mixing
--------------------------------------------
signal address2         : std_logic_vector(47 downto 0);
-- Mixed TKIP key.
signal tkip_key_w3      : std_logic_vector(31 downto 0);
signal tkip_key_w2      : std_logic_vector(31 downto 0);
signal tkip_key_w1      : std_logic_vector(31 downto 0);
signal tkip_key_w0      : std_logic_vector(31 downto 0);
--------------------------------------------
-- Signals for diagnostic port
--------------------------------------------
signal rc4_control_diag : std_logic_vector(7 downto 0);
------------------------------------------------------ End of Signal declaration

begin

  -- Constant signal.
  logic0 <= '0';
  -- Assign output ports.
  read_size  <= int_read_size;
  -- Diagnostic port.
  rc4_diag(7 downto 5) <= (others => '0');
  rc4_diag(4)          <= sbinit_done;
  rc4_diag(3 downto 0) <= rc4_control_diag(3 downto 0);

--===================== RC4 State Machine and Controls =======================--

  ----------------------------------------------- Port map for RC4 control block
  rc4_control_1 : rc4_control
    port map (
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      clk                => clk,          -- System clock.                (IN)
      reset_n            => reset_n,      -- System reset. Inverted logic.(IN)
      --------------------------------------
      -- Global controls
      --------------------------------------
      crc_debug          => crc_debug,    -- Enable CRC stored for debug. (IN)
      opmode             => opmode,       -- Indicates Rx or Tx mode.     (IN)
      startop            => startop,      -- Starts the encryption.       (IN)
      stopop             => stopop,       -- Stops the encryption.        (IN)
      enablecrypt        => enablecrypt,  -- Enables the encryption.      (IN)
      enablecrc          => enablecrc,    -- Enables CRC operation.       (IN)
      enablemic          => enablemic,    -- Enables MIC operation.       (IN)
      rc4_bsize_lsb      => rc4_bsize_lsb,-- Data buffer size LSB.        (IN)
      state_number       => state_number, -- Number of states to process. (IN)
      rc4_csaddr         => rc4_csaddr,   -- Control structure address.   (IN)
      rc4_saddr          => rc4_saddr,    -- Source buffer address.       (IN)
      rc4_daddr          => rc4_daddr,    -- Destination buffer address.  (IN)
      rc4_maddr          => rc4_maddr,    -- Control structure address.   (IN)
      rc4_kaddr          => rc4_kaddr,    -- Address of the key.          (IN)
      process_done       => process_done, -- Encryption finished.         (IN)
      crc_int            => crc_int,      -- Indicates error in CRC.      (IN)
      mic_int            => mic_int,      -- Indicates error in MIC.      (IN)
      --------------------------------------
      -- Commands
      --------------------------------------
      start_sbinit       => start_sbinit, -- Start S-Box init.            (IN)
      start_keymix       => start_keymix, -- Start TKIP key mixing.       (IN)
      key1_key2n         => key1_key2n,   -- TKIP key mixing phase.       (IN)
      start_keyload      => start_keyload,-- Start key loading in RAM.    (IN)
      start_sboxgen      => start_sboxgen,-- Start S-Box generation.      (IN)
      init_keystr        => init_keystr,  -- Start key stream init.       (IN)
      start_keystr       => start_keystr, -- Start key stream generation. (IN)
      start_michael      => start_michael,-- Start Michael processing.    (IN)
      start_s2b          => start_s2b,    -- Start CRC serializer.        (IN)
      crc_ld_init        => crc_ld_init,  -- Initialises CRC calculation. (IN)
      crc_calc           => crc_calc,     -- Pulse to compute CRC byte.   (IN)
      --                                 
      sbinit_done        => sbinit_done,  -- S-Box init done.             (OUT)
      keymix1_done       => keymix1_done, -- Key mixing phase 1 done.     (OUT)
      keymix2_done       => keymix2_done, -- Key mixing phase 2 done.     (OUT)
      keyload_done       => keyload_done, -- Key is stored in SRAM.       (OUT)
      sboxgen_done       => sboxgen_done, -- S-Box generation done.       (OUT)
      kstr_done          => kstr_done,    -- Key Stream calculated.       (OUT)
      michael_done       => michael_done, -- Michael block function done. (OUT)
      s2b_done           => s2b_done,     -- CRC calculated.              (OUT)
      kstr_done_early    => kstr_done_early,-- 2 cycles before kstr_done. (OUT)
      s2b_done_early     => s2b_done_early,-- Two cycles before s2b_done. (OUT)
      --------------------------------------
      -- Signals from control structure / MAC header
      --------------------------------------
      firstpack          => firstpack,    -- MPDU is the first of an MSDU.(IN)
      lastpack           => lastpack,     -- MPDU is the last of an MSDU. (IN)
      priority           => priority,     -- Priority field.              (IN)
      --
      address2           => address2,     -- Address 2 field.             (OUT)
      --------------------------------------
      -- Signals for Michael processing
      --------------------------------------
      comply_d6_d4n      => comply_d6_d4n, -- Low for D4.0 compliancy.    (IN)
      l_michael_init     => l_michael_init,-- Michael L initial value.    (IN)
      r_michael_init     => r_michael_init,-- Michael R initial value.    (IN)
      l_michael_in       => l_michael_in,  -- L data to michael block.    (IN)
      r_michael_in       => r_michael_in,  -- R data to michael block.    (IN)
      l_michael_out      => l_michael_out, -- L data from michael block.  (OUT)
      r_michael_out      => r_michael_out, -- R data from michael block.  (OUT)
      --------------------------------------
      -- Read interface
      --------------------------------------
      -- Controls from Keyload block.
      keyload_start_read => keyload_start_read,-- Start of read.          (IN)
      keyload_rd_size    => keyload_rd_size,   -- Read size.              (IN)
      keyload_rd_addr    => keyload_rd_addr,   -- Read address.           (IN)
      -- Controls from/to AHB interface
      start_read         => start_read,        -- Start of read.          (OUT)
      read_size          => int_read_size,     -- Read size.              (OUT)
      read_addr          => read_addr,         -- Read address.           (OUT)
      --
      read_done          => read_done,         -- Read done.              (IN)
      read_done_dly      => read_done_dly,     -- Read done delayed.      (IN)
      read_word0         => read_word0,        -- Read word 0.            (IN)
      read_word1         => read_word1,        -- Read word 1.            (IN)
      read_word2         => read_word2,        -- Read word 2.            (IN)
      read_word3         => read_word3,        -- Read word 3.            (IN)
      --------------------------------------
      -- Write interface
      --------------------------------------
      start_write        => start_write,       -- Start of write.         (OUT)
      write_size         => write_size,        -- Write size.             (OUT)
      write_addr         => write_addr,        -- Write address.          (OUT)
      write_done         => write_done,        -- Write done              (IN)
      write_word0        => write_word0,       -- Word 0 to be written.   (OUT)
      write_word1        => write_word1,       -- Word 1 to be written.   (OUT)
      write_word2        => write_word2,       -- Word 2 to be written.   (OUT)
      write_word3        => write_word3,       -- Word 3 to be written.   (OUT)
      --------------------------------------
      -- Key Stream
      --------------------------------------                              
      kstr_word0         => kstr_word0,        --                         (IN)
      kstr_word1         => kstr_word1,        --                         (IN)
      kstr_word2         => kstr_word2,        --                         (IN)
      kstr_word3         => kstr_word3,        --                         (IN)
      --
      kstr_size          => kstr_size,         -- Size of data buffer.    (OUT)
      --------------------------------------
      -- Data
      --------------------------------------
      -- Data fed to the state to byte serializer.
      data2crc_w0        => data2crc_w0,      --                         (OUT)
      data2crc_w1        => data2crc_w1,      --                         (OUT)
      data2crc_w2        => data2crc_w2,      --                         (OUT)
      data2crc_w3        => data2crc_w3,      --                         (OUT)
      -- CRC results.
      crc_out_1st        => crc_out_1st,      --                         (IN)
      crc_out_2nd        => crc_out_2nd,      --                         (IN)
      crc_out_3rd        => crc_out_3rd,      --                         (IN)
      crc_out_4th        => crc_out_4th,      --                         (IN)
      -- Number of bytes to serialize
      state2byte_size    => state2byte_size,  --                         (OUT)
      --------------------------------------
      -- SRAM interface
      --------------------------------------
      -- Address, write data, write enable and chip enable from S_Box init.
      sboxinit_address   => sboxinit_address, --                         (IN)
      sboxinit_wdata     => sboxinit_wdata,   --                         (IN)
      sboxinit_wen       => sboxinit_wen,     --                         (IN)
      sboxinit_cen       => sboxinit_cen,     --                         (IN)
      -- Address, write data, write enable and chip enable from Key loading.
      key_sr_address     => key_sr_address,   --                         (IN)
      key_sr_wdata       => key_sr_wdata,     --                         (IN)
      key_sr_wen         => key_sr_wen,       --                         (IN)
      key_sr_cen         => key_sr_cen,       --                         (IN)
      -- Address, write data, write enable and chip enable from S-Box Generation.
      sboxgen_address    => sboxgen_address,  --                         (IN)
      sboxgen_wdata      => sboxgen_wdata,    --                         (IN)
      sboxgen_wen        => sboxgen_wen,      --                         (IN)
      sboxgen_cen        => sboxgen_cen,      --                         (IN)
      -- Address, write data, write enable and chip enable from Key Stream block.
      kstr_sr_address    => kstr_sr_address,  --                         (IN)
      kstr_sr_wdata      => kstr_sr_wdata,    --                         (IN)
      kstr_sr_wen        => kstr_sr_wen,      --                         (IN)
      kstr_sr_cen        => kstr_sr_cen,      --                         (IN)
      -- SRAM lines.
      sram_wdata         => sram_wdata,       --                         (OUT)
      sram_address       => sram_address,     --                         (OUT)
      sram_wen           => sram_wen,         --                         (OUT)
      sram_cen           => sram_cen,         --                         (OUT)
      --------------------------------------
      -- Diagnostic port
      --------------------------------------
      rc4_diag           => rc4_control_diag  --                         (OUT)
      );
  ---------------------------------------- End of port map for RC4 control block


--============================== RC4 operation ===============================--

  -------------------------------------------- Port map for S-Box Initialisation
  rc4_sboxinit_1: rc4_sboxinit
  generic map (
    addrmax_g    => 8                   -- SRAM address bus with.
  )
  port map(
    clk          => clk,                -- System clock.                  (IN)
    reset_n      => reset_n,            -- System reset. Inverted logic.  (IN)
    -- Selector
    start_sbinit => start_sbinit,       -- Starts s-box initialisation.   (IN)
    sbinit_done  => sbinit_done,        -- S-box initialisation done.     (OUT)
    -- SRAM
    sr_wdata     => sboxinit_wdata,     -- SRAM write data.               (OUT)
    sr_address   => sboxinit_address,   -- SRAM address.                  (OUT)
    sr_wen       => sboxinit_wen,       -- SRAM write enable. Inv. logic. (OUT)
    sr_cen       => sboxinit_cen        -- SRAM Chip Enable.Inverted logic(OUT)
  );
  ------------------------------------- End of Port map for S-Box Initialisation
  
  ----------------------------------------------------- Port map for Key Loading
  rc4_keyloading_1: rc4_keyloading
  port map(
    clk          => clk,                -- System clock.                  (IN)
    reset_n      => reset_n,            -- System reset. Inverted logic.  (IN)
    -- Selector
    tkip_mode    => enablemic,
    start_keyload=> start_keyload,      -- Starts key loading.            (IN)
    keyload_done => keyload_done,       -- Indicates Key stored in SRAM.  (OUT)
    -- Interrupt
    stopop       => stopop,             -- Stop operation. Stop key loading(IN)
    -- Read Data Interface
    rd_size      => keyload_rd_size,    -- Size of data to read.          (OUT)
    rd_addr      => keyload_rd_addr,    -- Address to read data.          (OUT)
    rd_start_read=> keyload_start_read, -- Starts read process.           (OUT)
    rd_read_done => read_done,          -- Indicates read process done.   (IN)
    rd_word0     => read_word0,         -- Word read.                     (IN)
    rd_word1     => read_word1,         -- Word read.                     (IN)
    rd_word2     => read_word2,         -- Word read.                     (IN)
    rd_word3     => read_word3,         -- Word read.                     (IN)
    tkip_key_w0  => tkip_key_w0,        -- Mixed TKIP key.                (IN)
    tkip_key_w1  => tkip_key_w1,        -- Mixed TKIP key.                (IN)
    tkip_key_w2  => tkip_key_w2,        -- Mixed TKIP key.                (IN)
    tkip_key_w3  => tkip_key_w3,        -- Mixed TKIP key.                (IN)
    -- SRAM
    sr_wdata     => key_sr_wdata,       -- SRAM write data.               (OUT)
    sr_address   => key_sr_address,     -- SRAM address.                  (OUT)
    sr_wen       => key_sr_wen,         -- SRAM write enable.             (OUT)
    sr_cen       => key_sr_cen,         -- SRAM chip enable.              (OUT)
    sr_rdata     => sram_rdata,         -- SRAM read data.                (IN)
    -- Registers
    rc4_ksize    => rc4_ksize,          -- Size of the key in bytes       (IN)
    rc4_kaddr    => rc4_kaddr           -- Address of the key.            (IN)
  );
  ---------------------------------------------- End of Port map for Key Loading

  ------------------------------------------------ Port map for S-Box generation
  rc4_sboxgenerator_1: rc4_sboxgenerator
  port map(
    clk          => clk,                -- System clock.                  (IN)
    reset_n      => reset_n,            -- System reset. Inverted logic.  (IN)
    -- Selector
    start_sboxgen=> start_sboxgen,      -- Starts s-box generation        (IN)
    sboxgen_done => sboxgen_done,       -- Indicates s-box generation done(OUT)
    -- SRAM
    sr_wdata     => sboxgen_wdata,      -- SRAM write data.               (OUT)
    sr_address   => sboxgen_address,    -- SRAM address.                  (OUT)
    sr_wen       => sboxgen_wen,        -- SRAM write enable.             (OUT)
    sr_cen       => sboxgen_cen,        -- SRAM write enable.             (OUT)
    sr_rdata     => sram_rdata          -- SRAM read data.                (IN)
  );
  ----------------------------------------- End of Port map for S-Box generation

  ------------------------------------------------------- Port map for KeyStream
  rc4_keystream_1: rc4_keystream
  port map(
    clk               => clk,            -- AHB clock.                    (IN)
    reset_n           => reset_n,        -- AHB reset. Inverted logic.    (IN)
    -- Selector
    init_keystr       => init_keystr,    -- Initialises key stream.       (IN)
    start_keystr      => start_keystr,   -- Starts key stream generation. (IN)
    keystr_done       => kstr_done,      -- Indicates key stream finished.(OUT)
    keystr_done_early => kstr_done_early,-- Two cycles before kstr_done.  (OUT)
    -- Key Stream Words
    key_stream0       => kstr_word0,     -- Key stream byte 0.            (OUT)
    key_stream1       => kstr_word1,     -- Key stream byte 1.            (OUT)
    key_stream2       => kstr_word2,     -- Key stream byte 2.            (OUT)
    key_stream3       => kstr_word3,     -- Key stream byte 3.            (OUT)
    -- SRAM
    sr_wdata          => kstr_sr_wdata,  -- SRAM write data.              (OUT)
    sr_address        => kstr_sr_address,-- SRAM address.                 (OUT)
    sr_wen            => kstr_sr_wen,    -- SRAM write enable. Inv. logic.(OUT)
    sr_cen            => kstr_sr_cen,    -- SRAM write enable. Inv. logic.(OUT)
    sr_rdata          => sram_rdata,     -- SRAM read data.               (IN)
    -- Registers
    kstr_size         => kstr_size       -- Size of data buffer in bytes. (IN)
  );
  ------------------------------------------------ End of Port map for KeyStream

--============================= TKIP Key Mixing ==============================--

  ------------------------------------------------- Port map for TKIP key mixing
  tkip_key_mixing_1 : tkip_key_mixing
    port map (
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      reset_n             => reset_n,     -- AHB clock.                   (IN)
      clk                 => clk,         -- AHB reset. Inverted logic.   (IN)
      --------------------------------------
      -- Controls
      --------------------------------------
      key1_key2n          => key1_key2n,  -- Key mixing phase (1 or 2).   (IN)
      start_keymix        => start_keymix,-- Pulse to start key mixing.   (IN)
      --
      keymix1_done        => keymix1_done,-- Key mixing phase 1 is done.  (OUT)
      keymix2_done        => keymix2_done,-- Key mixing phase 2 is done.  (OUT)
      --------------------------------------
      -- Data
      --------------------------------------
      tsc                 => packet_num,  -- Sequance counter.            (IN) 
      address2            => address2,    -- Address 2 field.             (IN) 
      -- Temporal key (128 bits)
      temp_key_w3         => read_word3,  --                              (IN)
      temp_key_w2         => read_word2,  --                              (IN)
      temp_key_w1         => read_word1,  --                              (IN)
      temp_key_w0         => read_word0,  --                              (IN)
      -- TKIP key (128 bits)
      tkip_key_w3         => tkip_key_w3, --                              (OUT)
      tkip_key_w2         => tkip_key_w2, --                              (OUT)
      tkip_key_w1         => tkip_key_w1, --                              (OUT)
      tkip_key_w0         => tkip_key_w0  --                              (OUT)
      );
  ------------------------------------------ End of Port map for TKIP key mixing
  
--==================================== CRC ===================================--

  ------------------------------------------------------ Port map for State2Byte
  state2byte_1: state2byte
  port map(
    clk            => clk,              -- System clock.                   (IN)
    reset_n        => reset_n,          -- System reset. Inverted logic.   (IN)
    -- Flags:
    start_s2b      => start_s2b,        -- Signal that starts data storage (IN)
    s2b_done       => s2b_done,         -- Flag indicating result written. (OUT)
    s2b_done_early => s2b_done_early,   -- Flag two cycles before s2b_done.(OUT)
    -- Size:
    size           => state2byte_size,  -- Bytes to serialize.             (IN)
    -- Input state:
    state_word0    => data2crc_w0,      -- First state word.               (IN)
    state_word1    => data2crc_w1,      -- Second state word.              (IN)
    state_word2    => data2crc_w2,      -- Third state word.               (IN)
    state_word3    => data2crc_w3,      -- Fourth state word.              (IN)
    wait_cycle     => logic0,           -- Wait signal                     (IN)
    -- Output byte.
    byte_to_crc    => byte_to_crc       -- Output byte.                    (OUT)
  );
  ----------------------------------------------- End of Port map for State2Byte

  --------------------------------------------------------- Port map for CRC32_8
  crc_calculator_1: crc32_8
  port map(
    clk          => clk,
    resetn       => reset_n,
    data_in      => byte_to_crc,        -- 8-b in for parallel computing.  (IN)
    ld_init      => crc_ld_init,        -- initialize the CRC.             (IN)
    calc         => crc_calc,           -- ask of calculation of the available
    --                                     data.                           (IN)
    crc_out_1st  => crc_out_1st,        -- First word output.              (OUT)
    crc_out_2nd  => crc_out_2nd,        -- Second word output.             (OUT)
    crc_out_3rd  => crc_out_3rd,        -- Third word output.              (OUT)
    crc_out_4th  => crc_out_4th         -- Fourth word output.             (OUT)
  );
  -------------------------------------------------- End of Port map for CRC32_8

--============================ Michael processing ============================--

  ------------------------------------------ Port map for Michael block function
  michael_blkfunc_1 : michael_blkfunc
    port map (
      clk           => clk,              -- System clock.                  (IN)
      reset_n       => reset_n,          -- System reset. Inverted logic.  (IN)
      -- Flags
      start_michael => start_michael,    -- Signal to start block function.(IN)
      michael_done  => michael_done,     -- Flag indicating function done. (OUT)
      -- Input data
      l_michael_in  => l_michael_in,     -- L input value                  (IN)
      r_michael_in  => r_michael_in,     -- R input value                  (IN)
      -- Output data
      l_michael_out => l_michael_out,    -- L output value                 (OUT)
      r_michael_out => r_michael_out     -- L output value                 (OUT)
      );
  ----------------------------------- End of Port map for Michael block function

end RTL;
