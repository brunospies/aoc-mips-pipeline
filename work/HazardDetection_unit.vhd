-------------------------------------------------------------------------
-- Design unit: Hazard Detection Unit
-- Description: Detect data dependency with lw and the next instruction and
-- generates a bubble.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 


entity HazardDetection_unit is
    port (
        clock                : in  std_logic;
        reset                : in  std_logic;  
        rt_ID                : in  std_logic_vector (4 downto 0);
        rs_ID                : in  std_logic_vector (4 downto 0);
        rt_EX                : in  std_logic_vector (4 downto 0);
        MemToReg_EX          : in  std_logic;
        ce_pc                : out std_logic;
        ce_stage_ID          : out std_logic;
        rst_hazard_stage_EX  : out std_logic
    );
end HazardDetection_unit;

architecture arch1 of HazardDetection_unit is

signal ce : std_logic;
signal rst_hazard : std_logic;

begin

    ce <= '0' when MemToReg_EX = '1' and (rt_EX = rs_ID or rt_EX = rt_ID) else
          '1';
    
    ce_pc <= ce;
    ce_stage_ID <= ce;

    process(clock, reset)
        begin 
            if reset = '1' then
                rst_hazard <= '0';
            else 
                rst_hazard <= not ce;
            end if;
    
            if clock = '1' then
                rst_hazard_stage_EX <= rst_hazard;
            else
                rst_hazard_stage_EX <= '0';
            end if;
        end process;
            
end arch1;