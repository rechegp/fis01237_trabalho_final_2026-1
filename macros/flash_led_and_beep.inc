.macro flash_and_beep

       push R16
       push R17
       push R18
       push R19
       push @0

; não precisa fazer comparação, o valor da porta é o que precisa ser enviado! O que precisa diferenciar é a lógica para o buzzer.

      rjmp config_timer

  config_timer:

               ; config timer 1 - temporização

               ldi  R16,0b00_00_00_00
               sts  TCCR1A,R16            ;Configura modo normal sem portas OC
               ldi  R16,0b00_0_00_101
               sts  TCCR1B,R16            ;Configura clk com prescaler de 1024
               ldi  R16,0x0a              ; Ajusta R16 para 10
               sts  OCR1AH,R16            ;Ajusta o comparador A high do timer 1 para 10
               clr  R16                   ; Limpar R16
               sts  OCR1AL,R16            ;Ajusta o comparador A low do timer 1 para 0

               ; config timer 2 - onda quadrada buzzer

               ldi R16, 0b01_00_00_10 ; liga timer 2 em modo CTC com saída OC2A habilitada
               sts TCCR2A, R16
               ldi R16, 0b00_0_00_110 ; prescaler em 256
               sts TCCR2B, R16
               clr R16
               sts OCR2A, R16

               rjmp led_beep_on



  reset_timer:

              clr  R16
              sts  TCNT1H,R16        ; Limpa timer 1H
              sts  TCNT1L,R16        ; Limpa timer 1L
              sts TCNT2, R16         ; Limpa timer 2

              ret

  led_beep_on:
              clr R19 ; variável de controle resetada

              pop @0 ; pego meu register que escolho do stack pointer contendo informação de qual LED acender
              out PORTC, @0 ; envio sinal para a porta, acendendo o LED requisitado
              sbrc @0, 0
              ldi R16, 140 ; valor de OCR2A necessário para frequência do CTC em 220 Hz
              sbrc @0, 1
              ldi R16, 120 ; valor de OCR2A necessário para frequência do CTC em 260 Hz
              sbrc @0, 2
              ldi R16, 94  ; valor de OCR2A necessário para frequência do CTC em 330 Hz
              sbrc @0, 3
              ldi R16, 70  ; valor de OCR2A necessário para frequência do CTC em 440 Hz

              sts OCR2A, R16 ; envia frequência específica para ser reproduzida
              rcall reset_timer ; reiniciar timer antes de entrar na SR de aguardo
              ldi R16, 0x1E ; ajuste da comparação do timer - tempo ligado - para flash usar 0x1E
              rjmp wait_for_timer ; entra na SR para aguardar o timer acabar

  wait_for_timer:

                 lds  R17,TCNT1L        ; leiruta do TCNT1L - remover uma dessas instruções para o teste final
                 lds  R18,TCNT1H        ; leitura do TCNT1H
                 cpse R16,R18           ; compara com tempo (aqui comparei com TCNT1L para a simulação. O correto seria com TCNT1H)
                 rjmp wait_for_timer ; volta ao loop se tempo ainda não acabou
                 cpi R19, 1 ; se passou por aqui antes, precisa ir para outra subrotina
                 breq exit_macro ; encerra macro se já acabou período de lep e beep desligados
                 rjmp led_beep_off ; contagem chegou ao fim, ir para SR para desligar o LED

  led_beep_off:

               clr R17 ; limpa o que já estiver em R17
               clr R16 ; desliga LEDs, mas mantém pull-up interno dos botões configurados
               out PORTC, R16 ; envia sinal à porta, desligando os LEDs
               out PORTB, R16
               sts TCCR2B, R16 ; desliga timer 2 (saída OC2A desligada)
               inc R19 ; usado na SR wait_for_timer para que não volte à esta subrotina depois de desligar o LED
               rcall reset_timer ; reseta o timer mais uma vez
               ldi R16, 0x0F ; reconfigura timer para segurar por um certo período de tempo o desligamento - para flash usar 0x0F
               rjmp wait_for_timer


  exit_macro:

             ; não faço pop do @0, pois já foi usado na SR led_beep_on

             sts TCCR1B, R16 ; desliga timer 1 após fim da macro

             pop R19
             pop R18
             pop R17
             pop R16

.endmacro
