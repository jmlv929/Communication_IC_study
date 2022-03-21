

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of modem2bup_sync is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal phy_txstartend_conf_ff1_resync : std_logic;
  signal phy_rxstartend_ind_ff1_resync  : std_logic;
  signal phy_data_conf_ff1_resync       : std_logic;
  signal phy_data_ind_ff1_resync        : std_logic;
  signal phy_cca_ind_ff1_resync         : std_logic;
  signal rxv_service_ind_ff1_resync     : std_logic;
  signal phy_ccarst_conf_ff1_resync     : std_logic;


--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Each input signal is synchronized twice with bup_clk.
  sync_p: process (reset_n, bup_clk)
  begin
    if reset_n = '0' then

      phy_txstartend_conf_ff1_resync  <= '0';
      phy_rxstartend_ind_ff1_resync   <= '0';
      phy_data_conf_ff1_resync        <= '0';
      phy_data_ind_ff1_resync         <= '0';
      phy_cca_ind_ff1_resync          <= '0';
      rxv_service_ind_ff1_resync      <= '0';
      phy_ccarst_conf_ff1_resync      <= '0';

      phy_txstartend_conf_ff2_resync  <= '0';
      phy_rxstartend_ind_ff2_resync   <= '0';
      phy_data_conf_ff2_resync        <= '0';
      phy_data_ind_ff2_resync         <= '0';
      phy_cca_ind_ff2_resync          <= '0';
      rxv_service_ind_ff2_resync      <= '0';
      phy_ccarst_conf_ff2_resync      <= '0';

    elsif bup_clk'event and bup_clk = '1' then

      phy_txstartend_conf_ff1_resync  <= phy_txstartend_conf;
      phy_rxstartend_ind_ff1_resync   <= phy_rxstartend_ind;
      phy_data_conf_ff1_resync        <= phy_data_conf;
      phy_data_ind_ff1_resync         <= phy_data_ind;
      phy_cca_ind_ff1_resync          <= phy_cca_ind;
      rxv_service_ind_ff1_resync      <= rxv_service_ind;
      phy_ccarst_conf_ff1_resync      <= phy_ccarst_conf;

      phy_txstartend_conf_ff2_resync  <= phy_txstartend_conf_ff1_resync;
      phy_rxstartend_ind_ff2_resync   <= phy_rxstartend_ind_ff1_resync;
      phy_data_conf_ff2_resync        <= phy_data_conf_ff1_resync;
      phy_data_ind_ff2_resync         <= phy_data_ind_ff1_resync;
      phy_cca_ind_ff2_resync          <= phy_cca_ind_ff1_resync;
      rxv_service_ind_ff2_resync      <= rxv_service_ind_ff1_resync;
      phy_ccarst_conf_ff2_resync      <= phy_ccarst_conf_ff1_resync;
      
    end if;
  end process sync_p;
  
end RTL;
