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
 
ENTITY RoundRobinScheduler_tb IS
END RoundRobinScheduler_tb;

 
ARCHITECTURE behavior OF RoundRobinScheduler_tb IS 
	
	signal en_sim : boolean := True;
    
    signal clk : std_ulogic := '0';
    
    signal readies : std_ulogic_vector(4 downto 0) := (others=>'0');
    signal outs : std_ulogic_vector(4 downto 0);
    signal valid : std_ulogic := '0';
BEGIN


DUT : entity work.RoundRobinScheduler
generic map(
    N => 5
)
port map(
	clk => clk,
	start => valid,
	readies => readies,
	outs => outs
);


mclk : process
begin
	while en_sim = True loop
		wait for 5ns;
		clk <= not clk;
	end loop;
	wait;
end process;

ginput : process
begin        
    while en_sim = True loop
        readies <= not readies;
        wait for 20ns;
    end loop;
    wait;
end process;

ginput2 : process
begin        
    while en_sim = True loop
        valid <= '1';
        wait for 10ns;
        valid <= '0';
        wait for 500ns;
    end loop;
    wait;
end process;

END;
