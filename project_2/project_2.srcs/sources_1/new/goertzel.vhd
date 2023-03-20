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
use fixed.fixed_float_types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity goertzel is
generic (
    constant B : positive;
    constant F : positive;
    constant Nb : positive;
    constant k : natural
);

Port (
    signal clk : in std_ulogic;
    signal in_data : in sfixed(B-1 downto -F);
    signal in_valid : in std_ulogic;
    signal in_ready : out std_ulogic := '1';
    
    signal out_data : out sfixed((B-1)*2+1 downto -2*F);
    signal out_valid : out std_ulogic := '0'/*;
    
    
    signal debug_s1_2 : out sfixed((B-1)*2 + 1 downto -F*2);
    signal debug_s2_2 : out sfixed((B-1)*2 + 1 downto -F*2);
    signal debug_cs1s2 : out sfixed((B-1)*2 + 1 downto -F*2);
    signal debug_power : out sfixed((B-1)*2 + 1 downto -F*2);
    
    
    signal debug_s0 : out sfixed((B-1)*2 + 1 downto -F*2);
    signal debug_s1 : out sfixed((B-1)*2 + 1 downto -F*2);
    signal debug_s2 : out sfixed((B-1)*2 + 1 downto -F*2)
    */
);

end goertzel;

architecture Behavioral of goertzel is
    constant left : integer := B-1;
    constant right : integer := -F;
    constant pleft : integer := left *2 + 1;
    constant pright : integer := right*2;
    
    subtype FP is sfixed(left downto right);
    subtype PFP is sfixed(pleft downto pright);
    
    constant N : positive := 2 ** Nb;
    constant omega : real := 2 * MATH_PI * k / N;
    constant double_cos_omega : real := 2*cos(omega);
    constant double_cos_omega_fp : FP := to_sfixed(double_cos_omega, left, right);
    
        
    
    signal do_power : boolean := False;
    signal power_s2 : PFP;
    signal power_s1 : PFP;

begin

iterations: process(clk)
    variable i : natural range 0 to N := 0;
    
    variable s2 : PFP := (others => '0');
    variable s1 : PFP := (others => '0');
    
    variable sn0 : PFP;
    variable sn1 : PFP;
    variable sn2 : PFP;
    
    variable s1_2 : PFP;
    variable s2_2 : PFP;
    variable cs1s2 : PFP;
    variable power : PFP;
    
    variable x : FP;

    type IterationStage is (Waiting, Coeff, Addition, EndIter, Subtraction, PS1, PS2, PCS1, PCS2, PAddition);
    variable state : IterationStage := Waiting;
begin

    if rising_edge(clk) then
        case state is
            when Waiting =>
                out_valid <= '0';
                if in_valid = '1' then
                    state := Coeff;
                    x := in_data sra Nb;
                    in_ready <= '0';
                end if;
            when Coeff =>
                sn0 := resize(double_cos_omega_fp*s1, pleft, pright, fixed_saturate, fixed_truncate);
                state := Addition;
            when Addition =>
                sn1 := resize(sn0 + x, pleft, pright, fixed_saturate, fixed_truncate);
                state := Subtraction;
            when Subtraction =>
                sn2 := resize(sn1 - s2, pleft, pright, fixed_saturate, fixed_truncate);
                state := EndIter;
            when EndIter =>
                i := i + 1;
                if i = N-1 then
                    i := 0;
                    state := PS1;
                else
                    s2 := s1;
                    s1 := sn2;
                    state := Waiting;
                    in_ready <= '1';
                end if;
            when PS1 =>
                s1_2 := resize(s1 * s1, pleft, pright, fixed_saturate, fixed_truncate);
                state := PS2;
            when PS2 =>
                s2_2 := resize(s2 * s2, pleft, pright, fixed_saturate, fixed_truncate);
                state := PCS1;
            when PCS1 =>
                cs1s2 := resize(double_cos_omega_fp * s1, pleft, pright, fixed_saturate, fixed_truncate);
                state := PCS2;
            when PCS2 =>
                cs1s2 := resize(cs1s2 * s2, pleft, pright, fixed_saturate, fixed_truncate);
                state := PAddition;
            when PAddition =>
                power := resize(s1_2 + s2_2 - cs1s2, pleft, pright, fixed_saturate, fixed_truncate);
                out_data <= power;
                out_valid <= '1';
                in_ready <= '1';
                s2 := (others => '0');
                s1 := (others => '0');
                state := Waiting;
            end case;
    end if;
end process;


end Behavioral;
