.macro	setStack
.if @0>RAMEND
.error " Valor maior do que RAMEND usado para iniciar stack "
.else
	ldi	@1,LOW(@0)
	out	SPL,@1
	ldi	@1,HIGH(@0)
	out	SPH,@1
.endif
.endmacro
