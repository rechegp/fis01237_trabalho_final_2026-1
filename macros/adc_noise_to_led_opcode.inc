.macro obtain_random_from_adc ; @0 é registrador com o qual serão verificados quais bits estão ligados; @1 é onde o valor do opcode do LED será gravado.

       ; desenvolver lógica de seleção de opcode aqui. Imagino que isso possa ser aprimorado para ficar mais aleatório.


       read_adc_register_input:

                               cbr @0, 0xFC ; forço 6 MSBs da entrada do ADC a serem zero (failsafe)
                               cpi @0, 0b00000000 ; se 2 LSBs são 00, acende LED 0
                               breq led_0_on
                               cpi @0, 0b00000001  ; se os 2 LSBs são 01, acende LED 1
                               breq led_1_on
                               cpi @0, 0b00000010  ; se 2 LSBs são 10, acende LED 2
                               breq led_2_on
                               cpi @0, 0b00000011 ; se 2 LSBs são 11, acende LED 3
                               breq led_3_on
       led_0_on:

               ldi @1, 0b_0000_0_0_0_1
               rjmp exit_macro

       led_1_on:

                ldi @1, 0b_0000_0_0_1_0
                rjmp exit_macro

       led_2_on:

                ldi @1, 0b_0000_0_1_0_0
                rjmp exit_macro

       led_3_on:

               ldi @1, 0b_0000_1_0_0_0
               rjmp exit_macro

       exit_macro:

       nop




       ;ldi @1, 0b_0000_0_0_0_1 ; se tudo estiver zerado, está garantido que o LED 0 ainda acenda
       ;sbrc @0, 0 ; se bit 0 está ligado, acende LED 0
       ;ldi @1, 0b_0000_0_0_0_1
       ;sbrc @0, 1  ; e assim suscetivamente
       ;ldi @1, 0b_0000_0_0_1_0
       ;sbrc @0, 2
       ;ldi @1, 0b_0000_0_1_0_0
       ;sbrc @0, 3
       ;ldi @1, 0b_0000_1_0_0_0


.endmacro
