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
 
ENTITY Asciifier_tb IS
END Asciifier_tb;
 
ARCHITECTURE behavior OF Asciifier_tb IS 
	signal clk : std_logic := '0';
	signal outp : std_logic_vector(15 downto 0);
	
	signal en_sim : boolean := True;
    signal input : integer;
    signal converting, convert : std_logic;
    signal result : work.Ascii.CHAR_ARRAY(0 to 10);
    signal len : positive;
BEGIN


DUT : entity work.AsciiConverter
port map(
	input => input,
	converting => converting,
    convert => convert,
    clk => clk,
    result => result,
    len => len
);


mclk : process
begin
	while en_sim = True loop
		wait for 10ns;
		clk <= not clk;
	end loop;
	wait;
end process;

    simulation : process
    begin
        input <= 25;
        convert <= '1';
        result <= (others=>(others=>'0'));
        wait until converting = '1';
        wait until converting = '0';
        en_sim <= False;
        wait;
    end process;
END;
