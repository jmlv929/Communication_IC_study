

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of endianness_converter is

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- This process swaps data bytes and half-wodrs when required for endianness
  -- conversion.
  converter_pr: process(acctype, wdata_i, rdata_i)
  begin
    case acctype is

      when BYTE_CT => -- Swap bytes.
        rdata_o(31 downto 24) <= rdata_i( 7 downto  0);
        rdata_o(23 downto 16) <= rdata_i(15 downto  8);
        rdata_o(15 downto  8) <= rdata_i(23 downto 16);
        rdata_o( 7 downto  0) <= rdata_i(31 downto 24);
        
        wdata_o(31 downto 24) <= wdata_i( 7 downto  0);
        wdata_o(23 downto 16) <= wdata_i(15 downto  8);
        wdata_o(15 downto  8) <= wdata_i(23 downto 16);
        wdata_o( 7 downto  0) <= wdata_i(31 downto 24);
      
      when HWORD_CT => -- Swap half words.
        rdata_o(31 downto 16) <= rdata_i(15 downto  0);
        rdata_o(15 downto  0) <= rdata_i(31 downto 16);

        wdata_o(31 downto 16) <= wdata_i(15 downto  0);
        wdata_o(15 downto  0) <= wdata_i(31 downto 16);
        
      when others => -- Word access, no changes needed.
        rdata_o <= rdata_i;
        wdata_o <= wdata_i;
        
    end case;
  end process converter_pr;
  

end RTL;
