

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of bup2modem_sync is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal phy_txstartend_req_ff1_resync   : std_logic;
  signal phy_data_req_ff1_resync         : std_logic;
  signal phy_ccarst_req_ff1_resync       : std_logic;
  signal rxv_macaddr_match_ff1_resync    : std_logic;
  signal txv_immstop_ff1_resync          : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Each input signal is synchronized twice with modem_clk.
  sync_p: process (reset_n, modem_clk)
  begin
    if reset_n = '0' then
      phy_txstartend_req_ff1_resync <= '0';
      phy_data_req_ff1_resync       <= '0';
      phy_ccarst_req_ff1_resync     <= '0';
      rxv_macaddr_match_ff1_resync  <= '1';
      txv_immstop_ff1_resync        <= '0';
      
      phy_txstartend_req_ff2_resync <= '0';
      phy_data_req_ff2_resync       <= '0';
      phy_ccarst_req_ff2_resync     <= '0';
      rxv_macaddr_match_ff2_resync  <= '1';
      txv_immstop_ff2_resync        <= '0';
      
    elsif modem_clk'event and modem_clk = '1' then
      phy_txstartend_req_ff1_resync <= phy_txstartend_req;
      phy_data_req_ff1_resync       <= phy_data_req;
      phy_ccarst_req_ff1_resync     <= phy_ccarst_req;
      rxv_macaddr_match_ff1_resync  <= rxv_macaddr_match;
      txv_immstop_ff1_resync        <= txv_immstop;

      phy_txstartend_req_ff2_resync <= phy_txstartend_req_ff1_resync;
      phy_data_req_ff2_resync       <= phy_data_req_ff1_resync;
      phy_ccarst_req_ff2_resync     <= phy_ccarst_req_ff1_resync;
      rxv_macaddr_match_ff2_resync  <= rxv_macaddr_match_ff1_resync;
      txv_immstop_ff2_resync        <= txv_immstop_ff1_resync;
      
    end if;
  end process sync_p;

end RTL;
