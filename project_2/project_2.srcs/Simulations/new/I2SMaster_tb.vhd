----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2022 15:16:16
-- Design Name: 
-- Module Name: Asciifier_tb - Behavioral
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
 
ENTITY I2SMaster_tb IS
END I2SMaster_tb;
 
ARCHITECTURE behavior OF I2SMaster_tb IS 
	
	signal en_sim : boolean := True;
    
    signal clk : STD_LOGIC := '0';
    signal din : STD_LOGIC := '0';
    signal data_ready : STD_LOGIC;
    signal dout : signed (31 downto 0);
    signal ws : STD_LOGIC;
    signal clk_out : STD_LOGIC;
BEGIN


DUT : entity work.I2SMaster
port map(
	clk => clk,
	din => din,
	data_ready => data_ready,
	dout => dout,
	ws => ws,
	clk_out => clk_out
);

generate_input : process(clk_out)
begin
    if falling_edge(clk_out) then
        din <= not din;
    end if;
end process;


mclk : process
begin
	while en_sim = True loop
		wait for 5ns;
		clk <= not clk;
	end loop;
	wait;
end process;

    --simulation : process
    --begin        
        --en_sim <= False;
        --wait;
    --end process;
END;
