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
  component register_8bit is
    port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_write_en : in std_logic;
      i_data : in std_logic_vector(7 downto 0);
      o_data : out std_logic_vector(7 downto 0)
    );
  end component;
  component reverse_counter is
    port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_count_enable : in std_logic;
      o_data : out std_logic_vector(4 downto 0)
    );
  end component;
  component counter is
    port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_count_enable : in std_logic;
      o_data : out std_logic_vector(10 downto 0)
    );
  end component;
  component multiplexer is
    port (
      i_select : in std_logic;
      i_data_A : in std_logic_vector(7 downto 0);
      i_data_B : in std_logic_vector(4 downto 0);
      o_data : out std_logic_vector(7 downto 0)
    );
  end component;
  component fsm is
    port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_start : in std_logic; -- start value for the process
      i_k : in std_logic_vector(9 downto 0); -- the k words
      i_word_count : in std_logic_vector(9 downto 0); -- the current word count
      i_mem_data : in std_logic_vector(7 downto 0); -- the data from the memory
      o_mux_select : out std_logic;
      o_register_we : out std_logic;
      o_counter_increment : out std_logic;
      o_rev_count_reset : out std_logic;
      o_rev_count_decrement : out std_logic;
      o_mem_we : out std_logic;
      o_done : out std_logic
    );
  end component;

  signal mux_select : std_logic;
  signal register_out : std_logic_vector(7 downto 0);
  signal rev_count_out : std_logic_vector(4 downto 0);
  signal register_we : std_logic;
  signal rev_count_decrement : std_logic;
  signal rev_count_reset : std_logic;
  signal counter_increment : std_logic;
  signal counter_out : std_logic_vector(10 downto 0);

  signal component_reset : std_logic; -- reset signals for everything but the fsm
  signal rev_count_component_reset : std_logic; -- actual reset signal for the reverse counter, both fsm and global reset are connected to this

begin
  reg : register_8bit port map(
    i_clk => i_clk,
    i_rst => component_reset,
    i_write_en => register_we,
    i_data => i_mem_data,
    o_data => register_out
  );

  rev_count : reverse_counter port map(
    i_clk => i_clk,
    i_rst => rev_count_component_reset,
    i_count_enable => rev_count_decrement,
    o_data => rev_count_out
  );

  count : counter port map(
    i_clk => i_clk,
    i_rst => component_reset,
    i_count_enable => counter_increment,
    o_data => counter_out
  );

  mux : multiplexer port map(
    i_select => mux_select,
    i_data_A => register_out,
    i_data_B => rev_count_out,
    o_data => o_mem_data
  );

  f : fsm port map(
    i_clk => i_clk,
    i_rst => i_rst, -- this resets only on global reset
    i_start => i_start,
    i_k => i_k,
    i_word_count => counter_out(10 downto 1),
    i_mem_data => i_mem_data,
    o_mux_select => mux_select,
    o_register_we => register_we,
    o_counter_increment => counter_increment,
    o_rev_count_reset => rev_count_reset,
    o_rev_count_decrement => rev_count_decrement,
    o_mem_we => o_mem_we,
    o_done => o_done
  );

  component_reset <= i_rst or not i_start;
  rev_count_component_reset <= component_reset or rev_count_reset;
  o_mem_en <= i_start; -- always enable the memory when the start signal is high
  o_mem_addr <= counter_out + i_add; -- the address is the current count + the offset

end project_reti_logiche_arch;