.macro timer_next_round

       config_next_round_timer:
                    push R16
                    push R17
                    push R18
                    push @0

                    ; configuração timer 1 - tempo

                    ldi  R16,0b00_0_00_101
                    sts  TCCR1B,R16            ;Configura clk com prescaler de 1024
                    ldi  R16,0b00_00_00_00
                    sts  TCCR1A,R16            ;Configura modo normal sem portas OC
                    rjmp reset_next_round_timer


  reset_next_round_timer:

                         sts  TCNT1H,R27        ; Limpa timer 1H
                         sts  TCNT1L,R27        ; Limpa timer 1L
                         ;ldi R16, 0x30          ; carrega tempo para aguardar até próxima rodada em R18
                         pop @0 ; carrega tempo para aguardar até próxima rodada em R18
                         rjmp wait_for_next_round_timer


  wait_for_next_round_timer:

                 lds  R17,TCNT1L        ; leiruta do TCNT1L - remover uma dessas instruções para o teste final
                 lds  R18,TCNT1H        ; leitura do TCNT1H
                 cpse @0,R18           ; compara com tempo (aqui comparei com TCNT1L para a simulação. O correto seria com TCNT1H)
                 rjmp wait_for_next_round_timer ; volta ao loop se tempo ainda não acabou
                 rjmp exit_next_round_macro ; encerra macro se já acabou período de lep e beep desligados

  exit_next_round_macro:

                        sts TCCR1B, R27 ; desliga timer 1
                        pop R18
                        pop R17
                        pop R16
.endmacro
