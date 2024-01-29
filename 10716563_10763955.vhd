-- COMPONENTS --

-- The 8-bit register_8bit records the last not '0' value of the sequence
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
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

-- The 11-bit counter (1 more bit than the i_k input signal)
-- counts the current memory address offset from i_add
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
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
    if i_rst = '1' then
      stored_value <= (others => '0');
    elsif i_clk'event and i_clk = '1' and i_count_enable = '1' then
      stored_value <= stored_value + 1;
    end if;
  end process;
end counter_arch;

-- The multiplexer switches between the two inputs for mem data between the
-- previous num register and the reverse counter for credibilty bit
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
entity multiplexer is
  port (
    i_select : in std_logic;

    i_data_A : in std_logic_vector(7 downto 0);
    i_data_B : in std_logic_vector(4 downto 0);

    o_data : out std_logic_vector(7 downto 0)
  );
end multiplexer;
architecture multiplexer_arch of multiplexer is
begin
  -- A is an input from register_8bit and B is an input from reverse_counter
  process (i_select, i_data_A, i_data_B)
  begin
    -- if the register is 0, then the credibility bit is also 0, no matter the value of the reverse counter
    if i_select = '1' and not (i_data_A = "00000000") then
      o_data <= "000" & i_data_B;
    else
      o_data <= i_data_A;
    end if;
  end process;

end multiplexer_arch;

-- The 5 bit reverse_counter for the credibility bit
-- gets resetted to 31, decrements by 1 if enabled
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
entity reverse_counter is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;

    i_count_enable : in std_logic;
    o_data : out std_logic_vector(4 downto 0)
  );
end reverse_counter;
architecture reverse_counter_arch of reverse_counter is
  signal stored_value : std_logic_vector(4 downto 0);
begin
  -- The output is the stored value
  o_data <= stored_value;

  process (i_clk, i_rst, stored_value, i_count_enable)
  begin
    if i_rst = '1' then
      stored_value <= (others => '1'); -- resets to 31
    elsif i_clk'event and i_clk = '1' then
      if i_count_enable = '1' and not (stored_value = "00000") then
        stored_value <= stored_value - 1;
      end if;
    end if;
  end process;
end reverse_counter_arch;

-- The state machine that controls the process
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
entity fsm is
  port (
    i_clk : in std_logic;
    i_rst : in std_logic;

    i_start : in std_logic; -- start value for the process
    i_k : in std_logic_vector(9 downto 0); -- the k words
    i_word_count : in std_logic_vector(9 downto 0); -- the current word count
    i_mem_data : in std_logic_vector(7 downto 0); -- the data from the memory

    o_mux_select : out std_logic; -- select for the multiplexer
    o_register_we : out std_logic; -- write enable for the register
    o_counter_increment : out std_logic; -- enable the increment of the counter
    o_rev_count_reset : out std_logic; -- flag used to reset the reverse counter
    o_rev_count_decrement : out std_logic; -- enable the decrement of the reverse counter
    o_mem_we : out std_logic; -- write enable for the memory
    o_done : out std_logic -- done flag
  );
end fsm;
architecture fsm_arch of fsm is
  type STATE is (INIT, MEM_READY, ZERO_VALUE, NON_ZERO_VALUE, SET_CREDIBILITY, READ_MEM, DONE);
  signal current_state : STATE;
begin

  process (i_clk, i_rst) -- state update process
  begin
    if i_rst = '1' then
      current_state <= INIT; -- INIT is the reset state
    elsif i_clk'event and i_clk = '1' then
      -- state update conditions
      case current_state is
        when INIT =>
          if i_start = '1' then
            current_state <= MEM_READY;
          end if;
        when MEM_READY =>
          if i_mem_data = "00000000" then
            current_state <= ZERO_VALUE;
          else
            current_state <= NON_ZERO_VALUE;
          end if;
        when ZERO_VALUE =>
          current_state <= SET_CREDIBILITY;
        when NON_ZERO_VALUE =>
          current_state <= SET_CREDIBILITY;
        when SET_CREDIBILITY =>
          if i_word_count = i_k then
            current_state <= DONE;
          else
            current_state <= READ_MEM;
          end if;
        when READ_MEM =>
          current_state <= MEM_READY;
        when DONE =>
          if i_start = '0' then
            current_state <= INIT;
          end if;
      end case;
    end if;
  end process;

  process (current_state) -- flag setting process
  begin
    o_mux_select <= '0';
    o_register_we <= '0';
    o_counter_increment <= '0';
    o_rev_count_reset <= '0';
    o_rev_count_decrement <= '0';
    o_mem_we <= '0';
    o_done <= '0';

    -- the INIT and MEM_READY states do not set any flags
    case current_state is
      when INIT =>
      when MEM_READY =>
      when ZERO_VALUE =>
        o_mux_select <= '0'; -- select the register, technically not needed but for clarity
        o_counter_increment <= '1'; -- go to the next mem address
        o_mem_we <= '1'; -- write the register value into the memory address
      when NON_ZERO_VALUE =>
        o_register_we <= '1'; -- save the value to the register
        o_counter_increment <= '1'; -- go to the next mem address
        o_rev_count_reset <= '1'; -- reset the reverse counter
      when SET_CREDIBILITY =>
        o_mux_select <= '1'; -- select the reverse counter
        o_counter_increment <= '1'; -- go to the next mem address
        o_mem_we <= '1'; -- write the reverse counter value into the memory address
      when READ_MEM =>
        o_rev_count_decrement <= '1'; -- decrement the reverse counter
      when DONE =>
        o_done <= '1'; -- done!
    end case;
  end process;

end fsm_arch;

-- END OF COMPONENTS --

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
entity project_reti_logiche is

  port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_add : in std_logic_vector(15 downto 0);
    i_k : in std_logic_vector(9 downto 0);

    o_done : out std_logic;

    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_data : out std_logic_vector(7 downto 0);
    o_mem_we : out std_logic;
    o_mem_en : out std_logic
  );

end project_reti_logiche;
architecture project_reti_logiche_arch of project_reti_logiche is
  -- signals to interconnect the components
  signal mux_select : std_logic; -- 0 for register, 1 for reverse counter (fsm -> multiplexer)
  signal register_out : std_logic_vector(7 downto 0); -- output of the register -> input A of the multiplexer
  signal rev_count_out : std_logic_vector(4 downto 0); -- output of the reverse counter -> input B of the multiplexer
  signal register_we : std_logic; -- write enable for the register (fsm -> register)
  signal rev_count_decrement : std_logic; -- enable the decrement of the reverse counter (fsm -> reverse_counter)
  signal rev_count_reset : std_logic; -- flag used to reset the reverse counter (fsm -> reverse_counter)
  signal counter_increment : std_logic; -- enable the increment of the counter (fsm -> counter)
  signal counter_out : std_logic_vector(10 downto 0); -- output of the counter (offset from i_add)

  signal component_reset : std_logic; -- reset signals for everything but the fsm, this is used to reset everything when i_start is low
  signal rev_count_component_reset : std_logic; -- actual reset signal for the reverse counter, both fsm and global reset are connected to this

begin
  -- connect all the components together
  reg : entity work.register_8bit port map(
    i_clk => i_clk,
    i_rst => component_reset,
    i_write_en => register_we,
    i_data => i_mem_data,
    o_data => register_out
    );
  count : entity work.counter port map(
    i_clk => i_clk,
    i_rst => component_reset,
    i_count_enable => counter_increment,
    o_data => counter_out
    );
  mux : entity work.multiplexer port map(
    i_select => mux_select,
    i_data_A => register_out,
    i_data_B => rev_count_out,
    o_data => o_mem_data
    );
  rev_count : entity work.reverse_counter port map(
    i_clk => i_clk,
    i_rst => rev_count_component_reset,
    i_count_enable => rev_count_decrement,
    o_data => rev_count_out
    );
  f : entity work.fsm port map(
    i_clk => i_clk,
    i_rst => i_rst, -- this resets only on global reset
    i_start => i_start,
    i_k => i_k,
    i_word_count => counter_out(10 downto 1), -- only the 10 MSBs are used, this is the number of words (one every two memory cells)
    i_mem_data => i_mem_data,
    o_mux_select => mux_select,
    o_register_we => register_we,
    o_counter_increment => counter_increment,
    o_rev_count_reset => rev_count_reset,
    o_rev_count_decrement => rev_count_decrement,
    o_mem_we => o_mem_we,
    o_done => o_done
    );
  component_reset <= i_rst or not i_start; -- all components except the fsm are resetted on global reset or when i_start is low, so that the process can be restarted
  rev_count_component_reset <= component_reset or rev_count_reset; -- the reverse counter can also be reset by a flag set by the fsm itself
  o_mem_en <= i_start; -- always enable the memory when the start signal is high
  o_mem_addr <= counter_out + i_add; -- the address is the current count + the offset

end project_reti_logiche_arch;