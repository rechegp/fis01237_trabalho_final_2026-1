delay10ms:
	ldi       r24,LOW(39998)	
	ldi       r25,HIGH(39998)	

iLoop:	sbiw	r25:r24,1	
	brne	iLoop		

	dec	r18		
	brne	delay10ms	
	nop			

	ret
