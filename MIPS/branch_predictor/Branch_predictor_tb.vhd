library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Branch_predictor is
end tb_Branch_predictor;

architecture test of tb_Branch_predictor is
    -- Component declaration
    component Branch_predictor
        generic (
            SIZE : integer := 32
        );
        port (
            branch_ex   : in std_logic; 
            clock       : in std_logic;
            reset       : in std_logic; 
            pc_if       : in std_logic_vector(31 downto 0);
            pc_ex       : in std_logic_vector(31 downto 0);
            pc_cal      : in std_logic_vector(31 downto 0);
            pc_predict  : out std_logic_vector(31 downto 0);
            predict_if  : out std_logic;
            br_test     : out std_logic_vector(31 downto 0);
            tag_memory_table_test : out std_logic_vector(19 downto 0);
            valid_index_test : out std_logic
        );
    end component;

    -- Signals for connecting to the branch predictor
    signal branch_ex   : std_logic := '0';
    signal clock       : std_logic := '0';
    signal reset       : std_logic := '0';
    signal pc_if       : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_ex       : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_cal      : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_predict  : std_logic_vector(31 downto 0);
    signal predict_if  : std_logic;
    signal br_test     : std_logic_vector(31 downto 0);
    signal tag_memory_table_test : std_logic_vector(19 downto 0);
    signal valid_index_test : std_logic;
    
    -- Clock period definition
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the branch predictor
    uut: Branch_predictor
        port map (
            branch_ex   => branch_ex,
            clock       => clock,
            reset       => reset,
            pc_if       => pc_if,
            pc_ex       => pc_ex,
            pc_cal      => pc_cal,
            pc_predict  => pc_predict,
            predict_if  => predict_if,
            br_test     => br_test,
            tag_memory_table_test => tag_memory_table_test,
            valid_index_test => valid_index_test
        );

    -- Clock generation
    clock_process : process
    begin
        clock <= '0';
        wait for clk_period / 2;
        clock <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process to apply test cases
    stimulus: process
    begin
        -- Reset the predictor
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period * 2;  -- Pausa extra para estabilidade

        --  Test case 1: No branch taken initially
        -- ========================================
        pc_if <= x"00000000";
        pc_ex <= x"00000000";
        pc_cal <= x"00000010";  -- Next address if branch is taken (16 bytes ahead)
        branch_ex <= '0';        -- Branch not taken
        wait for clk_period * 2;

        report "Test case 1: No branch taken at pc_if = 0x00000000. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected no branch taken (predict_if = '0')." severity error;

        -- Test case 2
        -- ========================================
        pc_if <= x"00000000";
        pc_ex <= x"00000000";
        pc_cal <= x"00000020";  
        branch_ex <= '1';        -- Branch taken, store new address
        wait for clk_period * 2;

        report "Test case 2: Branch taken at pc_cal = 0x00000020. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected branch taken (predict_if = '0')." severity error;

        -- Test case 3
        -- ========================================
        pc_if <= x"00000000";
        pc_ex <= x"00000000";
        pc_cal <= x"00000030";  
        branch_ex <= '1';        -- Branch taken, store new address 10
        wait for clk_period * 2;

        report "Test case 3: No branch prediction at pc_if = 0x00000000. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected no branch taken (predict_if = '0')." severity error;

        -- Test case 4: Branch taken at a new address
        -- ========================================
        pc_if <= x"00000000";
        pc_ex <= x"00000000";
        pc_cal <= x"00000040";  
        branch_ex <= '1';
        wait for clk_period * 2;

        report "Test case 4: Branch taken at pc_ex = 0x00000000, pc_cal = 0x00000040. Expected predict_if = '1'" severity note;
        assert predict_if = '1' report "Error: Expected branch taken at new address (predict_if = '1')." severity error;

        wait;
    end process;
end test;
