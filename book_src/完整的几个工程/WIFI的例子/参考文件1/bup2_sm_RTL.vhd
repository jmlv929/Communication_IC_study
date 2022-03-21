
--============================================================================--
--                                   ARCHITECTURE                             --
--============================================================================--

architecture RTL of bup2_sm is

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  signal rxend_stat_i      : std_logic_vector(1 downto 0); -- RX end status
  signal rx_end            : std_logic;  -- end of packet and no auto resp needed
  signal rx_err            : std_logic;  -- unexpected end of packet or CRC error
  signal tx_end            : std_logic;  -- end of transmit packet
  signal tx_mode           : std_logic;  -- Bup in transmit mode            
  signal rx_mode           : std_logic;  -- Bup in reception mode
  signal rx_fcs_init       : std_logic;  -- RX init FCS computation
  signal rx_fcs_data_valid : std_logic;  -- RX compute FCS on mem seq data
  signal tx_fcs_init       : std_logic;  -- TX init FCS computation
  signal tx_fcs_data_valid : std_logic;  -- TX compute FCS on mem seq data
  signal data_to_mem_seq_o : std_logic_vector(7 downto 0); -- byte data to Mem Seq
  signal load_rxptr        : std_logic;  -- pulse for mem seq to load rxptr
  signal load_txptr        : std_logic;  -- pulse for mem seq to load txptr
  signal last_word_rx      : std_logic;  -- next RX bytes are part of last word
  signal last_word_tx      : std_logic;  -- next TX bytes are part of last word
  signal sampled_queue     : std_logic_vector(3 downto 0);  -- sampled tx queue
  -- access type for endianness converter
  signal rx_acc_type       : std_logic_vector(1 downto 0);
  signal tx_acc_type       : std_logic_vector(1 downto 0);

--------------------------------------------
-- Diag signals
--------------------------------------------
signal tx_sm_diag          : std_logic_vector(2 downto 0);
signal tx_read_sm_diag     : std_logic_vector(1 downto 0);
signal rx_sm_diag          : std_logic_vector(7 downto 0);
signal gene_sm_diag        : std_logic_vector(2 downto 0);

------------------------------------------------------ End of Signal declaration

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------

begin
  
  rxend_stat <= rxend_stat_i;
  
  sampled_queue_it_num <= sampled_queue;
  
  bup_sm_diag <= sampled_queue &                   -- 17:14
                 gene_sm_diag &                    -- 13:11
                 tx_read_sm_diag &                 -- 10:9
                 tx_sm_diag &                      --  8:6
                 rx_sm_diag(7 downto 2);           --  5:0
                 
--------------------------------------------------------------------------------
-- General state machine
--------------------------------------------------------------------------------

  bup2_general_sm_1 : bup2_general_sm
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn            => hresetn,
    hclk               => hclk,
    --------------------------------------
    -- Generic BuP Registers
    -------------------------------------- 
    bup_sm_idle        => bup_sm_idle,
    reset_bcon_txen    => reset_bcon_txen,
    reset_acp_txen     => reset_acp_txen,
    reset_iac_txen     => reset_iac_txen,
    queue_it_num       => queue_it_num,

    --------------------------------------
    -- Commands from BuP Registers
    -------------------------------------- 
    vcs_enable         => vcs_enable,
    tximmstop          => tximmstop,
    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    testenable         => testenable,
    bup_testmode       => bup_testmode,
    --------------------------------------
    -- Interrupt Generator
    -------------------------------------- 
    ccabusy_it         => ccabusy_it,
    ccaidle_it         => ccaidle_it,
    --------------------------------------
    -- Timers
    -------------------------------------- 
    backoff_timer_it   => backoff_timer_it,
    sifs_timer_it      => sifs_timer_it,
    txstartdel_flag    => txstartdel_flag,
    iac_without_ifs    => iac_without_ifs,  -- Set if no IFS in IAC queue
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_cca_ind        => phy_cca_ind, 
    phy_rxstartend_ind => phy_rxstartend_ind,
    --------------------------------------
    -- RX/TX state machine
    -------------------------------------- 
    rxend_stat         => rxend_stat_i,      
    rx_end             => rx_end,      
    rx_err             => rx_err,      
    tx_end             => tx_end,     
    iac_txenable       => iac_txenable,
    iacaftersifs_ack   => iacaftersifs_ack,
    --
    tx_mode            => tx_mode,       
    rx_mode            => rx_mode,
    rxv_macaddr_match  => rxv_macaddr_match,    
    rx_abortend        => rx_abortend,      
    iacaftersifs       => iacaftersifs,
    -------------------------------------- 
    -- Diag
    -------------------------------------- 
    gene_sm_diag       => gene_sm_diag
    );



--------------------------------------------------------------------------------
-- TX state machine
--------------------------------------------------------------------------------

  bup2_tx_sm_1 : bup2_tx_sm
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn             => hresetn,
    hclk                => hclk,
    --------------------------------------
    -- BuP Registers
    -------------------------------------- 
    tximmstop           => tximmstop,
    enable_1mhz         => enable_1mhz,
    buptxptr            => buptxptr,
    iacptr              => iacptr,

    txend_stat          => txend_stat,
    queue_it_num        => queue_it_num,
    sampled_queue_it_num=> sampled_queue,
    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    testenable          => testenable,
    bup_testmode        => bup_testmode,
    datatype            => datatype,
    fcsdisb             => fcsdisb,
    testdata            => testdata,
    --------------------------------------
    -- Memory Sequencer
    -------------------------------------- 
    mem_seq_ready       => mem_seq_ready,
    mem_seq_data        => mem_seq_data, 
    --                     
    mem_seq_req         => mem_seq_req,
    mem_seq_txptr       => mem_seq_txptr,
    last_word           => last_word_tx,
    load_txptr          => load_txptr, 
    tx_acc_type         => tx_acc_type,
    --------------------------------------
    -- FCS generator
    -------------------------------------- 
    fcs_data_1st        => fcs_data_1st,      
    fcs_data_2nd        => fcs_data_2nd,      
    fcs_data_3rd        => fcs_data_3rd,      
    fcs_data_4th        => fcs_data_4th,      
    --                     
    fcs_init            => tx_fcs_init,      
    fcs_data_valid      => tx_fcs_data_valid,
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_data_conf       => phy_data_conf,   
    phy_txstartend_conf => phy_txstartend_conf,
    --                  
    phy_data_req        => phy_data_req,    
    phy_txstartend_req  => phy_txstartend_req, 
    bup_txdata          => bup_txdata,     
    txv_datarate        => txv_datarate,   
    txv_length          => txv_length,     
    txpwr_level         => txpwr_level,    
    txv_service         => txv_service,    
    txv_txaddcntl       => txv_txaddcntl,
    txv_paindex         => txv_paindex,
    txv_txant           => txv_txant,
    tximmstop_sm        => tximmstop_sm,
    ackto               => ackto,
    ackto_en            => ackto_en,
    --------------------------------------
    -- BuP general state machine
    -------------------------------------- 
    tx_mode             => tx_mode,       
    --                     
    tx_start_it         => txstart_it,
    tx_end_it           => tx_end,
    tx_packet_type      => tx_packet_type,
    --------------------------------------------
    -- Diag
    --------------------------------------------
    tx_sm_diag          => tx_sm_diag,
    tx_read_sm_diag     => tx_read_sm_diag

  );


--------------------------------------------------------------------------------
-- RX state machine
--------------------------------------------------------------------------------

  bup2_rx_sm_1 : bup2_rx_sm
    port map (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn            => hresetn,
    hclk               => hclk,
    --------------------------------------
    -- BuP Registers
    -------------------------------------- 
    buprxptr           => buprxptr,
    buprxoff           => buprxoff,
    buprxsize          => buprxsize,
    buprxunload        => buprxunload,
    reg_frmcntl        => reg_frmcntl,
    reg_durid          => reg_durid,
    reg_bupaddr1       => reg_bupaddr1,
    reg_addr1mskh      => reg_addr1mskh,
    reg_addr1mskl      => reg_addr1mskl,
    reg_rxlen          => reg_rxlen,
    reg_rxserv         => reg_rxserv,
    reg_rxrate         => reg_rxrate,
    reg_rxrssi         => reg_rxrssi,
    reg_rxccaaddinfo   => reg_rxccaaddinfo,
    reg_rxant          => reg_rxant,
    reg_a1match        => reg_a1match,
    reg_enrxabort      => reg_enrxabort,
    reg_rxabtcnt       => reg_rxabtcnt,
    
    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    fcsdisb            => fcsdisb,
    --------------------------------------
    -- Memory Sequencer
    -------------------------------------- 
    mem_seq_rx_mode    => mem_seq_rx_mode,
    mem_seq_ind        => mem_seq_ind,
    data_to_mem_seq    => data_to_mem_seq_o, 
    last_word          => last_word_rx, 
    mem_seq_rxptr      => mem_seq_rxptr,
    load_rxptr         => load_rxptr,
    ready_load         => ready_load,
    rx_acc_type        => rx_acc_type,
    --------------------------------------
    -- FCS generator
    -------------------------------------- 
    fcs_data_1st       => fcs_data_1st,      
    fcs_data_2nd       => fcs_data_2nd,      
    fcs_data_3rd       => fcs_data_3rd,      
    fcs_data_4th       => fcs_data_4th,      
    --                    
    fcs_init           => rx_fcs_init,      
    fcs_data_valid     => rx_fcs_data_valid,
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_data_ind       => phy_data_ind,   
    phy_rxstartend_ind => phy_rxstartend_ind,
    rxv_length         => rxv_length,
    rxe_errorstat      => rxe_errorstat,  
    bup_rxdata         => bup_rxdata,
    rxv_datarate       => rxv_datarate,   
    rxv_service        => rxv_service, 
    rxv_service_ind    => rxv_service_ind,   
    rxv_rssi           => rxv_rssi,    
    rxv_ccaaddinfo     => rxv_ccaaddinfo,    
    rxv_rxant          => rxv_rxant,    
    --------------------------------------
    -- BuP general state machine
    -------------------------------------- 
    rx_mode            => rx_mode,      
    --                    
    rx_end             => rx_end,
    rx_fullbuf         => rx_fullbuf,
    bufempty           => bufempty,
    rxend_stat         => rxend_stat_i,      
    rx_errstat         => rx_errstat,
    rx_fcs_err         => rx_fcs_err,   
    rx_err             => rx_err,
    rx_packet_type     => rx_packet_type,
    --------------------------------------------
    -- Diag
    --------------------------------------------
    rx_sm_diag         => rx_sm_diag
        
  );


--------------------------------------------------------------------------------
-- FCS controls
--------------------------------------------------------------------------------

  fcs_init  <= rx_fcs_init when rx_mode = '1' else
               tx_fcs_init;

  fcs_data_valid  <= rx_fcs_data_valid when rx_mode = '1' else
                     tx_fcs_data_valid;

  data_to_fcs  <= data_to_mem_seq_o when rx_mode = '1' else
                  mem_seq_data;


--------------------------------------------------------------------------------
-- Memory Sequencer controls
--------------------------------------------------------------------------------
  
  data_to_mem_seq     <= data_to_mem_seq_o;
  mem_seq_tx_mode     <= tx_mode;
  load_ptr            <= load_rxptr or load_txptr;
  last_word           <= last_word_tx when tx_mode = '1' else last_word_rx;
  acctype             <= tx_acc_type when tx_mode = '1' else rx_acc_type;
  
--------------------------------------
-- Interrupt Generator pulses
-------------------------------------- 

  -- for RX start use rx_fcs_init, 
  -- since this indicates we start receiving a packet
  rxstart_it  <= rx_fcs_init;  
  rxend_it    <= rx_end;   
  txend_it    <= tx_end;   

end RTL;
