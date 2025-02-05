miniC : sinSemaMiniC.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c
	gcc -g sinSemaMiniC.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c  -lfl -o miniC

lex.yy.c : lexico.l sinSemaMiniC.tab.h 
	flex lexico.l

sinSemaMiniC.tab.h sinSemaMiniC.tab.c : sinSemaMiniC.y
	bison -d -v sinSemaMiniC.y 

clean : 
	rm -f sinSemaMiniC.tab.* miniC lex.yy.c codigoEnsamblador.s

run : miniC prueba.mc
	./miniC prueba.mc
