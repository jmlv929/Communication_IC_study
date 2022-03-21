
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of stream_processor is

------------------------------------------------------------- Signal declaration
  -- Signals for endianness converter.
  signal acctype         : std_logic_vector( 1 downto 0); -- Type of data.
  -- Little endian busses.
  signal hrdata_int      : std_logic_vector(31 downto 0); -- Read data.
  signal hwdata_int      : std_logic_vector(31 downto 0); -- Write data
  -- Control lines:
  signal comply_d6_d4n   : std_logic; -- Low for D4.0 compliancy. 
  signal rc4_startop     : std_logic; -- startop Pulse for RC4 algorithm.
  signal aes_startop     : std_logic; -- startop Pulse for AES algorithm.
  signal rc4_process_done: std_logic; -- Pulse indicating RC4 finished.
  signal aes_process_done: std_logic; -- Pulse indicating AES finished.
  signal process_done    : std_logic; -- Pulse indicating encryption finished.
  signal start_read      : std_logic; -- Positive edge starts initialisation.
  signal read_done       : std_logic; -- Read done.
  signal read_done_dly   : std_logic; -- Read done delayed by one clock cycle.
  signal start_write     : std_logic; -- Positive edge starts AHB write.
  signal write_done      : std_logic; -- Storage of encrypted data done.
  signal stopop          : std_logic; -- Stop Operation interruption.
  signal rc4_crc_int     : std_logic; -- Pulse indicating CRC error.
  signal rc4_mic_int     : std_logic; -- Pulse indicating MIC error.

  -- Registers:
  signal crc_debug       : std_logic; -- Enable CRC stored for debug.
  signal mic_int         : std_logic; -- Pulse indicating MIC error.
  signal opmode          : std_logic; -- Indicates Rx (0) or Tx (1) mode.
  signal startop         : std_logic; -- Pulse that starts the encryption.
  -- Number of states (16 bytes) to be en/decrypted.
  signal state_number    : std_logic_vector(12 downto 0);
  
  -- Sizes:
  signal strpksize       : std_logic_vector( 7 downto 0); -- Key size in bytes.
  signal strpbsize       : std_logic_vector(15 downto 0); -- Data buffer size.
  signal aes_msize       : std_logic_vector( 5 downto 0); -- MAC size in bytes.

  -- Addresses:
  signal strpkaddr       : std_logic_vector(31 downto 0); -- Key address.
  signal strpcsaddr      : std_logic_vector(31 downto 0); -- Control structure.
  signal strpsaddr       : std_logic_vector(31 downto 0); -- Source data buffer.
  signal strpdaddr       : std_logic_vector(31 downto 0); -- Destination buffer.
  signal strpmaddr       : std_logic_vector(31 downto 0); -- Mac header.

  -- Controls from control structure.
  signal rc4_firstpack   : std_logic;
  signal rc4_lastpack    : std_logic;
  signal priority        : std_logic_vector( 7 downto 0);
  signal michael_w0      : std_logic_vector(31 downto 0);
  signal michael_w1      : std_logic_vector(31 downto 0);
  signal packet_num      : std_logic_vector(47 downto 0);
  signal enablecrc       : std_logic; -- Enables (1) or disables CRC operation.
  signal enablemic       : std_logic; -- Enables (1) or disables MIC operation.
  signal enablecrypt     : std_logic; -- Enables (1) or disable (0) encryption.

  -- AHB access:
  signal ahb_interrupt   : std_logic; -- AHB interrupt (error cycle or retry).
  -- AHB read access:
  signal read_size       : std_logic_vector( 3 downto 0); -- Size of read data.
  signal read_addr       : std_logic_vector(31 downto 0); -- Read address.
  -- Data read on the AHB.
  signal read_word0      : std_logic_vector(31 downto 0);
  signal read_word1      : std_logic_vector(31 downto 0);
  signal read_word2      : std_logic_vector(31 downto 0);
  signal read_word3      : std_logic_vector(31 downto 0);
  -- AHB write access:
  signal write_size      : std_logic_vector( 3 downto 0); -- Size of write data.
  signal write_addr      : std_logic_vector(31 downto 0); -- Write address.

  -- Encryption / decryption result
  signal result_w0       : std_logic_vector(31 downto 0);
  signal result_w1       : std_logic_vector(31 downto 0);
  signal result_w2       : std_logic_vector(31 downto 0);
  signal result_w3       : std_logic_vector(31 downto 0);

  -- AES Algorithm:
  signal aes_mic_int     : std_logic; -- Interrupt on AES-CCM MIC error.
  signal aes_start_read  : std_logic; -- Positive edge starts AHB read.
  signal aes_read_size   : std_logic_vector( 3 downto 0); -- Size of read data.
  signal aes_read_addr   : std_logic_vector(31 downto 0); -- Read address.
  signal aes_start_write : std_logic; -- Positive edge starts AHB write.
  signal aes_write_size  : std_logic_vector( 3 downto 0); -- Size of write data
  signal aes_write_addr  : std_logic_vector(31 downto 0); -- Write address.
  -- AES encryption / decryption result or data to write.
  signal aes_result_w0   : std_logic_vector(31 downto 0);
  signal aes_result_w1   : std_logic_vector(31 downto 0);
  signal aes_result_w2   : std_logic_vector(31 downto 0);
  signal aes_result_w3   : std_logic_vector(31 downto 0);
  -- AES SRAM LINES
  signal aesram_wdata    : std_logic_vector(127 downto 0); -- AES SRAM wr. data.
  signal aesram_address  : std_logic_vector(  3 downto 0); -- AES SRAM address.
  signal aesram_wen      : std_logic; -- AES SRAM write enable. Inverted logic
  signal aesram_cen      : std_logic; -- AES SRAM chip enable. Inverted logic.
  signal aesram_rdata    : std_logic_vector(127 downto 0); -- AES Read data.

  -- RC4 Algorithm:
  signal rc4_start_read  : std_logic; -- Starts read sequence for the RC4.
  signal rc4_read_size   : std_logic_vector( 3 downto 0); -- Read size.
  signal rc4_read_addr   : std_logic_vector(31 downto 0); -- Read add
  signal rc4_start_write : std_logic; -- Starts write sequence for the RC4.
  signal rc4_write_size  : std_logic_vector( 3 downto 0); -- Write size.
  signal rc4_write_addr  : std_logic_vector(31 downto 0); -- Wr. addr
  -- RC4 encryption / decryption result or data to write.
  signal rc4_result_w0   : std_logic_vector(31 downto 0);
  signal rc4_result_w1   : std_logic_vector(31 downto 0);
  signal rc4_result_w2   : std_logic_vector(31 downto 0);
  signal rc4_result_w3   : std_logic_vector(31 downto 0);
  -- RC4 SRAM LINES
  signal rc4ram_wdata    : std_logic_vector( 7 downto 0); -- RC4 SRAM Wr. data.
  signal rc4ram_address  : std_logic_vector( 8 downto 0); -- RC4 SRAM Address.
  signal rc4ram_wen      : std_logic; -- RC4 SRAM write enable. Inverted logic.
  signal rc4ram_cen      : std_logic; -- RC4 SRAM chip enable. Inverted logic.
  signal rc4ram_rdata    : std_logic_vector( 7 downto 0); -- RC4 SRAM Read data

  -- Signals for diagnostic port.
  signal rc4_diag        : std_logic_vector( 7 downto 0);
  signal aes_diag        : std_logic_vector( 7 downto 0);
  signal reg_diag        : std_logic_vector( 7 downto 0);
  signal ctrl_diag       : std_logic_vector( 7 downto 0);
  signal ahb_diag        : std_logic_vector( 7 downto 0);
  signal strp_rc4_diag   : std_logic_vector(15 downto 0);
  signal strp_aes_diag   : std_logic_vector(15 downto 0);

------------------------------------------------------ End of Signal declaration

begin

  -- Diagnostic ports.
  strp_rc4_diag <= ctrl_diag(2 downto 0) & -- 15:13 cryptmode
                   rc4_firstpack         & -- 12
                   rc4_lastpack          & -- 11
                   stopop                & -- 10
                   mic_int               & -- 9
                   rc4_crc_int           & -- 8
                   ahb_diag(2 downto 0)  & -- 7:5   ahb_state
                   rc4_diag(4 downto 0)  ; -- 4:0   rc4_state
  
  strp_aes_diag <= reg_diag(2)           & -- 15    select_cs0
                   ctrl_diag(2)          & -- 14    cryptmode = aes
                   startop               & -- 13
                   ahb_diag(5 downto 4)  & -- 12:11 busreq & patch_htrans
                   stopop                & -- 10
                   mic_int               & -- 9
                   ahb_diag(3 downto 0)  & -- 8:5   inc_addr & ahb_state
                   opmode                & -- 4
                   aes_diag(3 downto 0)  ; -- 3:0   aes_state

  test_vector <= strp_rc4_diag & strp_aes_diag;
               
  -----------------------------------------------------------------------------
  -- RAM Connexion
  -----------------------------------------------------------------------------
  -- AES SRAM:
  aesram_di_o  <= aesram_wdata;
  aesram_a_o   <= aesram_address;
  aesram_rw_no <= aesram_wen;
  aesram_cs_no <= aesram_cen;
  aesram_rdata <= aesram_do_i;
  -- RC4 SRAM:
  rc4ram_di_o  <= rc4ram_wdata;
  rc4ram_a_o   <= rc4ram_address;
  rc4ram_rw_no <= rc4ram_wen;
  rc4ram_cs_no <= rc4ram_cen;
  rc4ram_rdata <= rc4ram_do_i;

  -------------------------------------------- Port map for endianness_converter
  big_endian_gen : if big_endian_g = 1 generate
    endianness_converter_1 : endianness_converter
      port map (
        --------------------------------------
        -- Data
        --------------------------------------
        -- Little endian stream processor interface.
        wdata_i        => hwdata_int,
        rdata_o        => hrdata_int,
        -- Big endian system interface.
        wdata_o        => hwdata,
        rdata_i        => hrdata,
        --------------------------------------
        -- Controls
        --------------------------------------
        acctype        => acctype
        );
  end generate big_endian_gen;

  -- interface with a little endian system: forward data busses without changes.
  little_endian_gen : if big_endian_g = 0 generate
    hwdata     <= hwdata_int;
    hrdata_int <= hrdata;
  end generate little_endian_gen;
  ------------------------------------- End of Port map for endianness_converter

  ------------------------------------------------------ Port map for SP_control
  str_proc_control_1 : str_proc_control
    port map (
      --------------------------------------
      -- Clocks & Reset
      --------------------------------------
      clk                    => clk,
      reset_n                => reset_n,
      --------------------------------------
      -- Registers interface
      --------------------------------------
      startop                => startop,
      stopop                 => stopop,
      --
      process_done           => process_done,
      mic_int                => mic_int,
      --------------------------------------
      -- Endianness controls
      --------------------------------------
      acctype                => acctype,
      --------------------------------------
      -- RC4 Control lines
      --------------------------------------
      rc4_process_done       => rc4_process_done,
      rc4_start_read         => rc4_start_read,
      rc4_read_size          => rc4_read_size,
      rc4_read_addr          => rc4_read_addr,
      rc4_start_write        => rc4_start_write,
      rc4_write_size         => rc4_write_size,
      rc4_write_addr         => rc4_write_addr,
      rc4_mic_int            => rc4_mic_int,
      --
      rc4_startop            => rc4_startop,
      --------------------------------------
      -- AES Control lines
      --------------------------------------
      aes_process_done       => aes_process_done,
      aes_start_read         => aes_start_read,
      aes_read_size          => aes_read_size,
      aes_read_addr          => aes_read_addr,
      aes_start_write        => aes_start_write,
      aes_write_size         => aes_write_size,
      aes_write_addr         => aes_write_addr,
      aes_mic_int            => aes_mic_int,
      --
      aes_startop            => aes_startop,
      --------------------------------------
      -- AHB interface control lines
      --------------------------------------
      read_done              => read_done,
      --
      start_read             => start_read,
      read_size              => read_size,
      read_addr              => read_addr,
      read_done_dly          => read_done_dly,
      start_write            => start_write,
      write_size             => write_size,
      write_addr             => write_addr,
      --------------------------------------
      -- Data lines
      --------------------------------------
      state_number           => state_number,
      -- Data read on the AHB.
      read_word0             => read_word0,
      read_word1             => read_word1,
      read_word2             => read_word2,
      read_word3             => read_word3,
      -- RC4 encryption / decryption result or data to write.
      rc4_result_w0          => rc4_result_w0,
      rc4_result_w1          => rc4_result_w1,
      rc4_result_w2          => rc4_result_w2,
      rc4_result_w3          => rc4_result_w3,
      -- AES encryption / decryption result or data to write.
      aes_result_w0          => aes_result_w0,
      aes_result_w1          => aes_result_w1,
      aes_result_w2          => aes_result_w2,
      aes_result_w3          => aes_result_w3,
      -- Encryption / decryption result or data to write to AHB interface.
      result_w0              => result_w0,
      result_w1              => result_w1,
      result_w2              => result_w2,
      result_w3              => result_w3,
      --------------------------------------
      -- Control structure
      --------------------------------------
      strpcsaddr             => strpcsaddr,
      --
      rc4_firstpack          => rc4_firstpack,
      rc4_lastpack           => rc4_lastpack,
      opmode                 => opmode,
      priority               => priority,
      strpksize              => strpksize,
      aes_msize              => aes_msize,
      strpbsize              => strpbsize,
      strpsaddr              => strpsaddr,
      strpdaddr              => strpdaddr,
      strpmaddr              => strpmaddr,
      michael_w0             => michael_w0,
      michael_w1             => michael_w1,
      packet_num             => packet_num,
      enablecrypt            => enablecrypt,
      enablecrc              => enablecrc,
      enablemic              => enablemic,
      --------------------------------------
      -- Diagnostic port
      --------------------------------------
      ctrl_diag             => ctrl_diag
      );
  ----------------------------------------------- End of port map for SP_control

  ---------------------------------------------------- Port map for SP_registers
  sp_registers_1: sp_registers
  port map(
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    pclk            => clk,             -- APB clock.
    presetn         => reset_n,         -- APB reset.Inverted logic.
    --------------------------------------
    -- APB interface
    --------------------------------------
    paddr           => paddr,           -- APB Address.
    psel            => psel,            -- Selection line.
    pwrite          => pwrite,          -- 0 => Read; 1 => Write.
    penable         => penable,         -- APB enable line.
    pwdata          => pwdata,          -- APB Write data bus.
    --
    prdata          => prdata,          -- APB Read data bus.
    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done    => process_done,    -- Pulse indicating encryption finished.
    dataflowerr     => ahb_interrupt,   -- Pulse indicating AHB error.
    crcerr          => rc4_crc_int,     -- Pulse indicating CRC error.
    micerr          => mic_int,         -- Pulse indicating MIC error.
    --
    interrupt       => interrupt,       -- Stream Processor interruption.
    --------------------------------------
    -- Registers
    --------------------------------------
    startop         => startop,         -- Pulse that starts the encryption.
    stopop          => stopop,          -- Pulse that stops the encryption.
    crc_debug       => crc_debug,       -- Enable CRC stored for debug.
    strpcsaddr      => strpcsaddr,      -- Address of the control structure.
    strpkaddr       => strpkaddr,       -- Address of the key.
    comply_d6_d4n   => comply_d6_d4n,   -- Low for D4.0 compliancy.   (IN)
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    reg_diag        => reg_diag         -- Diagnostic port.
  );
  --------------------------------------------- End of Port map for SP_registers

  ------------------------------------------------------ Port map for AHB Access
  sp_ahb_access_1 : sp_ahb_access
    generic map (addrmax_g => 32)
    port map (
      -- Clocks & Reset
      clk                 => clk,
      reset_n             => reset_n,
      -- Controls
      sp_init             => stopop,
      -- Read access controls
      start_read          => start_read,
      read_size           => read_size,
      read_addr           => read_addr,
      read_done           => read_done,
      -- Read data
      read_word0          => read_word0,
      read_word1          => read_word1,
      read_word2          => read_word2,
      read_word3          => read_word3,
      -- Writer access controls
      start_write         => start_write,
      write_size          => write_size,
      write_addr          => write_addr,
      write_done          => write_done,
      -- Write data
      write_word0         => result_w0,
      write_word1         => result_w1,
      write_word2         => result_w2,
      write_word3         => result_w3,
      -- AHB master interface
      hgrant              => hgrant,
      hready              => hready,
      hresp               => hresp,
      hrdata              => hrdata_int,
      hwdata              => hwdata_int,
      hbusreq             => hbusreq,
      htrans              => htrans,
      hwrite              => hwrite,
      haddr               => haddr,
      hburst              => hburst,
      hsize               => hsize,
      -- Interrupt line
      ahb_interrupt       => ahb_interrupt,
      -- Diagnostic port
      diag                => ahb_diag
      );

  hprot <= (others => '0');  -- no protection mode  
  hlock <= '0';              -- No lock access
  --------------------------------------------- End of Port map for AHB Access


--=============================== RC4 ALGORITHM ==============================--
RC4_algorithm: if (aes_enable_g = 0 or aes_enable_g = 1) generate

  --------------------------------------------------- Port map for RC4_sequencer  
  rc4_crc_1: rc4_crc
  port map(
    --------------------------------------
    -- Clocks and resets
    --------------------------------------
    clk             => clk,             -- System clock.                (IN)
    reset_n         => reset_n,         -- System reset. Inverted logic.(IN)
    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done    => rc4_process_done,-- Indicates encryption finished(OUT)
    crc_int         => rc4_crc_int,     -- Indicates error in CRC.      (OUT)
    mic_int         => rc4_mic_int,     -- Indicates error in CRC.      (OUT)
    --------------------------------------
    -- Global controls
    --------------------------------------
    crc_debug       => crc_debug,       -- Enable CRC stored for debug.
    opmode          => opmode,          -- Indicates Rx(0) or Tx(1) mode(IN)
    startop         => rc4_startop,     -- Starts the encryption.       (IN)
    stopop          => stopop,          -- Stops the encryption. (IN)
    enablecrypt     => enablecrypt,     -- Enables(1) the encryption.   (IN)
    enablecrc       => enablecrc,       -- Enables (1) or disables CRC. (IN)
    enablemic       => enablemic,       -- Enables (1) or disables MIC. (IN)
    rc4_ksize       => strpksize,       -- Size of the key in bytes.    (IN)
    rc4_bsize_lsb   => strpbsize(3 downto 0),-- Data buffer size LSB.   (IN)
    state_number    => state_number,    -- Nb of data states to process.(IN)
    rc4_csaddr      => strpcsaddr,      -- Control structure address.   (IN)
    rc4_kaddr       => strpkaddr,       -- Address of the key.          (IN)
    rc4_saddr       => strpsaddr,       -- Address of source data buffer(IN)
    rc4_daddr       => strpdaddr,       -- Address of destination data. (IN)
    rc4_maddr       => strpmaddr,       -- Address of MAC header.       (IN)
    packet_num      => packet_num,      -- Packet number.               (IN)
    --------------------------------------
    -- Signals for Michael processing
    --------------------------------------
    comply_d6_d4n   => comply_d6_d4n,   -- Low for D4.0 compliancy.     (IN)
    firstpack       => rc4_firstpack,   -- First MPDU of an MSDU.       (IN)
    lastpack        => rc4_lastpack,    -- Last MPDU of an MSDU.        (IN)
    l_michael_init  => michael_w0,      -- Michael L init value.        (IN)
    r_michael_init  => michael_w1,      -- Michael R init value.        (IN)
    priority        => priority,        -- Priority field for MIC IV.   (IN)
    --------------------------------------
    -- Read Interface
    --------------------------------------
    start_read      => rc4_start_read,  -- Start reading data.          (OUT)
    read_done       => read_done,       -- All data read.               (IN)
    read_done_dly   => read_done_dly,   -- read_done delayed.           (IN)
    read_size       => rc4_read_size,   -- Size of data to read.        (OUT)
    read_addr       => rc4_read_addr,   -- Address to read data.        (OUT)
    read_word0      => read_word0,      -- Read word 0.                 (IN)
    read_word1      => read_word1,      -- Read word 1.                 (IN)
    read_word2      => read_word2,      -- Read word 2.                 (IN)
    read_word3      => read_word3,      -- Read word 3.                 (IN)
    --------------------------------------
    -- Write Interface:
    --------------------------------------
    start_write     => rc4_start_write, -- Start writing data.          (OUT)
    write_done      => write_done,      -- All data written.            (IN)
    write_size      => rc4_write_size,  -- Size of data to write.       (OUT)
    write_addr      => rc4_write_addr,  -- Address to write data.       (OUT)
    write_word0     => rc4_result_w0,   -- Word 0 to be written.        (OUT)
    write_word1     => rc4_result_w1,   -- Word 1 to be written.        (OUT)
    write_word2     => rc4_result_w2,   -- Word 2 to be written.        (OUT)
    write_word3     => rc4_result_w3,   -- Word 3 to be written.        (OUT)
    --------------------------------------
    -- RC4 SRAM
    --------------------------------------
    sram_wdata      => rc4ram_wdata,    -- Data to be written.          (OUT)
    sram_address    => rc4ram_address,  -- Address.                     (OUT)
    sram_wen        => rc4ram_wen,      -- Write Enable. Inverted logic.(OUT)
    sram_cen        => rc4ram_cen,      -- Chip Enable. Inverted logic. (OUT)
    sram_rdata      => rc4ram_rdata,    -- Data read.                   (IN)
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    rc4_diag        => rc4_diag         --                              (OUT)
  );
  -------------------------------------------- End of Port map for RC4_sequencer
end generate RC4_algorithm;

not_RC4_algorithm: if aes_enable_g = 2 generate
  rc4_process_done <= '1';              -- RC4 finished.
  rc4_crc_int      <= '0';              -- No CRC error.
  rc4_mic_int      <= '0';              -- No CRC error.
  rc4_start_read   <= '0';              -- Do not read data for the RC4.
  rc4_read_size    <= (others => '0');  -- Size of read data = 0.
  rc4_read_addr    <= (others => '0');  -- Address of read data = 0.
  rc4_start_write  <= '0';              -- Do not write data for the RC4.
  rc4_write_size   <= (others => '0');  -- Size of write data = 0.
  rc4_write_addr   <= (others => '0');  -- Address of write data = 0.
  rc4_result_w0    <= (others => '0');  -- Word to write = 0.
  rc4_result_w1    <= (others => '0');  -- Word to write = 0.
  rc4_result_w2    <= (others => '0');  -- Word to write = 0.
  rc4_result_w3    <= (others => '0');  -- Word to write = 0.
  rc4ram_wdata     <= (others => '0');  -- Data to be written in the RAM.
  rc4ram_address   <= (others => '0');  -- Address in the RAM.
  rc4ram_wen       <= '1';              -- SRAM write not enabled
  rc4ram_cen       <= '1';              -- SRAM disabled.
  rc4_diag         <= (others => '0');  -- Diagnostic port.

end generate not_RC4_algorithm;
--=========================== END OF RC4 ALGORITHM ===========================--


--=============================== AES ALGORITHM ==============================--
AES_algorithm: if (aes_enable_g = 1 or aes_enable_g = 2) generate

  --------------------------------------------------- Port map for AES_sequencer
  aes_ccm_1: aes_ccm
  generic map(
    addrmax_g => 32
  )
  port map(
    -- Clocks and resets
    clk         => clk,                 -- System clock.                (IN)
    reset_n     => reset_n,             -- System reset. Inverted logic.(IN)
    -- Interrupts
    process_done=> aes_process_done,    -- Indicates encryption finished(OUT)
    mic_int     => aes_mic_int,         -- Indicates an error on the MIC(OUT)
    -- Control Structure
    aes_msize   => aes_msize,           -- MAC header size.             (IN)
    priority    => priority,            -- Priority.                    (IN)
    aes_kaddr   => strpkaddr,           -- Size of the key in bytes     (IN)
    aes_bsize   => strpbsize,           -- Size of data buffer(bytes)   (IN)
    aes_csaddr  => strpcsaddr,          -- Control structure address    (IN)
    aes_saddr   => strpsaddr,           -- Address of source data buffer(IN)
    aes_daddr   => strpdaddr,           -- Address of destination data. (IN)
    aes_maddr   => strpmaddr,           -- Address of Mac header        (IN)
    enablecrypt => enablecrypt,         -- Enables(1) the encryption.   (IN)
    aes_packet_num => packet_num,       -- Packet number.               (IN)
    state_number   => state_number,     -- Number of 16-byte data blocks(IN)
    -- Registers
    startop     => aes_startop,         -- Starts the encryption.       (IN)
    stopop      => stopop,              -- Stops the encryption.        (IN)
    opmode      => opmode,              -- Indicates Rx (0) or Tx (1).  (IN)
    -- Read Interface:
    start_read  => aes_start_read,      -- Start reading data.          (OUT)
    read_done   => read_done,           -- All data read.               (IN)
    read_size   => aes_read_size,       -- Size of data to read.        (OUT)
    read_addr   => aes_read_addr,       -- Address to read data.        (OUT)
    read_word0  => read_word0,          -- Read word 0.                 (IN)
    read_word1  => read_word1,          -- Read word 1.                 (IN)
    read_word2  => read_word2,          -- Read word 2.                 (IN)
    read_word3  => read_word3,          -- Read word 3.                 (IN)
    -- Write Interface:
    start_write => aes_start_write,     -- Start writing data.          (OUT)
    write_done  => write_done,          -- All data written.            (IN)
    write_size  => aes_write_size,      -- Size of data to write.       (OUT)
    write_addr  => aes_write_addr,      -- Address to write data.       (OUT)
    write_word0 => aes_result_w0,       -- Word 0 to be written.        (OUT)
    write_word1 => aes_result_w1,       -- Word 1 to be written.        (OUT)
    write_word2 => aes_result_w2,       -- Word 2 to be written.        (OUT)
    write_word3 => aes_result_w3,       -- Word 3 to be written.        (OUT)
    -- AES SRAM:
    sram_wdata  => aesram_wdata,        -- Data to be written.          (OUT)
    sram_addr   => aesram_address,      -- Address.                     (OUT)
    sram_wen    => aesram_wen,          -- Write Enable. Inverted logic.(OUT)
    sram_cen    => aesram_cen,          -- Chip Enable. Inverted logic. (OUT)
    sram_rdata  => aesram_rdata,        -- Data read.                   (IN)
    -- Diagnostic port:
    aes_diag    => aes_diag             --                              (OUT)
  );
  -------------------------------------------- End of Port map for AES_sequencer
end generate AES_algorithm;

not_AES_algorithm: if aes_enable_g = 0 generate

  aes_process_done <= '1';              -- AES finished.
  aes_mic_int      <= '0';              -- No MIC error.
  aes_start_read   <= '0';              -- Do not read data for the AES.
  aes_read_size    <= (others => '0');  -- Size of read data = 0.
  aes_read_addr    <= (others => '0');  -- Address of read data = 0.
  aes_start_write  <= '0';              -- Do not write data for the AES.
  aes_write_size   <= (others => '0');  -- Size of write data = 0.
  aes_write_addr   <= (others => '0');  -- Address of write data = 0.
  aes_result_w0    <= (others => '0');  -- Word to write = 0.
  aes_result_w1    <= (others => '0');  -- Word to write = 0.
  aes_result_w2    <= (others => '0');  -- Word to write = 0.
  aes_result_w3    <= (others => '0');  -- Word to write = 0.
  aesram_wdata     <= (others => '0');  -- Data to be written in the RAM.
  aesram_address   <= (others => '0');  -- Address in the RAM.
  aesram_wen       <= '1';              -- SRAM write not enabled
  aesram_cen       <= '1';              -- SRAM disabled.
  aes_diag         <= (others => '0');  -- Diagnostic port.

end generate not_AES_algorithm;
--=========================== END OF AES ALGORITHM ===========================--

end RTL;
