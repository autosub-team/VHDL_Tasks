library IEEE;
use IEEE.std_logic_1164.all;
use work.fsm_pkg.all;
use std.textio.ALL;
use IEEE.std_logic_textio.all;

entity fsm_mealy_tb is
end fsm_mealy_tb;

architecture behavior of fsm_mealy_tb is
    component fsm
        port
        (
            CLK     : in    std_logic;
            INPUT   : in    std_logic_vector(1 downto 0);
            RST     : in    std_logic;
            OUTPUT  : out   std_logic_vector(1 downto 0);
            STATE   : out   fsm_state
        );
    end component;

    constant clk_period : time := 20 ns; -- for 50MHz -> 20 ns

    signal CLK_UUT: std_logic;
    signal INPUT_UUT: std_logic_vector(1 downto 0);
    signal RST_UUT: std_logic;
    signal OUTPUT_UUT: std_logic_vector(1 downto 0);
    signal STATE_UUT: fsm_state;

    type pattern_type is record
        RESET: std_logic; -- if 1 reset the state machine, all other fields are ignored
        INPUT: std_logic_vector(1 downto 0);
        OUTPUT: std_logic_vector(1 downto 0);
        STATE: fsm_state;
    end record;

    type pattern_array is array (natural range <>) of pattern_type;

    -- test vector pattern to check the behavior for defined transitions
    constant patterns_def : pattern_array:=(
            {{TESTPATTERN_DEF}}
    );

    -- test vector pattern to check the behavior for undefined transitions
    -- (remain in same state with last output)
    constant patterns_undef : pattern_array:=(
            {{TESTPATTERN_UNDEF}}
    );

    function Image(In_Image : Std_Logic_Vector) return String is
        variable L : Line;  -- access type
        variable W : String(1 to In_Image'length) := (others => ' ');
    begin
         WRITE(L, In_Image);
         W(L.all'range) := L.all;
         Deallocate(L);
         return W;
    end Image;

    function Image(In_Image : fsm_state) return String is

    begin
        case In_Image is
        {% for num in range(0,num_states) %}
            when {% if loop.first%}START{% else %}S{{num - 1}}{% endif %} =>
                return "{% if loop.first%}START{% else %}S{{num - 1}}{% endif %}";
        {% endfor %}
            when others =>
                return "UNDEFIDED";
        end case;
    end Image;

begin

    UUT: fsm
        port map
        (
            CLK    => CLK_UUT,
            RST    => RST_UUT,
            INPUT  => INPUT_UUT,
            OUTPUT => OUTPUT_UUT,
            STATE  => STATE_UUT
        );

    --generates the global clock cycles
    clk_generator : process
    begin
        CLK_UUT <= '0';
        wait for clk_period/2;
        CLK_UUT <= '1';
        wait for clk_period/2;
    end process;

    test:process
        variable last_state : fsm_state;
    begin

    -------------------------------
    -- CHECK DEFINED TRANSITIONS --
    -------------------------------
        for i in patterns_def'range loop
            if(patterns_def(i).RESET = '1') then
                --goto and check initial state
                RST_UUT<='1';
                wait until rising_edge(CLK_UUT);
                RST_UUT<='0';
                wait for 1 ns;

                if(STATE_UUT /= START or OUTPUT_UUT /= "00") then
                    write(OUTPUT,string'("§{\n"));

                    write(OUTPUT,string'("Error for synchronous reset") & string'("\n"));
                    write(OUTPUT,string'("\n"));

                    write(OUTPUT,string'("Expected initial configuration:") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  START ") & string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= 00") & string'("\n"));
                    write(OUTPUT,string'("\n"));

                    write(OUTPUT,string'("Received: ") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  ")&Image(STATE_UUT) & string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= ")&Image(OUTPUT_UUT) & string'("\n"));
                    write(OUTPUT,string'("\n"));
                    write(OUTPUT,string'("\n}§"));
                    report "Simulation error" severity failure;
                end if;--endif check

                last_state := START;

            else
                INPUT_UUT <= patterns_def(i).INPUT;

                wait until rising_edge(CLK_UUT);
                wait for 1 ns;

                if(STATE_UUT /= patterns_def(i).STATE or OUTPUT_UUT /= patterns_def(i).OUTPUT) then
                    write(OUTPUT,string'("§{\n"));
                    write(OUTPUT,string'("Error:") & string'("\n"));

                    write(OUTPUT,string'("   From STATE = ")&Image(last_state)& string'("\n"));
                    write(OUTPUT,string'("   With INPUT = ")&Image(patterns_def(i).INPUT)& string'("\n"));

                    write(OUTPUT,string'("Expected :")& string'("\n"));
                    write(OUTPUT,string'("   STATE= ")&Image(patterns_def(i).STATE)& string'("\n"));
                    write(OUTPUT,string'("   OUTPUT=")&Image(patterns_def(i).OUTPUT)& string'("\n"));

                    write(OUTPUT,string'("Received: ") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  ")&Image(STATE_UUT)& string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= ")&Image(OUTPUT_UUT)& string'("\n"));
                    write(OUTPUT,string'("\n}§"));
                    report "Simulation error" severity failure;
                end if;--endif check

                last_state := patterns_def(i).STATE;
            end if;--endif RESET
        end loop;

    ---------------------------------
    -- CHECK UNDEFINED TRANSITIONS --
    ---------------------------------
       for i in patterns_undef'range loop
            if(patterns_undef(i).RESET = '1') then
                --goto and check initial state
                RST_UUT<='1';
                wait until rising_edge(CLK_UUT);
                RST_UUT<='0';
                wait for 1 ns;

                if(STATE_UUT /= START or OUTPUT_UUT /= "00") then
                    write(OUTPUT,string'("§{\n"));

                    write(OUTPUT,string'("Error for synchronous reset") & string'("\n"));
                    write(OUTPUT,string'("\n"));

                    write(OUTPUT,string'("Expected initial configuration:") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  START ") & string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= 00") & string'("\n"));
                    write(OUTPUT,string'("\n"));

                    write(OUTPUT,string'("Received: ") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  ")&Image(STATE_UUT) & string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= ")&Image(OUTPUT_UUT) & string'("\n"));
                    write(OUTPUT,string'("\n"));
                    write(OUTPUT,string'("\n}§"));
                    report "Simulation error" severity failure;
                end if;--endif check

                last_state := START;

            else
                INPUT_UUT <= patterns_undef(i).INPUT;

                wait until rising_edge(CLK_UUT);
                wait for 1 ns;

                if(STATE_UUT /= patterns_undef(i).STATE or OUTPUT_UUT /= patterns_undef(i).OUTPUT) then
                    write(OUTPUT,string'("§{\n"));
                    write(OUTPUT,string'("Error:") & string'("\n"));

                    write(OUTPUT,string'("   From STATE = ")&Image(last_state)& string'("\n"));
                    write(OUTPUT,string'("   With INPUT = ")&Image(patterns_undef(i).INPUT)& string'("\n"));

                    write(OUTPUT,string'("Expected :")& string'("\n"));
                    write(OUTPUT,string'("   STATE= ")&Image(patterns_undef(i).STATE)& string'("\n"));
                    write(OUTPUT,string'("   OUTPUT=")&Image(patterns_undef(i).OUTPUT)& string'("\n"));

                    write(OUTPUT,string'("Received: ") & string'("\n"));
                    write(OUTPUT,string'("   STATE=  ")&Image(STATE_UUT)& string'("\n"));
                    write(OUTPUT,string'("   OUTPUT= ")&Image(OUTPUT_UUT)& string'("\n"));
                    write(OUTPUT,string'("\nReceived a state change or output is not 00, although the state has no transition defined for this input!}§"));

                    report "Simulation error" severity failure;
                end if;--endif check

                last_state := patterns_undef(i).STATE;
            end if;--endif RESET
        end loop;

        report "Success_{{random_tag}}" severity failure;
    end process test ;

end behavior;
