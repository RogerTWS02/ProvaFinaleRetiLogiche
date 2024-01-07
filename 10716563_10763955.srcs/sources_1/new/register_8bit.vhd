library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- The 8-bit register_8bit records the last not '0' value of the sequence
entity register_8bit is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_write_en : in std_logic;

    i_data : in std_logic_vector(7 downto 0);
    o_data : out std_logic_vector(7 downto 0)
  );
end register_8bit;
architecture register_8bit_arch of register_8bit is
  signal stored_value : std_logic_vector(7 downto 0);
begin
  -- The output is always the stored value
  o_data <= stored_value;

  process (i_clk, i_rst)
  begin
    -- if reset, then reset
    if i_rst = '1' then
      stored_value <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      -- on rising edge of clock, if write enable, then store it in value
      if i_write_en = '1' then
        stored_value <= i_data;
      end if;
    end if;
  end process;
end register_8bit_arch;