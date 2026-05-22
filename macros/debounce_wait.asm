wait:

     in    R16,TCNT0    ;carrega o timer 0.
     cp  R16, R17     ;compara com R17.
     brne wait          ;volta a esperar se timer não chegou no valor esperado
     ret
