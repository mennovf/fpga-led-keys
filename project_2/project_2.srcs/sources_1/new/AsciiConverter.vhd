----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2022 11:10:12
-- Design Name: 
-- Module Name: AsciiConverter - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package Ascii is
    --The CHAR_ARRAY type is a variable length array of 8 bit std_logic_vectors. 
    --Each std_logic_vector contains an ASCII value and represents a character in
    --a string. The character at index 0 is meant to represent the first
    --character of the string, the character at index 1 is meant to represent the
    --second character of the string, and so on.
    type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;
use work.Ascii.all;

entity AsciiConverter is
    Port ( signal input : in integer;
           signal converting : out std_logic;
           signal convert, clk : in std_logic;
           signal result : out CHAR_ARRAY(0 to 10);
           signal length : out positive
           );
end AsciiConverter;

architecture Behavioral of AsciiConverter is

signal in_conversion : std_logic := '0';

begin

process(clk, convert, in_conversion)
variable idx : natural;
variable temp : CHAR_ARRAY(0 to result'right);
variable reduced : integer;
variable negative : boolean;
variable len : natural := 0;
variable copy_idx : natural := 0;
constant DNC : std_logic_vector(7 downto 0) := (others=>'-');
begin
    if rising_edge(clk) then
        if in_conversion = '0' and convert = '1' then
            in_conversion <= '1';
            reduced := abs(input);
            idx := temp'right;
            negative := input < 0;
           
        end if;
        
        if in_conversion = '1' then
            if reduced = 0 then  
                
                -- Shift the temp buffer to the left 
                for i in temp'range loop
                    if i < idx + 1 then
                        temp(0 to temp'right) := temp(1 to temp'right) & DNC;
                    end if;
                end loop;
                
                -- Copy temp into result with potential negative sign               
                len := 10 - idx;
                if negative then
                    result <= std_logic_vector(to_unsigned(45, 8)) & temp(0 to temp'right - 1);
                    len := len + 1;
                else
                    result <= temp;
                end if;
                
                length <= len;
                in_conversion <= '0';
                
                if len = 0 then
                    result(0) <= X"30";
                    length <= 1;
                end if;  
            else
                temp(idx) := std_logic_vector(to_unsigned((reduced rem 10) + 48, 8));
                reduced := reduced / 10;
                idx := idx - 1;
            end if;
        end if;
    end if;
    
    converting <= in_conversion;
end process;

end Behavioral;
