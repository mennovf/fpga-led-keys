----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2022 15:16:16
-- Design Name: 
-- Module Name: sk6812_tb - Behavioral
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

use work.LED.all;
 
ENTITY sk6812_tb IS
END sk6812_tb;
 
ARCHITECTURE behavior OF sk6812_tb IS 
	
    
    constant N : integer := 4;
    
	signal en_sim : boolean := True;
    
    signal clk : STD_LOGIC := '0';
    signal dout : std_ulogic := '0';
    signal send : std_ulogic := '0';
    signal ready : std_ulogic;
    signal leds : led_array(0 to N - 1);
BEGIN


DUT : entity work.sk6812
generic map(
    clk_period => 10ns,
    N => N
)
port map(
	clk => clk,
    leds => leds,
    send => send,
    ready => ready,
    dout => dout
);

generate_input : process
constant RED   : Color := (r => (others => '1'), g => (others => '0'), b => (others => '0'));
constant GREEN : Color := (r => (others => '0'), g => (others => '1'), b => (others => '0'));
constant BLUE  : Color := (r => (others => '0'), g => (others => '0'), b => (others => '1'));
constant ORDER : Color := (r => "00000001", g => "00000010", b => "00000100");

begin
    while en_sim loop
        wait for 10ns;
        leds <= (RED, GREEN, BLUE, ORDER);
    
        if ready = '1' then
            send <= '1';
            wait for 15ns;
            send <= '0';
        end if;
    end loop;
    wait;
end process;


mclk : process
begin
	while en_sim loop
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
