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
            predict_if  : out std_logic
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
            predict_if  => predict_if
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

        -- Test case 1: No branch taken initially
        pc_if <= x"00000000";
        pc_ex <= x"00000000";
        pc_cal <= x"00000010";  -- Next address if branch is taken (16 bytes ahead)
        branch_ex <= '0';        -- Branch not taken
        wait for clk_period * 2;

        -- Print and Check if the predictor is not predicting a branch (predict_if should be '0')
        report "Test case 1: No branch taken at pc_if = 0x00000000. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected no branch taken (predict_if = '0')." severity error;

        -- Test case 2: Branch taken at pc_ex = 0x00000000
        pc_ex <= x"00000000";
        pc_cal <= x"00000020";  -- Branch target address (32 bytes ahead)
        branch_ex <= '1';        -- Branch taken
        wait for clk_period * 2;

        -- Print and Test if prediction is updated to branch taken
        report "Test case 2: Branch taken at pc_ex = 0x00000000, pc_cal = 0x00000020. Expected predict_if = '1'" severity note;
        assert predict_if = '1' report "Error: Expected branch taken (predict_if = '1')." severity error;

        -- Test case 3: Mismatch in tags (branch not predicted)
        pc_if <= x"00000030";  -- Jump to another address (48 bytes ahead)
        wait for clk_period * 2;

        -- Print and Check if predictor does not take branch (predict_if should be '0')
        report "Test case 3: No branch prediction at pc_if = 0x00000030. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected no branch taken (predict_if = '0')." severity error;

        -- Test case 4: Branch taken at a new address
        pc_ex <= x"00000030";
        pc_cal <= x"00000040";  -- New branch target (64 bytes ahead)
        branch_ex <= '1';
        wait for clk_period * 2;

        -- Print and Test if predictor now predicts branch for pc_if = 0x00000030
        pc_if <= x"00000030";
        wait for clk_period * 2;

        -- Verify branch is predicted taken
        report "Test case 4: Branch taken at pc_ex = 0x00000030, pc_cal = 0x00000040. Expected predict_if = '1'" severity note;
        assert predict_if = '1' report "Error: Expected branch taken at new address (predict_if = '1')." severity error;

        -- Test case 5: Revisit previous branch (testing persistence)
        pc_if <= x"00000000";   -- Retest initial address (reset point)
        wait for clk_period * 2;

        -- Print and Check if the predictor correctly remembers the branch prediction
        report "Test case 5: Revisiting pc_if = 0x00000000. Expected predict_if = '1' (previous branch taken)" severity note;
        assert predict_if = '1' report "Error: Expected branch taken (predict_if = '1') for revisited address." severity error;

        -- Test case 6: Predict not taken after several not taken branches
        pc_ex <= x"00000050";
        pc_cal <= x"00000060";  -- New address for testing no branch taken (80 bytes ahead)
        branch_ex <= '0';       -- Branch not taken
        wait for clk_period * 2;

        -- Print and Verify prediction remains not taken
        pc_if <= x"00000050";
        wait for clk_period * 2;

        report "Test case 6: No branch prediction at pc_if = 0x00000050. Expected predict_if = '0'" severity note;
        assert predict_if = '0' report "Error: Expected no branch taken (predict_if = '0') after branch not taken." severity error;

        -- End of test with extended observations in waveform
        wait;
    end process;
end test;
