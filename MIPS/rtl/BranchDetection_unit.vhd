-------------------------------------------------------------------------
-- Design unit: Branch Detection Unit
-- Description: Detect branch and generates a bubble.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 


entity BranchDetection_unit is
    port (
        clock              : in  std_logic;
        reset              : in  std_logic;  
        Branch_ID          : in  std_logic;
        zero_branch        : in  std_logic;
        jump_ID            : in  std_logic;
        rst_branch_ID      : out std_logic
    );
end BranchDetection_unit;

architecture arch1 of BranchDetection_unit is

signal rst_branch : std_logic;

begin
    process(clock, reset)
    begin 
        if reset = '1' then
            rst_branch <= '0';
        else 
            rst_branch <= (Branch_ID and zero_branch) or jump_ID;
        end if;

        if clock = '1' then
            rst_Branch_ID <= rst_branch;
        else
            rst_Branch_ID <= '0';
        end if;

    end process;
            
end arch1;