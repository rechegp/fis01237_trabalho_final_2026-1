.macro	delayms
	push	r18
	push	r24
	push	r25

	ldi	r18,@0/10
	rcall	delay10ms

	pop	r25
	pop	r24
	pop	r18
.endmacro 
