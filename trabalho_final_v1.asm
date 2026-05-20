.cseg
.org 0x0000
rjmp init




; botão por led - cada led teria seu próprio botão

; outro método: dois botões, um que seleciona e outro que confirma
.org 0x0034

init:

.include "macros/SetStack.inc"
.include "m328pdef.inc" ; Define device ATmega328P
.include "macros/debounce_filter.inc"
.include "macros/debounce_wait.asm"
.include "macros/reset_z_pointer.inc"
.include "macros/flash_led_and_beep.inc"
.include "macros/buzzer_on_off.asm"


; configuração Stack Pointer

SetStack RAMEND, R16

; Configuração PORTD para LEDS e botões

clr R16
sbr R16, 0x0F
out DDRD, R16
com R16
out PORTD, R16

; Configuração endereçamento indireto com deslocamento

reset_z_pointer ; chama a macro respectiva

clr R03 ; R03 será atualizado com a referência do valor máximo de R02 (tamanho da sequência na memória)
mov R02, R03 ; R02 será usado como índice da sequência

rjmp game1_start


game1_start:

            rjmp read_and_load_random_val



read_and_load_random_val:    ; Lógica de enviar valor aleatório do ADC para o fim da sequência

                         ldi R16, 0b0000_0_0_0_1  ; valor de R16 será o recebido da lógica de randomização do ADC
                         sbr R16, 0xF0 ; garanto que bits mais significativos dos botões não sejam alterados
                         st Z+, R16
                         inc R03
                         clr R02
                         reset_z_pointer ; reseta apontador Z (volta a começo da SRAM - necessário para ler a sequência depois)
                         cp R03, R04
                         rjmp read_sequence_from_sram ; garante que será redireionado para leitura da sequência após primeira rodada


read_sequence_from_sram: ; Lógica de ler valores da sequência em ordem crescente


                         cp R02, R03
                         breq reset_sequence_index ; vai para próxima etapa de transição
                         ld R20, Z+
                         flash_and_beep R20 ; macro para piscar LEDs e fazer o beep de acordo com a LED acesa
                         inc R02
                         rjmp read_sequence_from_sram

reset_sequence_index:

                     clr R02 ; limpa  R02 para ler desde o início da sequência (não pode ser feitos em subrotina com loop)
                     reset_z_pointer ; reseta apontador Z para fazer a verificação da sequência do jogador
                     rjmp read_buttons ; Vai para espera dos botões

read_buttons: ; Verifica qual botão foi pressionado, e então encaminha a subrotina específica


             sbis PIND, 4
             rjmp button_1_pressed
             sbis PIND, 5
             rjmp button_2_pressed
             sbis PIND, 6
             rjmp button_3_pressed
             sbis PIND, 7
             rjmp button_4_pressed
             rjmp read_buttons ; se nenhum botão é pressionado, volta à leitura

button_1_pressed:

                 debounce_filter 0x01 ; usa timer 0, compara com valor chamado
                 sbic PIND, 4
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_0_1
                 rjmp check_sequence

button_2_pressed:

                 debounce_filter 0x01 ; usa timer 0, compara com valor chamado
                 sbic PIND, 5
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_1_0
                 rjmp check_sequence

button_3_pressed:

                 debounce_filter 0x01 ; usa timer 0, compara com valor chamado
                 sbic PIND, 6
                 rjmp read_buttons

                 ldi R20, 0b0000_0_1_0_0
                 rjmp check_sequence

button_4_pressed:

                 debounce_filter 0x01 ; usa timer 0, compara com valor chamado
                 sbic PIND, 7
                 rjmp read_buttons

                 ldi R20, 0b0000_1_0_0_0
                 rjmp check_sequence


check_sequence:
               inc R02 ; lê o próximo índice da sequência. Só é possível chegar aqui quando o pressionamento de um botão é confirmado
               sbr R20, 0xF0 ; liga bits do register para comparar com máscara da porta já presente na SRAM
               ld R16, Z+
               cpse R16, R20
               rjmp game_over ; errou! Pode ser usada uma interrupção aqui.
               flash_and_beep R20 ; se acertou, acende o LED respectivo ao botão que foi pressionado corretamente
               cpse R02, R03 ; verificar se a sequência acabou
               rjmp read_buttons
               rjmp read_and_load_random_val

game_over:
          ser R16
          out PORTD, R16
          rjmp loop

loop:
     nop
     rjmp loop



