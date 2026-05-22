.macro obtain_random_from_adc ; @0 é registrador com o qual serão verificados quais bits estão ligados; @1 é onde o valor do opcode do LED será gravado.

       ; desenvolver lógica de seleção de opcode aqui. Imagino que isso possa ser aprimorado para ficar mais aleatório.
       ldi @1, 0b_0000_0_0_0_1 ; se tudo estiver zerado, está garantido que o LED 0 ainda acenda
       sbrc @0, 0 ; se bit 0 está ligado, acende LED 0
       ldi @1, 0b_0000_0_0_0_1
       sbrc @0, 1  ; e assim suscetivamente
       ldi @1, 0b_0000_0_0_1_0
       sbrc @0, 2
       ldi @1, 0b_0000_0_1_0_0
       sbrc @0, 3
       ldi @1, 0b_0000_1_0_0_0




.endmacro
