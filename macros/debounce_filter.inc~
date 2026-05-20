.macro debounce_filter
	push R16
	push R17
	
	config_timer:
	ldi	R16,0b00_00_00_00
	out TCCR0A,R16           ;Configura modo normal
	ldi	R16,0b00_0_00_101
	out	TCCR0B,R16 	         ;Configura clk com prescaler de 1024 (8 para simular no avr_sim)
	clr    R16            ;se B4 estiver apertado (clear) segue o código.
	out    TCNT0,R16      ;zera o timer 0.
	ldi R17, @0           ;determina tempo de debounce
	rcall wait
	
	pop R17
	pop R16

.endmacro
