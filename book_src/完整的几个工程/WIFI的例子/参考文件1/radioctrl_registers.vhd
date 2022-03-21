
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: radioctrl_registers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.20   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : APB registers of the radio controller
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/radioctrl/vhdl/rtl/radioctrl_registers.vhd,v  
--  Log: radioctrl_registers.vhd,v  
-- Revision 1.20  2005/10/04 12:27:14  Dr.A
-- #BugId:1398#
-- Completed sensitivity list in registers and reqdata_handler.
-- Removed unused signals and rf_goto_sleep port
--
-- Revision 1.19  2005/04/11 16:19:57  sbizet
-- #BugId:183#
-- RCVERSION changed
--
-- Revision 1.18  2005/03/02 12:58:31  sbizet
-- #BugId:907#
-- Removed auto-acknowledgement of the SWRFOFFREQ
--
-- Revision 1.17  2005/01/06 17:12:46  sbizet
-- #BugId:907,643,947#
-- Added :
-- o agc_rfoff interrupt
-- o software radio off(register+interrupt)
-- o read access avoidance when maxresp=0
--
-- Revision 1.16  2004/12/14 16:45:25  sbizet
-- #BugId:907#
-- Added rfint, swrfoff and swrfoffreq for 1.2 function(not functionnal)
--
-- Revision 1.15  2004/06/04 13:52:23  Dr.C
-- Added a register on prdata.
--
-- Revision 1.14  2004/02/19 17:29:40  Dr.B
-- add b_antsel.
--
-- Revision 1.13  2004/01/06 18:05:45  Dr.B
-- update upgrade version.
--
-- Revision 1.12  2003/12/23 10:04:28  Dr.B
-- maxresp has the max value.
--
-- Revision 1.11  2003/12/22 18:47:46  Dr.B
-- update default values.
--
-- Revision 1.10  2003/12/22 13:55:11  Dr.B
-- hiss_curr default value is high.
--
-- Revision 1.9  2003/12/19 11:32:00  Dr.B
-- update process list.
--
-- Revision 1.8  2003/12/03 08:16:31  Dr.B
-- change default value of retry register.
--
-- Revision 1.7  2003/11/26 16:03:12  Dr.B
-- update release number.
--
-- Revision 1.6  2003/11/20 11:28:58  Dr.B
-- remove edgeselect.
--
-- Revision 1.5  2003/11/17 14:54:01  Dr.B
-- add conflict bit.
--
-- Revision 1.4  2003/10/30 14:42:37  Dr.B
-- update to spec 0.06.
--
-- Revision 1.3  2003/09/25 12:35:58  Dr.C
-- Corrected bit number error on RCRFCNTL
--
-- Revision 1.2  2003/09/23 13:09:19  Dr.C
-- Updated to spec 0.05
--
-- Revision 1.1  2003/07/15 08:40:46  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity radioctrl_registers is
  generic (
    ana_digital_g : integer := 0); -- Selects between analog and HISS interface
  port (
    -------------------------------------------
    -- Reset                         
    -------------------------------------------
    reset_n : in std_logic;

    -------------------------------------------
    -- APB interface                           
    -------------------------------------------
    psel_i      : in  std_logic;
    penable_i   : in  std_logic;
    paddr_i     : in  std_logic_vector(5 downto 0);
    pwrite_i    : in  std_logic;
    pclk        : in  std_logic;
    pwdata_i    : in  std_logic_vector(31 downto 0);
    prdata_o    : out std_logic_vector(31 downto 0);
    -------------------------------------------
    -- AGC interrupt
    -------------------------------------------
    agc_rfint_i         : in std_logic;  -- AGC RF Interrupt decoded by AGC BB
    -------------------------------------------
    -- Request handler                         
    -------------------------------------------
    accend_i            : in std_logic;  -- Software access end
    rddata_i            : in std_logic_vector(15 downto 0);  -- Read data
    parityerr_i         : in std_logic;  -- Parity error
    retried_parityerr_i : in std_logic;  -- Parity error
    agcerr_i            : in std_logic;  -- Parity err on AGC transmission
    proterr_i           : in std_logic;  -- Protocol error
    conflict_i          : in std_logic;  -- Conflict: Read Access before a RX
    readto_i            : in std_logic;  -- Read access time out
    clkswto_i           : in std_logic;  -- Clock switch time out
    clksw_i             : in std_logic;  -- Clock freq. has been switched
    rf_off_done_i       : in std_logic;  -- RF has been switched off

    startacc_o : out std_logic;                      -- Start reg access
    acctype_o  : out std_logic;                      -- Access type
    edgemode_o : out std_logic;                      -- Clock edge active
    radad_o    : out std_logic_vector(5 downto 0);   -- Register address
    wrdata_o   : out std_logic_vector(15 downto 0);  -- Write data
    retry_o    : out std_logic_vector(2 downto 0);   -- Number of trials

    -------------------------------------------
    -- Radio interface            
    -------------------------------------------
    maxresp_o      : out std_logic_vector(5 downto 0);  -- Number of cc to wait 
                                        -- to abort a read access
    txiqswap_o     : out std_logic;     -- Swap TX I/Q lines
    rxiqswap_o     : out std_logic;     -- Swap RX I/Q lines

    -------------------------------------------
    -- HiSS interface            
    -------------------------------------------
    forcehisspad_o : out std_logic;     -- Force HISS pad to be always on
    hiss_biasen_o  : out std_logic; -- enable HiSS drivers and receivers
    hiss_replien_o : out std_logic; -- enable HiSS drivers and receivers
    hiss_clken_o   : out std_logic; -- Enable HiSS clock receivers
    hiss_curr_o    : out std_logic; -- Select high-current mode for HiSS drivers
    
    -------------------------------------------
    -- Radio             
    -------------------------------------------
    b_antsel_i     : in  std_logic;  -- give info on the antenna selection for B
    --
    xoen_o         : out std_logic;       -- Enable RF crystal oscillator
    band_o         : out std_logic;       -- Select 5/2.4 GHz power ampl.
    txstartdel_o   : out std_logic_vector(7 downto 0);  -- Delay to wait bef send tx_onoff_conf
    paondel_o      : out std_logic_vector(7 downto 0);  -- Delay to switch on PA
    forcedacon_o   : out std_logic; -- when high, always enable dac
    forceadcon_o   : out std_logic; -- when high, always enable adc
    swcase_o       : out std_logic_vector(1 downto 0);  -- RF switches
    antforce_o     : out std_logic;       -- Forces antenna switch
--    useant_o       : out std_logic;       -- Selects antenna to use
    useant_o       : out std_logic;       -- Selects antenna to use
    sw_rfoff_req_o : out std_logic;       -- Pulse to request RF stop by software

    -------------------------------------------
    -- Misc                 
    -------------------------------------------
    interrupt_o : out std_logic         -- Interrupt
    
  );

end radioctrl_registers;
