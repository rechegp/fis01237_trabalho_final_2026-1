.macro debounce_filter

	push R16
	push R17
	

  ; configuração do timer 0 (usado apenas para filtro debounce)

  ; inverti ordem dos registers por causa do simulador
  ldi	R16,0b00_0_00_101
	out	TCCR0B,R16 	         ;Configura clk com prescaler de 1024 (8 para simular no avr_sim)
  ldi	R16,0b00_00_00_00
	out TCCR0A,R16           ;Configura modo normal


	out    TCNT0,R27      ;zera o timer 0.
	ldi R17, @0           ;determina tempo de debounce

  ; subrotina da macro

	call wait

  out TCCR0B, R27 ; desliga timer 0 após fim da contagem
	
	pop R17
	pop R16

.endmacro
