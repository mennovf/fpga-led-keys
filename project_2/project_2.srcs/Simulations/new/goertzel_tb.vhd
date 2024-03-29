----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2022 15:16:16
-- Design Name: 
-- Module Name: Goertzel_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.textio.all;
USE ieee.std_logic_textio.all;
use ieee.numeric_std.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

library fixed;
use fixed.fixed_pkg.all;
 
ENTITY Goertzel_tb IS
END Goertzel_tb;

use work.SFixedMultiplierInterface.all;

 
ARCHITECTURE behavior OF Goertzel_tb IS 
	
	signal en_sim : boolean := True;
    
    signal clk : std_ulogic := '0';
    
    signal in_data : FP;
    signal in_valid : std_ulogic := '0';
    signal in_ready : std_ulogic;
    
    signal out_data : FP;
    signal out_valid : std_ulogic;
    
    signal madd_input : MultAddInput;
    signal madd_output : MultAddOutput;
BEGIN

--multiplier : entity work.sfixed_multiplier
--port map (
--    clk => clk,
--    ins => madd_input,
--    outs => madd_output
--);



--DUT : entity work.goertzel
--generic map(
--    Nb => 10,
--    k => 0
--)
--port map(
--	clk => clk,
--	in_data => in_data,
--	in_ready => in_ready,
--	in_valid => in_valid,
	
--	out_data => out_data,
--	out_valid => out_valid,
	
--	multaddin => madd_input,
--	multaddout => madd_output
--);




mclk : process
begin
	while en_sim = True loop
		wait for 5ns;
		clk <= not clk;
	end loop;
	wait;
end process;

ginput : process(clk)
constant MAX : positive := 1;
variable counter : natural range 0 to MAX := 0;
begin        
    if rising_edge(clk) then
        if in_ready = '1' then
            in_valid <= '1';
            --in_data <= (0 => '1', others => '0') when counter = 0 else (0 => '0', others => '0');
            in_data <= (1 => '1', others => '0');
            
            if counter < MAX then
                counter := counter + 1;
            else
                counter := 0;
            end if;
        else
            --in_valid <= '0';
        end if;
    end if;
end process;
END;
