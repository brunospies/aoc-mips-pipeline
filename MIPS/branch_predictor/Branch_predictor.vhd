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
        branch_ex       : in std_logic;                      -- Branch in execution instruction fetch
        pc_if           : in std_logic_vector(31 downto 0);  -- PC of the branch instruction in fetch
        pc_ex           : in std_logic_vector(31 downto 0);  -- PC of the branch instruction in execution
        pc_cal          : in std_logic_vector(31 downto 0);  -- PC of the branch instruction calculated
        branch_decision : in std_logic;                      -- Branch decision (taken or not taken)
        predict_if      : out std_logic;                     -- Prediction status (taken or not taken)
        pc_predict      : out std_logic_vector(31 downto 0); -- Predicted PC
        
        -- Testbench signals
        br_test         : out std_logic_vector(31 downto 0);
        predict_branch_test : out std_logic_vector(1 downto 0);
        tag_memory_table_test : out std_logic_vector(19 downto 0);
        valid_index_test : out std_logic;
        branch_bit : out std_logic_vector(1 downto 0);
        branch_index : out std_logic_vector(12 downto 2)
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
    alias tag_pc_if is pc_if(31 downto 12);
    alias index_if  is pc_if(12 downto 2);

    -- Instruction execution
    alias tag_pc_ex is pc_ex(31 downto 12);
    alias index_ex  is pc_ex(12 downto 2);

    -- Prediction FSM
    signal new_predict_branch : prediction;
    signal writeEnable : std_logic_vector(SIZE-1 downto 0);
    signal taken : std_logic;
    signal incrementedPC : std_logic_vector(31 downto 0);

begin            

    -- Increment PC by 4 (for next instruction)
    incrementedPC <= std_logic_vector(unsigned(pc_if) + to_unsigned(4, 32));

    -- Process to write the history table when a branch or a jump is taken (with pc_ex)
    process(clock, reset)
    begin
        if reset = '1' then
            for i in 0 to SIZE-1 loop
                tag_memory_table(i) <= (others => '0');
                br(i) <= (others => '0');
                predict_branch(i) <= (others => '0');    -- Set all the predictions to not taken
                valid_index(i) <= '0';
            end loop;
        elsif rising_edge(clock) then 
            if branch_ex = '1' then 
                br(to_integer(unsigned(index_ex))) <= pc_cal;
                tag_memory_table(to_integer(unsigned(index_ex))) <= tag_pc_ex;
                predict_branch(to_integer(unsigned(index_ex))) <= new_predict_branch(to_integer(unsigned(index_ex)));
                valid_index(to_integer(unsigned(index_ex))) <= '1';

                -- Testbench signals
                br_test <= br(to_integer(unsigned(index_ex)));
                tag_memory_table_test <= tag_memory_table(to_integer(unsigned(index_ex)));
                valid_index_test <= valid_index(to_integer(unsigned(index_ex)));
            end if;
        end if;
    end process;  

    -- Process to update prediction FSM
    process(clock)
    begin
        if rising_edge(clock) then
            -- Branch prediction must be updated only if branch is in execution and has the same tag
            if tag_memory_table(to_integer(unsigned(index_ex))) = tag_pc_ex and branch_ex = '1' then  -- Correspondence and update of dynamic branch prediction
                if branch_decision = '1' then
                    case predict_branch(to_integer(unsigned(index_ex))) is
                        when "11" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "11";  -- Strongly taken
                        when "10" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "11";  -- Taken
                        when "01" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "10";  -- Weakly taken
                        when others =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "01";  -- Weakly not taken
                    end case;
                else
                    case predict_branch(to_integer(unsigned(index_ex))) is
                        when "11" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "10";  -- Weakly taken
                        when "10" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "01";  -- Weakly not taken
                        when "01" =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "00";  -- Strongly not taken
                        when others =>
                            new_predict_branch(to_integer(unsigned(index_ex))) <= "00";  -- Strongly not taken
                    end case;
                end if;
            end if;
        end if;
    end process;

    -- Testbench signals
    branch_bit <= predict_branch(to_integer(unsigned(index_ex)));
    branch_index <= index_ex;

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
    pc_predict <= br(to_integer(unsigned(index_if))) when taken = '1' 
                 and valid_index(to_integer(unsigned(index_if))) = '1'
                 and tag_memory_table(to_integer(unsigned(index_if))) = tag_pc_if
                 else incrementedPC;

    -- Output the prediction status
    predict_if <= taken;

end behavioral;
