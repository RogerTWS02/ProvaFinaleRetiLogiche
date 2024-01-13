-- TESTBENCH
-- TESTING ALL THESE SEQUENCES IN ONE SINGLE SCENARIO:
-- TB 1: RAM address overflow,
-- TB 2: 32 '0' values,
-- TB 3: start with '0' value,
-- TB 4: reset signal between sequences.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity project_tb is
end project_tb;

architecture project_tb_arch of project_tb is
  constant CLOCK_PERIOD : time := 20 ns;
  signal tb_clk : std_logic := '0';
  signal tb_rst, tb_start, tb_done : std_logic;
  signal tb_add : std_logic_vector(15 downto 0);
  signal tb_k : std_logic_vector(9 downto 0);

  signal tb_o_mem_addr, exc_o_mem_addr, init_o_mem_addr : std_logic_vector(15 downto 0);
  signal tb_o_mem_data, exc_o_mem_data, init_o_mem_data : std_logic_vector(7 downto 0);
  signal tb_i_mem_data : std_logic_vector(7 downto 0);
  signal tb_o_mem_we, tb_o_mem_en, exc_o_mem_we, exc_o_mem_en, init_o_mem_we, init_o_mem_en : std_logic;

  type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
  signal RAM : ram_type := (others => "00000000");

  --=== MULTIPLE SEQUENCES DEFINITIONS ===--

  -- Sequence 1 tests for credibility byte after more than 32 '0' values
  constant SEQUENCE_1_LENGTH : integer := 34;
  type sequence_1_type is array (0 to SEQUENCE_1_LENGTH * 2 - 1) of integer;
  constant SEQUENCE_1_ADDRESS : integer := 1000;
  signal sequence_1_input : sequence_1_type := (90, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  signal sequence_1_full : sequence_1_type := (90, 31, 90, 30, 90, 29, 90, 28, 90, 27, 90, 26, 90, 25, 90, 24, 90, 23, 90, 22, 90, 21, 90, 20, 90, 19, 90, 18, 90, 17, 90, 16, 90, 15, 90, 14, 90, 13, 90, 12, 90, 11, 90, 10, 90, 9, 90, 8, 90, 7, 90, 6, 90, 5, 90, 4, 90, 3, 90, 2, 90, 1, 90, 0, 90, 0, 90, 0);

  -- Sequence 2 tests for starting 0 value behavior
  constant SEQUENCE_2_LENGTH : integer := 6;
  type sequence_2_type is array (0 to SEQUENCE_2_LENGTH * 2 - 1) of integer;
  constant SEQUENCE_2_ADDRESS : integer := 2000;
  signal sequence_2_input : sequence_2_type := (0, 0, 90, 0, 64, 0, 0, 0, 56, 0, 12, 0);
  signal sequence_2_full : sequence_2_type := (0, 0, 90, 31, 64, 31, 64, 30, 56, 31, 12, 31);

  -- Sequence 3 tests for RAM address overflow
  constant SEQUENCE_3_LENGTH : integer := 10;
  type sequence_3_type is array (0 to SEQUENCE_3_LENGTH * 2 - 1) of integer;
  constant SEQUENCE_3_ADDRESS : integer := 65530;
  signal sequence_3_input : sequence_3_type := (45, 0, 56, 0, 0, 0, 0, 0, 0, 0, 12, 0, 128, 0, 128, 0, 31, 0, 0, 0);
  signal sequence_3_full : sequence_3_type := (45, 31, 56, 31, 56, 30, 56, 29, 56, 28, 12, 31, 128, 31, 128, 31, 31, 31, 31, 30);

  --== END OF MULTIPLE SEQUENCES DEFINITIONS ==--

  signal memory_control : std_logic := '0';

  component project_reti_logiche is
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
  end component project_reti_logiche;

begin
  UUT : project_reti_logiche
  port map(
    i_clk => tb_clk,
    i_rst => tb_rst,
    i_start => tb_start,
    i_add => tb_add,
    i_k => tb_k,

    o_done => tb_done,

    o_mem_addr => exc_o_mem_addr,
    i_mem_data => tb_i_mem_data,
    o_mem_data => exc_o_mem_data,
    o_mem_we => exc_o_mem_we,
    o_mem_en => exc_o_mem_en
  );

  -- Clock generation
  tb_clk <= not tb_clk after CLOCK_PERIOD/2;

  -- Process related to the memory
  MEM : process (tb_clk)
  begin
    if tb_clk'event and tb_clk = '1' then
      if tb_o_mem_en = '1' then
        if tb_o_mem_we = '1' then
          RAM(to_integer(unsigned(tb_o_mem_addr))) <= tb_o_mem_data after 1 ns;
          tb_i_mem_data <= tb_o_mem_data after 1 ns;
        else
          tb_i_mem_data <= RAM(to_integer(unsigned(tb_o_mem_addr))) after 1 ns;
        end if;
      end if;
    end if;
  end process;

  memory_signal_swapper : process (memory_control, init_o_mem_addr, init_o_mem_data,
    init_o_mem_en, init_o_mem_we, exc_o_mem_addr,
    exc_o_mem_data, exc_o_mem_en, exc_o_mem_we)
  begin
    -- This is necessary for the testbench to work: we swap the memory
    -- signals from the component to the testbench when needed.

    tb_o_mem_addr <= init_o_mem_addr;
    tb_o_mem_data <= init_o_mem_data;
    tb_o_mem_en <= init_o_mem_en;
    tb_o_mem_we <= init_o_mem_we;

    if memory_control = '1' then
      tb_o_mem_addr <= exc_o_mem_addr;
      tb_o_mem_data <= exc_o_mem_data;
      tb_o_mem_en <= exc_o_mem_en;
      tb_o_mem_we <= exc_o_mem_we;
    end if;
  end process;

  -- This process provides the correct scenario on the signal controlled by the TB
  create_scenario : process
    variable ram_value : std_logic_vector(7 downto 0);
    variable expected_value : integer;
  begin
    wait for 50 ns;

    report "TEST STARTED";

    -- Signal initialization and reset of the component
    tb_start <= '0';
    tb_add <= (others => '0');
    tb_k <= (others => '0');
    tb_rst <= '1';

    -- Wait some time for the component to reset...
    wait for 50 ns;

    tb_rst <= '0';
    memory_control <= '0'; -- Memory controlled by the testbench

    wait until falling_edge(tb_clk); -- Skew the testbench transitions with respect to the clock

    -- Configure the memory
    init_o_mem_en <= '1';
    init_o_mem_we <= '1';

    --== LOOPS FOR ALL THE SEQUENCES INIT ==--

    for i in 0 to SEQUENCE_1_LENGTH * 2 - 1 loop
      init_o_mem_addr <= std_logic_vector(to_unsigned(SEQUENCE_1_ADDRESS + i, 16));
      init_o_mem_data <= std_logic_vector(to_unsigned(sequence_1_input(i), 8));
      wait until rising_edge(tb_clk);
    end loop;

    for i in 0 to SEQUENCE_2_LENGTH * 2 - 1 loop
      init_o_mem_addr <= std_logic_vector(to_unsigned(SEQUENCE_2_ADDRESS + i, 16));
      init_o_mem_data <= std_logic_vector(to_unsigned(sequence_2_input(i), 8));
      wait until rising_edge(tb_clk);
    end loop;

    for i in 0 to SEQUENCE_3_LENGTH * 2 - 1 loop
      init_o_mem_addr <= std_logic_vector(to_unsigned(SEQUENCE_3_ADDRESS + i, 16));
      init_o_mem_data <= std_logic_vector(to_unsigned(sequence_3_input(i), 8));
      wait until rising_edge(tb_clk);
    end loop;

    --== END OF LOOPS FOR ALL THE SEQUENCES INIT ==--

    wait until falling_edge(tb_clk);

    memory_control <= '1'; -- Memory controlled by the component

    --== SIMULATION FOR ALL SEQUENCES ==--

    report "FIRST SEQUENCE STARTED";
    tb_add <= std_logic_vector(to_unsigned(SEQUENCE_1_ADDRESS, 16));
    tb_k <= std_logic_vector(to_unsigned(SEQUENCE_1_LENGTH, 10));
    tb_start <= '1';
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;
    report "FIRST SEQUENCE ENDED";
    wait for 5 ns;
    tb_start <= '0';
    wait for 50 ns;
    wait until falling_edge(tb_clk);

    report "SECOND SEQUENCE STARTED";
    tb_add <= std_logic_vector(to_unsigned(SEQUENCE_2_ADDRESS, 16));
    tb_k <= std_logic_vector(to_unsigned(SEQUENCE_2_LENGTH, 10));
    tb_start <= '1';
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;
    report "SECOND SEQUENCE ENDED";
    wait for 5 ns;
    tb_start <= '0';
    wait for 50 ns;
    wait until falling_edge(tb_clk);

    report "THIRD SEQUENCE STARTED";
    tb_add <= std_logic_vector(to_unsigned(SEQUENCE_3_ADDRESS, 16));
    tb_k <= std_logic_vector(to_unsigned(SEQUENCE_3_LENGTH, 10));
    tb_start <= '1';
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;
    report "THIRD SEQUENCE ENDED";
    wait for 5 ns;
    tb_start <= '0';

    --== END OF SIMULATION FOR ALL SEQUENCES ==--

    wait;

  end process;

  -- Process without sensitivity list designed to test the actual component.
  test_routine : process
    variable ram_value : std_logic_vector(7 downto 0);
    variable expected_value : integer;
  begin

    wait until tb_rst = '1';
    wait for 50 ns;
    assert tb_done = '0' report "TEST FALLITO o_done !=0 during reset" severity failure;
    wait until tb_rst = '0';

    wait until falling_edge(tb_clk);
    assert tb_done = '0' report "TEST FALLITO o_done !=0 after reset before start" severity failure;

    wait until rising_edge(tb_start);

    --== CHECKING THE MEMORY FOR ALL SEQUENCES ==--
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;

    assert tb_o_mem_en = '0' or tb_o_mem_we = '0' report "TEST 1 FALLITO o_mem_en !=0 memory should not be written after done." severity failure;

    for i in 0 to SEQUENCE_1_LENGTH * 2 - 1 loop
      ram_value := RAM((SEQUENCE_1_ADDRESS + i) mod 65536);
      expected_value := sequence_1_full(i);
      assert ram_value = std_logic_vector(to_unsigned(expected_value, 8)) report "TEST 1 FALLITO @ OFFSET=" & integer'image(i) & " expected= " & integer'image(expected_value) & " actual=" & integer'image(to_integer(unsigned(ram_value))) severity failure;
      -- assert RAM((SEQUENCE_1_ADDRESS + i) mod 65536) = std_logic_vector(to_unsigned(sequence_1_full(i), 8)) report "TEST FALLITO @ OFFSET=" & integer'image(i) & " expected= " & integer'image(scenario_full(i)) & " actual=" & integer'image(to_integer(unsigned(RAM((SCENARIO_ADDRESS + i) mod 65536)))) severity failure;
    end loop;

    wait for 50 ns;
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;

    for i in 0 to SEQUENCE_2_LENGTH * 2 - 1 loop
      ram_value := RAM((SEQUENCE_2_ADDRESS + i) mod 65536);
      expected_value := sequence_2_full(i);
      assert ram_value = std_logic_vector(to_unsigned(expected_value, 8)) report "TEST 2 FALLITO @ OFFSET=" & integer'image(i) & " expected= " & integer'image(expected_value) & " actual=" & integer'image(to_integer(unsigned(ram_value))) severity failure;
    end loop;

    wait for 50 ns;
    while tb_done /= '1' loop
      wait until rising_edge(tb_clk);
    end loop;

    for i in 0 to SEQUENCE_3_LENGTH * 2 - 1 loop
      ram_value := RAM((SEQUENCE_3_ADDRESS + i) mod 65536);
      expected_value := sequence_3_full(i);
      assert ram_value = std_logic_vector(to_unsigned(expected_value, 8)) report "TEST 3 FALLITO @ OFFSET=" & integer'image(i) & " expected= " & integer'image(expected_value) & " actual=" & integer'image(to_integer(unsigned(ram_value))) severity failure;
    end loop;

    --== END OF CHECKING THE MEMORY FOR ALL SEQUENCES ==--

    wait until falling_edge(tb_start);
    assert tb_done = '1' report "TEST FALLITO o_done !=0 after reset before start" severity failure;
    wait until falling_edge(tb_done);

    assert false report "Simulation Ended! TEST PASSATO (EXAMPLE)" severity failure;
  end process;

end architecture;