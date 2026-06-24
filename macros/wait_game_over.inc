.macro timer_game_over

; mesma estrutura de código da macro wait_next_round, porém com temporização diferente (e o extra de fazer os LEDs piscarem juntos e acionar o buzzer).

       config_game_over_timer:


                              push R16
                              push R17
                              push R18
                              push R19
                              push R20
                              push R21

                              ; configuração timer 2 - buzzer
                              ldi R16, 0xFF
                              sts OCR2A, R16 ; envia frequência específica para ser reproduzida
                              ldi R16, 0b00_0_00_111 ; prescaler do timer 2 em 1024
                              sts TCCR2B, R16

                              ; configuração timer 1 - tempo



                              ldi R20, 0x0F ; saída para porta dos LEDs (iniciam ligados)
                              ldi R21, 0x0F ; máscara para XOR (ou exclusivo)

                              ldi  R16,0b00_0_00_101
                              sts  TCCR1B,R16            ;Configura clk com prescaler de 1024
                              ldi  R16,0b00_00_00_00
                              sts  TCCR1A,R16            ;Configura modo normal sem portas OC

                              ; configuração timer 0 - pisca LEDs

                              ldi	R16,0b00_0_00_101
	                            out	TCCR0B,R16 	         ;Configura clk com prescaler de 1024 (8 para simular no avr_sim)
                              ldi	R16,0b00_00_00_00
	                            out TCCR0A,R16           ;Configura modo normal

                              rjmp reset_game_over_timer

  reset_game_over_timer:

                         sts  TCNT1H,R27        ; Limpa timer 1H
                         sts  TCNT1L,R27        ; Limpa timer 1L
                         out  TCNT0, R27        ; Limpa timer 0
                         ldi R16, 0xFF          ; carrega tempo para aguardar até final da sequência
                         ldi R19, 0xFF          ; carrega tempo para os LEDs piscarem
                         rjmp wait_for_game_over_timer


  wait_for_game_over_timer:

                           lds  R17,TCNT1L        ; leiruta do TCNT1L - remover uma dessas instruções para o teste final
                           lds  R18,TCNT1H        ; leitura do TCNT1H
                           cpse R16,R18           ; compara com tempo (aqui comparei com TCNT1L para a simulação. O correto seria com TCNT1H)
                           rjmp flash_leds        ; volta ao loop se tempo ainda não acabou
                           rjmp exit_game_over_macro ; encerra macro se já acabou período de lep e beep desligados

  flash_leds:

             in R17,TCNT0     ;carrega o timer 0.
             cp R17, R19      ;compara com R19.
             brne flash_leds  ;volta a esperar se timer não chegou no valor esperado
             eor R20, R21     ; se LEDs estão ligados, desligam; se estão desligados, serão ligados
             out PORTC, R16
             rjmp wait_for_game_over_timer

  exit_game_over_macro:

                       sts TCCR2B, R27 ; desliga timer 2
                       out PORTB, R27  ; desliga saída do buzzer
                       sts TCCR1B, R27 ; desliga timer 1
                       out TCCR0B, R27 ; desliga timer 0
                       pop R21
                       pop R20
                       pop R19
                       pop R18
                       pop R17
                       pop R16
.endmacro
