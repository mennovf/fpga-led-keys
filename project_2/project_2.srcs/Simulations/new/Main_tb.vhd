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
--USE ieee.numeric_std.ALL;
 
ENTITY Main_tb IS
END Main_tb;
 
ARCHITECTURE behavior OF Main_tb IS 
	signal clk : std_logic := '0';
	
	signal en_sim : boolean := True;
    signal sw, RsTx : std_logic;
    signal led : std_logic_vector(0 to 2);
    signal i2s_clk_out  :  std_logic;
    signal i2s_lrcl     :  std_logic;
BEGIN


DUT : entity work.Main
port map(
	clk => clk,
	sw => sw,
	led => led,
	RsTx => RsTx,
	i2s_din => '0',
	i2s_clk_out => i2s_clk_out,
	i2s_lrcl => i2s_lrcl
);


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
