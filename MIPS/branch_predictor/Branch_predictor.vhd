library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Branch_predictor is
    generic (
        SIZE      : integer := 32       -- Size of the branch history table (Index of the PC)
    );
    port (
        clock           : in std_logic;
        reset           : in std_logic; 
        branch_id       : in std_logic;                      -- Branch in execution 
        incrementedPC_IF           : in std_logic_vector(31 downto 0);  -- PC of the branch instruction in fetch
        incrementedPC_ID           : in std_logic_vector(31 downto 0);  -- PC of the branch instruction in execution
        branchTarget          : in std_logic_vector(31 downto 0);  -- PC of the branch instruction calculated
        branch_decision_ID : in std_logic;                      -- Branch decision (taken or not taken)
        predicted_IF    : out std_logic;                     -- Prediction status (taken or not taken)
        pc_predicted_IF : out std_logic_vector(31 downto 0); -- Predicted PC
        bubble_branch_ID: out std_logic;                     -- Bubble the branch in ID stage
        jump_ID         : in std_logic;                      -- Jump instruction in ID stage
        jumpTarget_ID   : in std_logic_vector(31 downto 0);  -- Jump target in ID stage
        branch_EX       : in std_logic;                      -- Branch in execution
        incrementedPC_EX          : in std_logic_vector(31 downto 0);  -- PC of the branch instruction in execution
        branchTarget_EX : in std_logic_vector(31 downto 0);  -- PC of the branch instruction calculated

        -- Testbench signals
        br_test         : out std_logic_vector(31 downto 0);
        predict_branch_test : out std_logic_vector(1 downto 0);
        tag_memory_table_test : out std_logic_vector(19 downto 0);
        valid_index_test : out std_logic;
        branch_bit : out std_logic_vector(1 downto 0);
        branch_index : out std_logic_vector(12 downto 2);
        branch_decision_test : out std_logic_vector(1 downto 0)
    );
end Branch_predictor;

architecture behavioral of Branch_predictor is

    -- Type declarations
    type pc_br is array(0 to SIZE-1) of std_logic_vector(31 downto 0);
    type prediction is array(0 to SIZE-1) of std_logic_vector(1 downto 0);
    type tag is array(0 to SIZE-1) of std_logic_vector(19 downto 0);
    type valid is array(0 to SIZE-1) of std_logic;

    -- Signal declarations
    signal br : pc_br;
    signal predict_branch : prediction;
    signal tag_memory_table : tag;
    signal valid_index : valid;
    
    -- Instruction fetch
    alias tag_pc_if is incrementedPC_IF(31 downto 12);
    alias index_if  is incrementedPC_IF(12 downto 2);

    -- Instruction execution
    alias tag_pc_id is incrementedPC_ID(31 downto 12);
    alias index_id  is incrementedPC_ID(12 downto 2);

    -- Instruction execution stage
    alias tag_pc_EX is incrementedPC_EX(31 downto 12);
    alias index_EX  is incrementedPC_EX(12 downto 2);

    -- Prediction FSM
    signal new_predict_branch: std_logic_vector(1 downto 0); 
    signal taken : std_logic;

    signal wrong_predict : std_logic_vector(1 downto 0);

begin            
    -- Process to write the history table when a branch
    process(clock, reset, new_predict_branch)
    begin
        if reset = '1' then
            for i in 0 to SIZE-1 loop
                tag_memory_table(i) <= (others => '0');
                br(i) <= (others => '0');
                predict_branch(i) <= (others => '0');    -- Set all the predictions to not taken
                valid_index(i) <= '0';
            end loop;

        elsif rising_edge(clock) then
            if branch_EX = '1' then 
                br(to_integer(unsigned(index_EX))) <= branchTarget_EX;
                tag_memory_table(to_integer(unsigned(index_EX))) <= tag_pc_EX;
                predict_branch(to_integer(unsigned(index_EX))) <= new_predict_branch;
                valid_index(to_integer(unsigned(index_EX))) <= '1';
            end if;
        end if;
    end process;

    -- Process to update prediction FSM
    process(clock, reset)
    begin
        if reset = '1' then
            new_predict_branch <= "00";  -- Strongly not taken
        elsif rising_edge(clock) then
            -- Branch prediction must be updated only if branch is in execution and has the same tag
            if tag_memory_table(to_integer(unsigned(index_id))) = tag_pc_id and branch_id = '1' then  -- Correspondence and update of dynamic branch prediction
                if branch_decision_ID = '1' then
                    case predict_branch(to_integer(unsigned(index_id))) is
                        when "11" =>
                            new_predict_branch <= "11";  -- Strongly taken
                        when "10" =>
                            new_predict_branch <= "11";  -- Taken
                        when "01" =>
                            new_predict_branch <= "10";  -- Weakly taken
                        when others =>
                            new_predict_branch <= "01";  -- Weakly not taken
                    end case;
                else
                    case predict_branch(to_integer(unsigned(index_id))) is
                        when "11" =>
                            new_predict_branch <= "10";  -- Weakly taken
                        when "10" =>
                            new_predict_branch <= "01";  -- Weakly not taken
                        when "01" =>
                            new_predict_branch <= "00";  -- Strongly not taken
                        when others =>
                            new_predict_branch <= "00";  -- Strongly not taken
                    end case;
                end if;
            else
                new_predict_branch <= "00";  -- Strongly not taken
            end if;
        end if;
    end process;

    -- Process to determine if the branch is taken or not
    process(clock, index_if)
    begin
        if rising_edge(clock) then 
            case predict_branch(to_integer(unsigned(index_if))) is
                when "11" | "10" =>
                    taken <= '1';   -- Branch taken
                when "01" | "00" =>
                    taken <= '0';   -- Branch not taken
                when others =>
                    taken <= '0';   -- Default not taken
            end case;
        end if;
    end process;

    -- Predict the PC based on branch prediction or default incremented PC
    pc_predicted_IF <= br(to_integer(unsigned(index_if))) when (taken = '1' and valid_index(to_integer(unsigned(index_if))) = '1' 
                        and tag_memory_table(to_integer(unsigned(index_if))) = tag_pc_if) else
                        branchTarget when (branch_decision_ID /= taken) and branch_decision_ID = '1' and branch_ID = '1' else -- Should have been taken but was not taken
                        incrementedPC_ID when (branch_decision_ID /= taken) and branch_decision_ID = '0' and branch_ID = '1' else -- Should have been not taken but was taken
                        jumpTarget_ID when jump_ID = '1' else
                        incrementedPC_IF;

    -- Output the prediction status
    predicted_IF <= taken;
    -- Bubble the branch in ID stage
    bubble_branch_ID <= '1' when ((((branch_decision_ID xor taken) and branch_ID)) or jump_ID) = '1' else '0';
    wrong_predict <= "01" when ((branch_decision_ID xor taken) and branch_ID) = '1' else "00";

    -- Testbench signals
    branch_bit <= predict_branch(to_integer(unsigned(index_id)));
    branch_index <= index_id;
    br_test <= br(to_integer(unsigned(index_id)));
    tag_memory_table_test <= tag_memory_table(to_integer(unsigned(index_id)));
    valid_index_test <= valid_index(to_integer(unsigned(index_id)));
    branch_decision_test <= "01" when branch_decision_ID = '1' else "00";


end behavioral;
