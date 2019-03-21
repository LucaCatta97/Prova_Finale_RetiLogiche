----------------------------------------------------------------------------------
--
-- Gabriele Daglio Matricola: 866337, Codice Persona: 10537168
-- Luca Cattaneo Matricola: 865870, Codice Persona: 10521219
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
        );    
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state is (reset, leggi_mask, salva_mask, leggi_x_punto, salva_x_punto, leggi_y_punto, salva_y_punto, analisi_mask, leggi_x_centroide, salva_x_centroide,
                   leggi_y_centroide, salva_y_centroide, calcola_distanza, confronta_distanza, scrivi_output, done, azzera);
    signal present_state, next_state: state;
    signal mask, next_mask: std_logic_vector(7 downto 0);
    signal outmask, next_outmask: std_logic_vector(7 downto 0);
    signal distanza, next_distanza, dist_min, next_dist_min: unsigned(8 downto 0);
    signal indirizzo, next_indirizzo: std_logic_vector(15 downto 0);
    signal x_punto, next_x_punto, y_punto, next_y_punto, x_centroide, next_x_centroide, y_centroide, next_y_centroide: std_logic_vector(8 downto 0);
    signal i, next_i: std_logic_vector(7 downto 0); 

begin
    --AGGIORNAMENTO STATO
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            present_state <= reset;
            mask <= "00000000";
            x_punto <= "000000000";
            y_punto <= "000000000";
            outmask <= "00000000";
            x_centroide <= "000000000";
            y_centroide <= "000000000";
            dist_min <= "111111111";
            distanza <= "000000000";
            indirizzo <= "0000000000000001";
            i <= "00000000";
            
          
        elsif(rising_edge(i_clk) and i_rst = '0') then
            present_state <= next_state;
            mask <= next_mask;
            x_punto <= next_x_punto;
            y_punto <= next_y_punto;
            outmask <= next_outmask;
            x_centroide <= next_x_centroide;
            y_centroide <= next_y_centroide;
            dist_min <= next_dist_min;
            distanza <= next_distanza;
            indirizzo <= next_indirizzo;
            i <= next_i;
            
        end if;
    end process;
    
    process(present_state, mask, x_punto, y_punto, outmask, x_centroide, y_centroide, dist_min, distanza, indirizzo, i_data, i_start, i)    
    begin
        o_address <= "0000000000000000";
        o_done <= '0';
        o_en <= '0';
        o_we <= '0';
        o_data <= "00000000";
        next_state <= present_state;
        next_mask <= mask;
        next_x_punto <= x_punto;
        next_y_punto <= y_punto;
        next_outmask <= outmask;
        next_x_centroide <= x_centroide;
        next_y_centroide <= y_centroide;
        next_dist_min <= dist_min;
        next_distanza <= distanza;
        next_indirizzo <= indirizzo;
        next_i <= i;
        
        case present_state is
            
            when reset =>
                if(i_start = '1') then
                    o_done <= '0';
                    next_state <= leggi_mask;
                end if;
                
            when leggi_mask =>
                o_en <= '1';
                o_address <= "0000000000000000";
                next_state <= salva_mask;
                
            when salva_mask =>
                next_mask <= i_data after 5 ns; --PROVARE CON AFTER 3ns
                next_state <= leggi_x_punto;
                
            when leggi_x_punto =>
                o_en <= '1';
                o_address <= "0000000000010001";
                next_state <= salva_x_punto;
            
            when salva_x_punto =>
                next_x_punto <= '0' & i_data after 5 ns;
                next_state <= leggi_y_punto;
                
            when leggi_y_punto =>
                o_en <= '1';
                o_address <= "0000000000010010";
                next_state <= salva_y_punto;
                
            when salva_y_punto =>
                next_y_punto <= '0' & i_data after 5 ns;
                next_state <= analisi_mask;
                
            when analisi_mask =>
                if(conv_integer(i) < 8) then
                    if(mask(conv_integer(i)) = '0') then
                        next_outmask(conv_integer(i)) <= '0';
                        next_indirizzo <= indirizzo + "0000000000000010";
                        next_i <= i + "00000001";
                        next_state <= analisi_mask;
                    else
                        next_state <= leggi_x_centroide;
                    end if;
                else
                    next_state <= scrivi_output;
                end if;             
            
            when leggi_x_centroide =>
                o_en <= '1';
                o_address <= indirizzo;
                next_indirizzo <= indirizzo + "0000000000000001";
                next_state <= salva_x_centroide;
                
            when salva_x_centroide =>
                next_x_centroide <= '0' & i_data after 5 ns;
                next_state <= leggi_y_centroide;
                
            when leggi_y_centroide =>
                o_en <= '1';
                o_address <= indirizzo;
                next_indirizzo <= indirizzo + "0000000000000001";
                next_state <= salva_y_centroide;
                
            when salva_y_centroide =>
                next_y_centroide <= '0' & i_data after 5 ns;
                next_state <= calcola_distanza;
            
            when calcola_distanza =>
                next_distanza <= unsigned(abs(signed(x_centroide) - signed(x_punto)) + (abs(signed(y_centroide) - signed(y_punto))));
                next_state <= confronta_distanza;
            
            when confronta_distanza =>
                if(distanza < dist_min) then
                    next_dist_min <= distanza;
                    next_state <= azzera;                   
                elsif(distanza = dist_min) then
                    next_outmask(conv_integer(i)) <= '1';
                    next_i <= i + "00000001";
                    next_state <= analisi_mask;                   
                else
                    next_outmask(conv_integer(i)) <= '0';
                    next_i <= i + "00000001";
                    next_state <= analisi_mask;                   
                end if;
                
            when azzera =>
                next_outmask <= "00000000";
                next_outmask(conv_integer(i)) <= '1';
                next_i <= i + "00000001";
                next_state <= analisi_mask;
                                           
            when scrivi_output =>
                o_en <= '1';
                o_we <= '1';
                o_address <= "0000000000010011";
                o_data <= outmask;
                next_state <= done;
           
           when done =>           
                o_done <= '1';
                next_state <= reset;                
                
        end case;        
    end process;


end Behavioral;
