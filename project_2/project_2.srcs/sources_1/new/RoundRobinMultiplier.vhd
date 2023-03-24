----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2023 22:14:57
-- Design Name: 
-- Module Name: RoundRobinMultiplier - Behavioral
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


--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;

--package RRMTypes is
--    type WORD_ARRAY_type is array (integer range <>) of std_logic_vector (31 downto 0);
--end package;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RoundRobinScheduler is
generic (
    constant N : positive
);
port (
    signal clk : in std_ulogic;
    signal start : in std_ulogic;
    
    signal readies : in std_ulogic_vector(N-1 downto 0);
    
    signal outs : out std_ulogic_vector(N-1 downto 0) := (others => '0')
);
end RoundRobinScheduler;

architecture Behavioral of RoundRobinScheduler is



begin

scheduler : process(clk)

variable active : std_ulogic_vector(N-1 downto 0) := (others => '0');
type StateType is (Idle, WaitingStart, WaitingEnd);

variable state : StateType := Idle;

begin

if rising_edge(clk) then

    case state is
        when Idle =>
            if start = '1' then
                state := WaitingStart;
                active := active(N-2 downto 0) & '1';
                outs <= active;
            end if;
        when WaitingStart =>
            if (active and readies) /= active then
                state := WaitingEnd;
                outs <= (others => '0');
            end if;
        when WaitingEnd =>
            if (readies and active) = active then
                if active(N-1) = '1' then
                    state := Idle;
                    active := (others => '0');
                    outs <= (others => '0');
                else
                    active := active(N-2 downto 0) & '0';
                    outs <= active;
                    state := WaitingStart;
                end if;
            end if;
    end case;

end if;

end process;


end Behavioral;
