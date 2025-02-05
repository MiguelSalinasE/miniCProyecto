#include <stdio.h>
#include <stdlib.h>

//Comprobación de que sea correcto el análisis
extern int yyparse();
extern int yylex();

//Variables acumuladas con los errores
extern int numErrorLex;
extern int errSeman;
extern int errSintac;

extern FILE *yyin;

int main(int argc,char* argv[]){
    if(argc != 2){
        printf("Uso correcto: %s fichero\n",argv[0]);
        exit(1);
    }
    yyin = fopen(argv[1],"r");
    if(yyin == NULL){
        printf("No se puede abrir %s\n", argv[1]);
        exit(2);
    }
    yyparse(); //Analizador léxico
    if(errSintac+numErrorLex+errSeman==0){
        printf("Código generado en fichero codigoEnsamblador.s\n");
    }else{
        printf("Errores durante compilación:\n");
        printf("-->Errores léxicos: %d\n",numErrorLex);
        printf("-->Errores sintácticos: %d\n",errSintac);
        printf("-->Errores semánticos: %d\n",errSeman);
    }
}
