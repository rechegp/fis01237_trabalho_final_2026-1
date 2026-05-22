.macro reset_z_pointer

       ldi ZL, LOW(SRAM_START)
       ldi ZH, HIGH(SRAM_START)

.endmacro
