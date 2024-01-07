library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;

-- The 11-bit counter (1 more bit than the i_k input signal)
-- counts the current memory address offset from i_add
entity counter is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;

    i_count_enable : in std_logic;
    o_data : out std_logic_vector(10 downto 0)
  );
end counter;
architecture counter_arch of counter is
  signal stored_value : std_logic_vector(10 downto 0);
begin
  -- The output is the stored value
  o_data <= stored_value;

  process (i_clk, i_rst)
  begin
    -- If reset, then... reset!
    if i_rst = '1' then
      stored_value <= (others => '0');
    elsif i_clk'event and i_clk = '1' and i_count_enable = '1' then
      stored_value <= stored_value + 1;
    end if;
  end process;
end counter_arch;