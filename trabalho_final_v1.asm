.include "m328pdef.inc" ; Define device ATmega328P
.include "macros/SetStack.inc" ; macro Stack Pointer
.include "macros/debounce_filter.inc" ; macro debounce filter de botões por software

.include "macros/reset_z_pointer.inc" ; macro para redefinir valor padrão de register apontador Z
.include "macros/flash_led_and_beep.inc" ; macro para piscar LEDs e tocar buzzer de acordo com leitura da memória
.include "macros/adc_noise_to_led_opcode.inc" ; macro para converter entrada do ADC em opcode do LED
.include "macros/wait_next_round.inc" ; macro para esperar tempo até iniciar nova rodada
.include "macros/wait_game_over.inc" ; macro para esperar tempo para retornar ao menu inicial

; Subrotinas de Macros estão no final do código (arquivos .asm)
.cseg
.org 0x0000
jmp init
; botão por LED - cada LED teria seu próprio botão

.org 0x0016
jmp timer1_ocra_match ; Usando esta interrupção para ver se o tempo limite entre pressionamentos esgotou

.org 0x0018
jmp timer1_ocrb_match ; Usando esta interrupção para o menu inicial e acender os LEDs individualmente de forma cíclica

; outro método: dois botões, um que seleciona e outro que confirma
.org 0x002A ; Usando interrupção do ADC para sempre guardar último valor gerado aleatoriamente
jmp adc_interrupt ; interrupção usada para armazenar último valor aleatório oriundo do ADC

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
     ldi R16, 0b11_1_0_0101 ; Usa referência de tensão do ADC em 1,1V; usa modo 8 ou10 bits (só lê ADCH ou ADCL); usa porta 5 do ADC para leitura do ruído
     sts ADMUX, R16  ; Debug: caso não funcione reverter para modo 8 bits
     ldi R16, 0b1_1_0_0_1_111 ; liga ADC e inicia conversão; auto-trigger desligado, enable interrupt ligado; prescaler em 64.
     sts ADCSRA, R16
     sei ; habilita global interupt (SREG)
     clr R16 ; desliga MUX em modo comparação; ADC em modo single conversion (pois autotrigger está desligado)
     sts ADCSRB, R16

     ; Configuração endereçamento indireto com deslocamento

     reset_z_pointer ; chama a macro respectiva

     ; demais variáveis do programa

     clr R03 ; R03 será atualizado com a referência do valor máximo de R02 (tamanho da sequência na memória)
     mov R02, R03 ; R02 será usado como índice da sequência
     clr R17 ; variável de dificuldade;  tempo limite do modo de jogo (pressionamento entre botões)
     clr R18 ; variável de dificuldade; tempo que o LED/buzzer fica ligado por etapa
     clr R19 ; variável de dificuldade; tempo que o LED fica desligado por etapa
     clr R20 ; variável que grava o valor do pressionamento de botão
     clr R21 ; variável de dificuldade; tempo entre rodadas
     clr R22 ; variável que recebe o valor "bruto" da leitura do ADC
     clr R23 ; variável que recebe codificação "one-hot" de acordo com os 2 LSBs do ADC
     clr R24 ; variável de fim de jogo por exceder tempo (condição de derrota)
     clr R25 ; variável que define se a variável de fim de jogo será ligada (conta o tempo)
     ser R26 ; constante setado, usado para referência de compare da interrupção por tempo
     clr R27 ; constante zero, usado para limpar registers externos
     ldi R28, 0x01 ; variável usada para animação dos LEDs do menu de seleção de modo de jogo
     mov R15, R28  ; usado como constante 1 (verdadeiro)
     mov R29, R28 ; usado como booleano para verificar se um modo de jogo está ativo ou não

     ;debounce_filter 0x02 ; tempo suficiente para que ocorra interrupção causada pelo ADC, gravando valor "aleatório" para leitura

     jmp menu_config

     jmp game1_start

menu_config:

            ldi R28, 0x01 ; reinicia animação dos LEDs do menu inicial
            dec R29       ; reinicia seletor de modo de jogo
            ldi R16, 0xA0 ; valor definido do ciclo de acendimento para cada LED
            sts OCR1BH, R16 ; carrega valor para temporizar o compare match para interrupção
            ldi R16, 0b00_0_00_100 ; configura prescaler do timer em 256
            sts TCCR1B, R16
            ldi R16, 0b00_00_00_00 ; configura timer em modo normal
            sts TCCR1A, R16
            sts TCNT1L, R27 ; reset do timer 1 para contagem do tempo entre pressionamentos de botão
            sts TCNT1H, R27
            ldi R16, (1 << OCIE1B)
            sts TIMSK1, R16 ; liga a interrupção do timer 1 compare match OCRB

            reset_z_pointer ; reinicia registrador apontador

            jmp read_buttons ; vai para SR de leitura dos botões

read_buttons: ; Verifica qual botão foi pressionado, e então encaminha a subrotina específica


             sbis PIND, 4
             rjmp button_1_pressed
             sbis PIND, 5
             rjmp button_2_pressed
             sbis PIND, 6
             rjmp button_3_pressed
             sbis PIND, 7
             rjmp button_4_pressed
             sbrc R24, 0 ; se R24 é 1, acabou o tempo!
             rjmp game_over
             rjmp read_buttons ; se nenhum botão é pressionado, volta à leitura

button_1_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 4
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_0_1
                 cpse R27, R29        ; se não há modo de jogo ativo, encaminhar para SR de definir gamemode
                 rjmp check_sequence
                 rjmp gamemode_selected

button_2_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 5
                 rjmp read_buttons

                 ldi R20, 0b0000_0_0_1_0
                 cpse R27, R29        ; se não há modo de jogo ativo, encaminhar para SR de definir gamemode
                 rjmp check_sequence
                 jmp gamemode_selected

button_3_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 6
                 rjmp read_buttons

                 ldi R20, 0b0000_0_1_0_0
                 cpse R27, R29        ; se não há modo de jogo ativo, encaminhar para SR de definir gamemode
                 rjmp check_sequence
                 jmp gamemode_selected

button_4_pressed:

                 debounce_filter 0xFF ; usa timer 0, compara com valor chamado
                 sbic PIND, 7
                 rjmp read_buttons

                 ldi R20, 0b0000_1_0_0_0
                 cpse R27, R29        ; se não há modo de jogo ativo, encaminhar para SR de definir gamemode
                 rjmp check_sequence
                 jmp gamemode_selected

gamemode_selected:

                  call check_button_depressed ; esperar botão ser solto

                  inc R29              ; indica que um modo de jogo está em vigor
                  sts TIMSK1, R27      ; desliga a interrupção do OCRB match
                  out PORTC, R27       ; desliga LEDs do menu inicial

                  ldi R16, 0x50        ; tempo para começo da partida

                  timer_next_round R16

                  sbrc R20, 0
                  rjmp game1_start
                  sbrc R20, 1
                  rjmp game2_start
                  sbrc R20, 2
                  rjmp game3_start
                  sbrc R20, 3
                  rjmp game4_start

game1_start:

            ldi R17, 0xFF  ; valor definido de tempo limite para modo de jogo 1
            sts OCR1AH, R17 ; carrega valor para temporizar o compare match para interrupção - TROCAR PARA OCR1AH no flash
            sts OCR1AL, R27 ; tempo total é 0xFF00 * 2 (aprox. 8 segundos)
            ldi R18, 0x1E   ; valor definido de tempo de LED/buzzer ligados para modo de jogo 1
            ldi R19, 0x0F   ; valor definido de tempo de LED/buzzer desligados para modo de jogo 1
            ldi R21, 0x30   ; valor definido de tempo entre rodadas
            jmp read_and_load_random_val

game2_start:

            ldi R17, 0xBF  ; valor definido de tempo para modo de jogo 2
            sts OCR1AH, R17 ; carrega valor para temporizar o compare match para interrupção - TROCAR PARA OCR1AH no flash
            ldi R17, 0x40
            sts OCR1AL, R17 ; tempo total é 0xBF40 * 2 (aprox. 6 segundos)
            ldi R18, 0x17   ; valor definido de tempo de LED/buzzer ligados para modo de jogo 2
            ldi R19, 0x0C   ; valor definido de tempo de LED/buzzer desligados para modo de jogo 2
            ldi R21, 0x22   ; valor definido de tempo entre rodadas
            jmp read_and_load_random_val

game3_start:

            ldi R17, 0x7F  ; valor definido de tempo para modo de jogo 2
            sts OCR1AH, R17 ; carrega valor para temporizar o compare match para interrupção - TROCAR PARA OCR1AH no flash
            ldi R17, 0x80
            sts OCR1AL, R17 ; tempo total é 0x7F80 * 2 (aprox. 4 segundos)
            ldi R18, 0x0F   ; valor definido de tempo de LED/buzzer ligados para modo de jogo 1
            ldi R19, 0x08   ; valor definido de tempo de LED/buzzer desligados para modo de jogo 1
            ldi R21, 0x18   ; valor definido de tempo entre rodadas
            jmp read_and_load_random_val

game4_start:

            ldi R17, 0x3F  ; valor definido de tempo para modo de jogo 2
            sts OCR1AH, R17 ; carrega valor para temporizar o compare match para interrupção - TROCAR PARA OCR1AH no flash
            ldi R17, 0xC0
            sts OCR1AL, R17 ; tempo total é 0x3FC0 * 2 (aprox. 2 segundos)
            ldi R18, 0x8   ; valor definido de tempo de LED/buzzer ligados para modo de jogo 1
            ldi R19, 0x04   ; valor definido de tempo de LED/buzzer desligados para modo de jogo 1
            ldi R21, 0x0C   ; valor definido de tempo entre rodadas
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
                         flash_and_beep R20,R18,R19 ; macro para piscar LEDs e fazer o beep de acordo com a LED acesa
                         inc R02
                         rjmp read_sequence_from_sram

reset_sequence_index:

                     clr R02 ; limpa  R02 para ler desde o início da sequência (não pode ser feitos em subrotina com loop)
                     reset_z_pointer ; reseta apontador Z para fazer a verificação da sequência do jogador
                     ldi R16, 0b00_0_00_101 ; configura prescaler do timer em 1024
                     sts TCCR1B, R16
                     ldi R16, 0b00_00_00_00 ; configura timer em modo normal
                     sts TCCR1A, R16
                     sts TCNT1L, R27 ; reset do timer 1 para contagem do tempo entre pressionamentos de botão
                     sts TCNT1H, R27

                     ldi R16, (1 << OCIE1A)
                     sts TIMSK1, R16 ; liga a interrupção do timer 1
                     jmp read_buttons ; Vai para espera dos botões

check_sequence:


               clr R24 ; reset do tempo
               sts TIMSK1, R27 ; desliga interrupção temporariamente
               inc R02 ; lê o próximo índice da sequência. Só é possível chegar aqui quando o pressionamento de um botão é confirmado
               ld R16, Z+
               cpse R16, R20
               rjmp game_over ; errou! Fim de jogo.

               sts TCNT1L, R27 ; reinicia timer
               sts TCNT1H, R27
               clr R25 ; limpa flag usada para indicar tempo esgotado
               flash_and_beep R20,R18,R19 ; se acertou, acende o LED respectivo ao botão que foi pressionado corretamente
               ldi R16, 0b00_0_00_101 ; reconfigura prescaler do timer em 1024
               sts TCCR1B, R16
               ldi R16, (1 << OCIE1A) ;religa a iterrupção para próxima rodada
               sts TIMSK1, R16
               rjmp check_button_depressed ; encaminha a SR que verifica estado do botão



check_button_depressed:
                       sbrc R24, 0 ; verifica se jogador não segurou o botão por tempo demais!
                       rjmp game_over
                       in R16, PIND ; recebe valor da porta D
                       cbr R16, 0x0F ; evita bug com o Arduino - registrador pode ler PD0-1 como alto por causa de TX/RX
                       cpi R16, 0xF0 ; verifica se botões não estão pressionados
                       breq next_step ; encaminha a SR que verifica se a rodada acabou
                       rjmp check_button_depressed ; prende no loop enquanto botão estiver sendo pressionado


next_step:
          cpse R15, R29 ; se modo de jogo estiver carregado, voltar para ponto em que SR foi chamada
          ret
          cpse R02, R03 ; verificar se a sequência acabou
          rjmp read_buttons
          ldi R16, 0b1_1_1_0_1_111 ; mesma instrução da configuração, para iniciar conversão novamente
          sts ADCSRA, R16
          sts TIMSK1, R27 ; desabilita a interrupção do timer
          sts TCCR1B, R27 ; desliga timer 1

          timer_next_round R21 ; chama macro de espera
          rjmp read_and_load_random_val

game_over: ; fim de jogo, retornar ao menu inicial

           ; reinicia variáveis do jogo

          clr R02
          clr R03
          clr R24

          sts TIMSK1, R27 ; desliga interrupção quando o jogo acaba
          timer_game_over
          out PORTC, R27 ; desliga LEDs

          jmp menu_config


timer1_ocra_match:

                  push R16
                  in R16, SREG
                  push R16

                  com R25 ; inverte (completemento de 1) para indicar que passou um período de tempo predefinido
                  cpse R25, R26 ; vê se tempo acabou (segunda passagem na interrupção)
                  inc R24 ; será usado como condição de game over (fim do tempo!)
                  sts TCNT1L, R27 ; limpa timer, conta novamente o tempo mais uma vez
                  sts TCNT1H, R27

                  pop R16
                  out SREG, R16
                  pop R16

                  reti

timer1_ocrb_match:

                  push R16
                  in R16, SREG
                  push R16

                  out PORTC, R28 ; envia valor atual para porta dos LEDs
                  lsl R28        ; desloca bit setado para a esquerda (apaga LED que antes estava ligado, e liga o próximo da sequência)
                  sbrc R28, 4 ; se já passou pelo LED de PINC3, preciso reiniciar a sequência
                  ldi R28, 1

                  pop R16
                  out SREG, R16
                  pop R16

                  reti






adc_interrupt:

              push R16
              in R16, SREG
              push R16

              lds R22, ADCH    ; salva valor de ADCL em R22 (reverter para ADCH se usar ADC em 8 bits)

              pop R16
              out SREG, R16
              pop R16

              reti

.include "macros/debounce_wait.asm"


