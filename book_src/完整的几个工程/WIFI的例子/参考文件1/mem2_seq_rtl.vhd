

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture rtl of mem2_seq is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant NULL_CT : std_logic_vector(31 downto 0) := (others => '0');

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  --------------------------------------------
  -- Access buffers
  --------------------------------------------
  signal ahb_buffer     : std_logic_vector(31 downto 0);  -- Buffer on AHB side
  signal modem_buffer   : std_logic_vector(31 downto 0);  -- Buffer on modme side
  signal select_ptr     : std_logic_vector(1 downto 0);  -- Select byte to be
  signal select_ptr_ff1 : std_logic_vector(1 downto 0);  --   transmitted

  signal firstbuf           : std_logic;
  signal firstbuf_ff1       : std_logic;
  signal ahb_buffer_empty     : std_logic;  -- AHB buffer is empty
  signal ahb_buffer_empty_ff1 : std_logic;
  signal modem_buffer_empty     : std_logic;-- Modem buffer is empty
  signal modem_buffer_empty_ff1 : std_logic;
  signal request_pending    : std_logic;  -- State machine requested a data but
  signal request_pending_ff1: std_logic;  -- 
 
  --------------------------------------------
  -- Address generation
  --------------------------------------------
  signal offset         : std_logic_vector(2 downto 0);
  signal haddr_o        : std_logic_vector(31 downto 0);
  signal hsize_o        : std_logic_vector(2 downto 0);
  signal busreq_o       : std_logic;
  signal hburst_o       : std_logic_vector(2 downto 0);
  signal hwrite_int     : std_logic;        -- Stored value of hwrite
  
  --------------------------------------------
  -- Transfer
  --------------------------------------------
  signal start          : std_logic;        
  signal tx_ff1         : std_logic;  
  signal last_word_int  : std_logic;
  signal last_req       : std_logic;
  signal last_req_ff1   : std_logic;
  signal last_bytes_nb  : std_logic_vector(1 downto 0);
  signal oneword        : std_logic;           -- One word to be transmitted
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- Reset BUFEMPTY flag on write access to RX buffer.
  reset_bufempty <= busreq_o and rx;
  
  --------------------------------------------
  -- To ensure that the last write access has been 
  -- performed before a new load_ptr is received,
  -- a wait indication is sent.
  --------------------------------------------
  wait_before_load_p : process(hreset_n, hclk)
  begin
    if hreset_n = '0' then
      ready_load <= '0';   
    elsif hclk'event and hclk = '1' then
      if ((select_ptr = "00") and
         (last_req_ff1 = '1') and (free = '1') and
         (busreq_o = '0')) then
        ready_load <= '1';
      else
        ready_load <= '0';
      end if;
    end if;
  end process wait_before_load_p;
  

  ------------------------------------------------------------------------------
  -- Buffers
  -- There are two access buffers: one is linked to the modem, 
  -- the other to the AHB bus
  ------------------------------------------------------------------------------
  buffer_p : process(hreset_n, hclk)
  begin
    if hreset_n = '0' then
      ahb_buffer   <= (others => '0');
      modem_buffer <= (others => '0');
      busreq_o     <= '0';   
      firstbuf     <= '1';
      firstbuf_ff1 <= '1';
      last_req_ff1 <= '0';
      ahb_buffer_empty <= '1';
      modem_buffer_empty <= '1';
      request_pending    <= '0';
      request_pending_ff1 <= '0';
      oneword <= '0';
      ahb_buffer_empty_ff1 <= '0';
    elsif hclk'event and hclk = '1' then
      busreq_o         <= '0';  
      firstbuf_ff1     <= firstbuf;
      last_req_ff1     <= last_req;
      if start = '1' then
        request_pending_ff1 <=  '0';
      else
        request_pending_ff1 <= request_pending;
      end if;
      
      ahb_buffer_empty_ff1 <= ahb_buffer_empty;
      -- indicates this is the first time the buffer is filled
      if start = '1' then
        firstbuf     <= '1';
        if last_word = '1' then
          oneword <= '1';
        else
          oneword <= '0';          
        end if;        
      end if;
      
      -- update ahb buffer for transmission
      if start = '1' and tx = '1' then
        busreq_o <= '1';
        modem_buffer_empty <= '1';
        ahb_buffer_empty   <= '1';
        request_pending    <= '0';

      elsif valid_data  = '1' and tx = '1' then
        if firstbuf = '1' then
          -- for the first data transmission the two buffers are empty 
          modem_buffer <= hrdata;
          busreq_o     <= not oneword; --'1';
          firstbuf     <= '0';
          modem_buffer_empty <= '0';
        else
          -- fill the ahb buffer 
          ahb_buffer   <= hrdata;  
          ahb_buffer_empty <= '0';
        end if;
      elsif end_data = '1' and rx = '1' and firstbuf = '1' then
        firstbuf <= '0';
      end if;
      
      -- byte received, modem buffer updated
      if ind = '1' then
        case select_ptr is
          when "00" =>
            modem_buffer(7 downto 0)   <= data_rec;
          when "01" =>
            modem_buffer(15 downto 8)  <= data_rec;
          when "10" =>
            modem_buffer(23 downto 16) <= data_rec;
          when "11" =>
            modem_buffer(31 downto 24) <= data_rec;
          when others =>              
        end case; 

      end if;      

      -- modem_buffer is full or empty
      if ((ind = '1' and select_ptr = "00" and select_ptr_ff1 = "11" and
                                                          load_ptr = '0') or
          (last_req = '1' and last_req_ff1 = '0')) and 
           buprxptr /= NULL_CT then        
        -- Rx mode: the modem buffer is emptied in the ahb buffer in order
        -- to write the received data in the memory
        -- !!!!! A null pointer indicates that the system is not ready 
        -- to store the packet.
        ahb_buffer   <= modem_buffer;
        busreq_o     <= '1';
      elsif ((req = '1' and select_ptr = "11" and oneword = '0' ) or
        (firstbuf_ff1 = '1' and firstbuf = '0' 
             and select_ptr = "11" and load_ptr = '0' and tx = '1') or
        (ahb_buffer_empty = '0' and   ahb_buffer_empty_ff1 = '1'
         and modem_buffer_empty = '1') or
        (request_pending = '1' and ahb_buffer_empty = '0' and load_ptr = '0'
         and firstbuf = '0')) 
      then
        -- Tx mode: the modem buffer is empty and must be filled again
        if last_word_int = '1' then
          busreq_o <= '0';
        else
          busreq_o         <= free;                    
        end if;
        if ahb_buffer_empty = '1' then -- and last_word = '0'
          modem_buffer_empty <= '1';
        else
          modem_buffer_empty <= '0';
          ahb_buffer_empty   <= '1';
          modem_buffer     <= ahb_buffer;
   
        end if;
      end if;   
      
       if (modem_buffer_empty = '1' and req = '1') then
          request_pending    <= '1';
        elsif modem_buffer_empty = '0' then
          request_pending    <= '0'; 
       end if;  
    end if;  
  end process buffer_p;
  
  last_bytes_nb <= buprxptr(1 downto 0);
  
  --------------------------------------------
  -- last word and last bus request
  --------------------------------------------
  last_word_int_p: process(hreset_n,hclk)
  begin
    if hreset_n = '0' then      
      last_word_int <= '0';
      last_req      <= '0';
    elsif hclk'event and hclk = '1' then
      -- Indicates last word until end of reception
      if (load_ptr = '1') then
        last_word_int <= last_word;
      elsif last_word = '1' and (ind = '1' or tx = '1') then
        last_word_int <= '1';
      elsif (end_data = '1' and last_req = '1') or
            (tx = '0' and tx_ff1 = '1') then
        last_word_int <= '0';
      end if;
      
      -- Indicates last AHB bus request to store the last bytes
     if last_word_int = '1' and select_ptr = last_bytes_nb and rx = '1' and
         (busreq_o = '0' and free = '1') then
        last_req <= '1';
      elsif load_ptr = '1' then
        last_req <= '0';
      end if;
      
    end if;  
  end process last_word_int_p;
  

  ------------------------------------------------------------------------------
  -- Data to transmit to the modem
  ------------------------------------------------------------------------------
  trans_data_p: process(hreset_n, hclk)
  begin
    if hreset_n = '0' then
      trans_data <= (others => '0');
      ready      <= '0';
      modem_buffer_empty_ff1 <= '1';
    elsif hclk'event and hclk = '1' then
      modem_buffer_empty_ff1 <= modem_buffer_empty;
      if load_ptr = '1' or (modem_buffer_empty = '1' and req = '1') then
        ready <= '0';
      elsif modem_buffer_empty = '0' then
        ready <= '1';
      end if;
      if (req = '1' and firstbuf = '0') or 
       (tx = '1' and firstbuf = '0' and firstbuf_ff1 = '1') or
       (modem_buffer_empty = '0' and modem_buffer_empty_ff1 = '1' and request_pending = '1') then

        case select_ptr is
          when "00" =>
            trans_data <= modem_buffer(7 downto 0);
          when "01" =>
            trans_data <= modem_buffer(15 downto 8);
          when "10" =>
            trans_data <= modem_buffer(23 downto 16);
          when "11" =>
            trans_data <= modem_buffer(31 downto 24);
          when others =>    
        end case;
      end if;
    end if;
  end process trans_data_p;

  

  ------------------------------------------------------------------------------
  -- Select pointer
  -- It is used to select where the incomming byte should be stored or which byte
  -- should be transmitted
  ------------------------------------------------------------------------------
  select_ptr_p: process (hreset_n, hclk)
  begin
    if hreset_n = '0' then
      select_ptr     <= (others => '0');
      select_ptr_ff1 <= (others => '0');
    elsif hclk'event and hclk = '1' then
      if start = '1' then
        if rx = '1' then
          if ind = '1' then
            select_ptr     <= buprxptr(1 downto 0) + "01";
            select_ptr_ff1 <= buprxptr(1 downto 0);
          else
            select_ptr     <= buprxptr(1 downto 0);
            select_ptr_ff1 <= buprxptr(1 downto 0);            
          end if;
        else
          select_ptr     <= buptxptr(1 downto 0);
          select_ptr_ff1 <= buptxptr(1 downto 0);
        end if;
      elsif ind = '1' or (req = '1' and firstbuf = '0' and
                          modem_buffer_empty = '0') or 
       (tx = '1' and firstbuf = '0' and firstbuf_ff1 = '1')
         or (request_pending = '0' and request_pending_ff1 = '1')
      then
        select_ptr <= select_ptr + "01";
        select_ptr_ff1 <= select_ptr;
      end if;
    end if;  
  end process select_ptr_p;


  ------------------------------------------------------------------------------
  -- AHB address generation
  ------------------------------------------------------------------------------
  address_p: process(hreset_n,hclk)
  begin
    if hreset_n = '0' then
      haddr_o <= (others => '0');      
    elsif hclk'event and hclk = '1' then
      if start = '1' then
        if rx = '1' then
          haddr_o <= buprxptr;
        else
          -- for transmission, only read accesses are performed
          -- They are all word aligned
          haddr_o <= buptxptr(31 downto 2) & "00";
        end if;
      elsif decr_addr = '1' then
        haddr_o <= haddr_o - EXT(offset, haddr_o'length);
      elsif inc_addr = '1' or end_add = '1' then
        haddr_o <= haddr_o + EXT(offset, haddr_o'length);
      end if;            
    end if;  
  end process address_p;

  -- address offset determination
  -- Because the bup only performs 32bit access,
  -- address offset is always 4 bytes and hsize always WORD_CT
  offset   <= "100";
  hsize_o  <= WORD_CT;
  hburst_o <= SINGLE_CT;  
  
  ------------------------------------------------------------------------------
  -- AHB write data
  ------------------------------------------------------------------------------
  wrdata_p: process(hreset_n,hclk)
  begin
    if hreset_n = '0' then
      hwdata <= (others => '0');
    elsif hclk'event and hclk = '1' then
      if rx = '1' and busreq_o = '1'then
        hwdata <= ahb_buffer;               
      end if;
    end if;
  end process wrdata_p;
    

  ------------------------------------------------------------------------------
  -- New transaction
  ------------------------------------------------------------------------------
  start_p: process(hreset_n, hclk) 
  begin
    if hreset_n = '0' then
      tx_ff1   <= '0';
    elsif hclk'event and hclk = '1' then
      tx_ff1   <= tx;
    end if;    
  end process start_p;
  
  start <= load_ptr;
  
  ------------------------------------------------------------------------------
  -- AHB  bus control signals
  ------------------------------------------------------------------------------
  hwrite_p: process (hclk, hreset_n)
  begin  
    if hreset_n = '0' then              
      hwrite_int <= '0';
    elsif hclk'event and hclk = '1' then
      if busreq_o = '1' then
        hwrite_int <= rx;
      end if;      
    end if;
  end process hwrite_p;

  hlock        <= '0';
  hprot        <= "1011";
  hwrite       <= rx when busreq_o = '1' else hwrite_int; 
  haddr        <= haddr_o;
  busreq       <= busreq_o;
  hsize        <= hsize_o;
  hburst       <= hburst_o;
  unspeclength <= '0';
  
end rtl;
