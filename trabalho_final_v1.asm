.include "m328pdef.inc" ; Define device ATmega328P
.include "macros/SetStack.inc" ; macro Stack Pointer
.include "macros/debounce_filter.inc" ; macro debounce filter de botões por software

.include "macros/reset_z_pointer.inc" ; macro para redefinir valor padrão de register apontador Z
.include "macros/flash_led_and_beep.inc" ; macro para piscar LEDs e tocar buzzer de acordo com leitura da memória
.include "macros/adc_noise_to_led_opcode.inc" ; macro para converter entrada do ADC em opcode do LED
.include "macros/wait_next_round.inc" ; macro para esperar tempo até iniciar nova rodada

; Subrotinas de Macros estão no final do código (arquivos .asm)
.cseg
.org 0x0000
rjmp init
; botão por LED - cada LED teria seu próprio botão

; outro método: dois botões, um que seleciona e outro que confirma
.org 0x002A ; Usando interrupção do ADC para sempre guardar último valor gerado aleatoriamente
rjmp adc_interrupt ; interrupção usada para armazenar último valor aleatório oriundo do ADC

.org 0x0034

init:

     ; configuração Stack Pointer

     SetStack RAMEND, R16

     ; Configuração PORTC para LEDs e PORTD para botões


     ldi R16, (1 << PINB3)
     out DDRB, R16  ; habilita saída do buzzer (OC2A - pino 11 do Arduino Uno)
     clr R16
     out DDRD, R16
     out PORTC, R16
     sbr R16, 0x0F ; half-byte inferior usado para LEDs na porta C.
     out DDRC, R16
     com R16 ; half-byte superior usado para botões na porta D.
     out PORTD, R16
     ldi R16, 0b00_110000 ; mantém ligados pinos 4 e 5 do multiplexador do ADC, mas desliga os outros para evitar conflitos com LEDs da porta C
     sts DIDR0, R16
     ldi R16, 0b11_0_0_0101 ; Usa referência de tensão do ADC em 1,1V; usa modo 10 bits (só lê ADCL); usa porta 5 do ADC para leitura do ruído
     sts ADMUX, R16  ; Debug: caso não funcione reverter para modo 8 bits
     ldi R16, 0b1_1_0_0_1_111 ; liga ADC e inicia conversão; auto-trigger desligado, enable interrupt ligado; prescaler em 64.
     sts ADCSRA, R16
     sei ; habilita global interupt (SREG)
     clr R16 ; desliga MUX em modo comparação; ADC em modo single conversion (pois autotrigger está desligado)
     sts ADCSRB, R16

     ; Configuração endereçamento indireto com deslocamento

     reset_z_pointer ; chama a macro respectiva

     clr R03 ; R03 será atualizado com a referência do valor máximo de R02 (tamanho da sequência na memória)
     mov R02, R03 ; R02 será usado como índice da sequência

     debounce_filter 0x02 ; tempo suficiente para que ocorra interrupção causada pelo ADC, gravando valor "aleatório" para leitura

     jmp game1_start


game1_start:

            jmp read_and_load_random_val



read_and_load_random_val:    ; Lógica de enviar valor aleatório do ADC para o fim da sequência


                         obtain_random_from_adc R22, R23 ; macro que ajusta qual LED será aceso a partir do que é recebido do ADC (pela interrupção)
                         st Z+, R23
                         inc R03
                         clr R02
                         reset_z_pointer ; reseta apontador Z (volta a começo da SRAM - necessário para ler a sequência depois)
                         rjmp read_sequence_from_sram ; garante que será redireionado para leitura da sequência após primeira rodada


read_sequence_from_sram: ; Lógica de ler valores da sequência em ordem crescente


                         cpse R02, R03
                         cpse R02, R02  ; truque para pular linha garantidamente
                         rjmp reset_sequence_index ; vai para próxima etapa de transição
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

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 4
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_0_1
                 rjmp check_sequence

button_2_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 5
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_1_0
                 rjmp check_sequence

button_3_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 6
                 rjmp read_buttons

                 ldi R20, 0b0000_0_1_0_0
                 rjmp check_sequence

button_4_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 7
                 rjmp read_buttons

                 ldi R20, 0b0000_1_0_0_0
                 rjmp check_sequence


check_sequence:

               inc R02 ; lê o próximo índice da sequência. Só é possível chegar aqui quando o pressionamento de um botão é confirmado
               ld R16, Z+
               cpse R16, R20
               rjmp game_over ; errou! Pode ser usada uma interrupção aqui.
               flash_and_beep R20 ; se acertou, acende o LED respectivo ao botão que foi pressionado corretamente
               rjmp check_button_depressed ; encaminha a SR que verifica estado do botão



check_button_depressed:

                       in R21, PIND ; recebe valor da porta D
                       cbr R21, 0x0F ; evita bug com o Arduino - registrador pode ler PD0-1 como alto por causa de TX/RX
                       cpi R21, 0xF0 ; verifica se botões não estão pressionados
                       breq next_step ; encaminha a SR que verifica se a rodada acabou
                       rjmp check_button_depressed ; prende no loop enquanto botão estiver sendo pressionado


next_step:

          cpse R02, R03 ; verificar se a sequência acabou
          rjmp read_buttons
          ldi R16, 0b1_1_0_0_1_111 ; mesma instrução da configuração, para iniciar conversão novamente
          sts ADCSRA, R16
          timer_next_round ; chama macro de espera
          rjmp read_and_load_random_val

game_over:

          ldi R16, 0x0F
          out PORTC, R16
          rjmp loop

loop:

     nop
     rjmp loop

adc_interrupt:

              push R16
              in R16, SREG
              push R16

              lds R22, ADCL    ; salva valor de ADCL em R22 (reverter para ADCH se usar ADC em 8 bits)

              pop R16
              out SREG, R16
              pop R16

              reti

.include "macros/debounce_wait.asm"


