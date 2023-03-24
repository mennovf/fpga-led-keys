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
 
ENTITY sfixed_multiplier_tb IS
END sfixed_multiplier_tb;

 
ARCHITECTURE behavior OF sfixed_multiplier_tb IS 
	
--	signal en_sim : boolean := True;
    
--    signal clk : std_ulogic := '0';
    
--    constant B : integer := 12;
--    constant F : integer := 24;
    
--    signal in_A : sfixed(B-1 downto -F) := to_sfixed(-0.5, B-1, -F);
--    signal in_B : sfixed(B-1 downto -F) := to_sfixed(3.0, B-1, -F);
--    signal in_C : sfixed(B-1 downto -F) := to_sfixed(1.0, B-1, -F);
--    signal in_valid : std_ulogic := '1';
--    signal in_ready : std_ulogic;
    
--    signal out_data : sfixed(B-1 downto -F);
--    signal out_valid : std_ulogic := '0';
BEGIN


--DUT : entity work.sfixed_multiplier
--generic map (
--    B => B,
--    F=> F
--)
--port map (
--    clk => clk,
--    in_A => in_A,
--    in_B => in_B,
--    in_C => in_C,
--    in_valid => in_valid,
--    in_ready => in_ready,
--    out_data => out_data,
--    out_valid => out_valid
--);

--mclk : process
--begin
--	while en_sim = True loop
--		wait for 5ns;
--		clk <= not clk;
--	end loop;
--	wait;
--end process;

END;
