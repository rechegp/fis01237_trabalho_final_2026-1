.macro reset_z_pointer

       ; Essa macro é bem direto ao ponto.

       ldi ZL, LOW(SRAM_START)
       ldi ZH, HIGH(SRAM_START)

.endmacro
