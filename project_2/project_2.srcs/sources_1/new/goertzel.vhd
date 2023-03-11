----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2023 21:59:47
-- Design Name: 
-- Module Name: goertzel - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use IEEE.MATH_REAL.ALL;

library fixed;
use fixed.fixed_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity goertzel is
generic (
    constant B : positive;
    constant F : positive;
    constant N : positive;
    constant k : natural
);

Port (
    signal clk : in std_ulogic;
    signal in_data : in sfixed(B-1 downto -F);
    signal in_valid : in std_ulogic;
    signal in_ready : out std_ulogic := '0';
    
    signal out_data : out sfixed(B-1 downto -F);
    signal out_valid : out std_ulogic := '0'
);

end goertzel;

architecture Behavioral of goertzel is
    constant omega : real := 2 * MATH_PI * k / N;
    constant double_cos_omega : real := 2*cos(omega);
begin


end Behavioral;
