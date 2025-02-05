%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"

    //Metodos y variables para flex
    extern int yylex();
    extern int yylineno;
    extern int numErrorLex;
    //Funcion para los mensajes 
    void yyerror(const char *msg);
    int regs[10];
    void inicializaRegs();
    //Creamos la tabla de simbolos
    Lista listaSimbolos;
    Tipo tipo;

    //Contadores
    int nCadenas = 0;
    int nEtiquetas = 1;
    int errSintac = 0;
    int errSeman = 0;

    //Funciones
    int compruebaTabla(char * simbolo);
    int insertaCadena(char * simbolo);
    int constanteComprueba(char * simbolo);
    void imprimirListaSim();
    char * getRegistroLibre();
    void liberarReg(char * reg);
    char * concatena(char * cad1, char * cad2);
    void imprimirCodigo(ListaC codigo);
    char * nuevaEtiqueta();

    //Variables para imprimir

    FILE *fichero;

%}

%code requires{
    #include "listaCodigo.h"
}

%union{
    char * str;
    ListaC codigo;
}

%token PRINT "print"
%token MAIN "main"
%token BEGINN "begin"
%token END "end"
%token READ "read"
%token WRITE "write"
%token VOID "void"
%token VAR "var"
%token CONST "const"
%token ELSE "else"
%token WHILE "while"
%token IF "if"
%token PLUSOP "+"
%token MINUSOP "-"
%token MULTIP "*"
%token DIV "/"
%token LPAREN "("
%token RPAREN ")"
%token SEMICOLON ";"
%token ASSIGNOP "="
%token LLAVE "{"
%token RLLAVE "}"
%token COMMA ","

%token <str> INTLITERAL "number"
%token <str> ID "id"
%token <str> STRING "string"

%type <codigo> expression statement statement_list print_list print_item read_list declarations identifier_list asig 

%left "+" "-"
%left "*" "/"
%precedence UMENOS

//Mensaje de error con mas detalle
%define parse.error verbose

//Para el conflicto desplaza/reduce por las sentencias if e if-else
%expect 1

%%

program         : VOID ID "(" ")" "{" {inicializaRegs(); listaSimbolos = creaLS(); } declarations statement_list "}" {
                    if(errSintac+errSeman+numErrorLex == 0){
                        imprimirListaSim();
                        concatenaLC($7,$8);
                        imprimirCodigo($7);
                    }
                    liberaLC($7);
                    liberaLC($8);
                    liberaLS(listaSimbolos);
                };

declarations    : declarations VAR {tipo = VARIABLE;} identifier_list ";"{
                    $$ = $1;
                    concatenaLC($$,$4);
                    liberaLC($4);
                }
               | declarations CONST {tipo = CONSTANTE; } identifier_list ";"{
                $$ = $1;
                concatenaLC($$,$4);
                liberaLC($4);
               } 
               | %empty{
                    $$= creaLC();
               };

identifier_list : asig{
                    $$=$1;
                }
                | identifier_list "," asig{
                    $$=$1;
                    concatenaLC($$,$3);
                    liberaLC($3);
                };
            
asig            : ID{
                    if(compruebaTabla($1)){
                        errSeman++;
                        printf("Fallo(semántico): linea %d, %s ya declarada\n",yylineno,$1);
                    } else{
                        //Insertamos el simbolo en la lista de simbolos.
                        Simbolo aux;
    			 aux.nombre = $1;
    			 aux.tipo = tipo;
    			 aux.valor = 0;
    			 insertaLS(listaSimbolos,finalLS(listaSimbolos),aux);
                    }
                    $$=creaLC();
                }
                | ID "=" expression{
                    if(compruebaTabla($1)){
                        errSeman++;
                        printf("Fallo(semántico): linea %d, %s ya declarada\n",yylineno,$1);
                    }else{
                        //Insertamos el simbolo en la lista de simbolos.
                        Simbolo aux;
    			 aux.nombre = $1;
    			 aux.tipo = tipo;
    			 aux.valor = 0;
    			 insertaLS(listaSimbolos,finalLS(listaSimbolos),aux);
                    }

                    $$=$3;

                    Operacion aux;
                    aux.op = "sw";
                    aux.res = recuperaResLC($3);
                    aux.arg1=concatena("_",$1);
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    liberarReg(aux.res);
                };

statement_list  : statement_list statement{
                    $$=$1;
                    concatenaLC($$,$2);
                    liberaLC($2);
                } 
                | %empty{
                    $$= creaLC();
                }
                ;

statement       : ID "=" expression ";"{
                    if(compruebaTabla($1)){
                        if(constanteComprueba($1)){
                            errSeman++;
                            printf("Fallo(semantico): linea %d, %s es constante\n", yylineno, $1);
                        } 
                    }else{
                        errSeman++;
                        printf("Error semantico en linea %d: %s no esta declarada\n",yylineno,$1);  
                     }
                     $$=$3;
                     Operacion aux;
                     aux.op="sw";
                     aux.res=recuperaResLC($3);
                     aux.arg1=concatena("_",$1);
                     aux.arg2=NULL;
                     insertaLC($$,finalLC($$),aux);
                     liberarReg(aux.res); 
                }
                | "{" statement_list "}" {
                    $$=$2;
                }
                | IF "(" expression ")" statement ELSE statement{
                     $$=$3;
                    char * etiq1=nuevaEtiqueta();
                    //Operación
                    Operacion aux;
                    aux.op="beqz";
                    aux.res=recuperaResLC($3);
                    aux.arg1=etiq1;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    concatenaLC($$,$5);
                    liberarReg(aux.res);
                    liberaLC($5);
                    aux.op="b";
                    //Etiqueta 2
                    char * etiq2=nuevaEtiqueta();
                    aux.res=etiq2;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    //Etiqueta 1
                    aux.op=concatena(etiq1,":");
                    aux.res=NULL;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    concatenaLC($$,$7);
                    //Etiqueta 2
                    liberaLC($7);
                    aux.op=concatena(etiq2,":");
                    aux.res=NULL;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                }
                | IF "(" expression ")" statement{
                    $$ = $3;
                    char * etiq = nuevaEtiqueta();
                    //Operacion
                    Operacion aux;
                    aux.op = "beqz";
                    aux.res=recuperaResLC($3);
                    aux.arg1 = etiq;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    liberarReg(aux.res);
                    //Etiqueta 1, corresponde inicio if
                    concatenaLC($$,$5);
                    aux.op = concatena(etiq,":");
                    aux.res = NULL;
                    aux.arg1 = NULL;
                    aux.arg2 = NULL;
                    insertaLC($$,finalLC($$),aux);
                    liberaLC($5);
                }
                | WHILE "(" expression ")" statement{
                    char * etiq1=nuevaEtiqueta();
                    char * etiq2=nuevaEtiqueta();
                    $$=creaLC();
                    //Etiqueta 1, inicio bucle
                    Operacion aux;
                    aux.op=concatena(etiq1,":");
                    aux.res=NULL;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    concatenaLC($$,$3);
                    //Operacion
                    aux.op="beqz";
                    aux.res=recuperaResLC($3);
                    aux.arg1=etiq2;
                    aux.arg2=NULL;
                    liberaLC($3);
                    insertaLC($$,finalLC($$),aux);
                    liberarReg(aux.res);
                    concatenaLC($$,$5);
                    liberaLC($5);
                    //Salto b
                    aux.op="b";
                    aux.res=etiq1;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    //Etiqueta 2, final
                    aux.op=concatena(etiq2,":");
                    aux.res=NULL;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                }
                | PRINT print_list ";"{
                    $$=$2;
                } 
                | READ read_list ";"{
                    $$=$2;
                }
                | error ";"{
                    errSintac++;
                    printf("Fallo sintactico en la linea %d\n",yylineno);
                    $$=creaLC();
                };

print_list      : print_item{
                    $$=$1;
                }
                | print_list "," print_item{
                    $$=$1;
                    concatenaLC($$,$3);
                    liberaLC($3);
                };

print_item      : expression{
                    $$=$1;
                    Operacion aux;
                    aux.op = "li";
                    aux.res = "$v0";
                    aux.arg1 = "1";
                    aux.arg2 = NULL;
                    insertaLC($$,finalLC($$),aux);
                    aux.op="move";
                    aux.res="$a0";
                    aux.arg1=recuperaResLC($1);
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    liberarReg(aux.arg1);
                    aux.op = "syscall";
                    aux.res = NULL;
                    aux.arg1 = NULL;
                    aux.arg2 = NULL;
                    insertaLC($$,finalLC($$),aux);
                }
                | STRING {
                    int nS = insertaCadena($1);
                    $$=creaLC();
                    Operacion aux;
                    aux.op="li";
                    aux.res="$v0";
                    aux.arg1="4";
                    aux.arg2=NULL;
                    insertaLC($$,finalLC($$),aux);
                    aux.op="la";
                    aux.res="$a0";
                    //Para hacer cadena que indica cadenas $str (4) + 000(3) + 0(1)=\0
                    char * cadena=(char *) malloc(4+3+1);
                    sprintf(cadena,"$str%d",nS);
                    aux.arg1=cadena;
                    aux.arg2=NULL;
                    //Insertamos el codigo en la lista
                    insertaLC($$,finalLC($$),aux);
                    //syscall
                    aux.op="syscall";
                    aux.res=NULL;
                    aux.arg1=NULL;
                    aux.arg2=NULL;
                    //Insertamos el codigo en la lista
                    insertaLC($$,finalLC($$),aux);
                };

read_list       : ID {
                    if(compruebaTabla($1)){
                        if(constanteComprueba($1)){
                            errSeman++;
                            printf("Fallo(semantico): linea %d, %s es constate\n",yylineno,$1);
                        }else{
                            $$=creaLC();
                            Operacion aux;
                            aux.op="li";
                            aux.res="$v0";
                            aux.arg1="5";
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                            aux.op="syscall";
                            aux.res=NULL;
                            aux.arg1=NULL;
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                            aux.op="sw";
                            aux.res="$v0";
                            aux.arg1=concatena("_",$1);
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                        }
                    }else{
                        errSeman++;
                        printf("Fallo(semántico): linea %d,%s no declarada\n",yylineno,$1);
                    }
                }
                | read_list "," ID {
                    if(compruebaTabla($3)){
                        if(constanteComprueba($3)){
                            errSeman++;
                            printf("Fallo(semántico): linea %d, %s es constante",yylineno,$3);
                        }else{
                            $$=$1;
                            Operacion aux;
                            aux.op="li";
                            aux.res="$v0";
                            aux.arg1="5";
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                            aux.op="syscall";
                            aux.res=NULL;
                            aux.arg1=NULL;
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                            aux.op="sw";
                            aux.res="$v0";
                            aux.arg1=concatena("_",$3);
                            aux.arg2=NULL;
                            insertaLC($$,finalLC($$),aux);
                        }
                    }else{
                        errSeman++;
                        printf("Fallo(semántico): linea %d, %s no declarada",yylineno,$3);
                    }
                };

expression      : expression PLUSOP expression {
			//Operación add, está operación nos sirve de guía para las siguientes
                         $$=$1;
                        concatenaLC($$,$3);
                        Operacion aux;
                        aux.op="add";
                        aux.res=recuperaResLC($1);
                        aux.arg1=recuperaResLC($1);
                        aux.arg2=recuperaResLC($3);
                        insertaLC($$,finalLC($$),aux);
                        liberaLC($3);
                        liberarReg(aux.arg2);
                }
                | expression MINUSOP expression{
                        $$=$1;
                        concatenaLC($$,$3);
                        Operacion aux;
                        aux.op="sub";
                        aux.res=recuperaResLC($1);
                        aux.arg1=recuperaResLC($1);
                        aux.arg2=recuperaResLC($3);
                        insertaLC($$,finalLC($$),aux);
                        liberaLC($3);
                        liberarReg(aux.arg2);
                }
                | expression MULTIP expression{
                        $$=$1;
                        concatenaLC($$,$3);
                        Operacion aux;
                        aux.op="mul";
                        aux.res=recuperaResLC($1);
                        aux.arg1=recuperaResLC($1);
                        aux.arg2=recuperaResLC($3);
                        insertaLC($$,finalLC($$),aux);
                        liberaLC($3);
                        liberarReg(aux.arg2);
                }
                | expression "/" expression{
                        $$=$1;
                        concatenaLC($$,$3);
                        Operacion aux;
                        aux.op="div";
                        aux.res=recuperaResLC($1);
                        aux.arg1=recuperaResLC($1);
                        aux.arg2=recuperaResLC($3);
                        insertaLC($$,finalLC($$),aux);
                        liberaLC($3);
                        liberarReg(aux.arg2);
                }
                | MINUSOP expression %prec UMENOS{
                        $$=$2;
                        Operacion aux;
                        aux.op="neg";
                        aux.res=recuperaResLC($2);
                        aux.arg1=recuperaResLC($2);
                        aux.arg2=NULL;
                        insertaLC($$,finalLC($$),aux);
                }
                | "(" expression ")"{
                        $$=$2;
                }
                | ID { 
                        if(!compruebaTabla($1)){
                            errSeman++;
                            printf("Error semantico en linea %d: %s no declarada\n",yylineno,$1);
                        }
                        $$ = creaLC();
                        Operacion aux;
                        aux.op="lw";
                        aux.res=getRegistroLibre();
                        aux.arg1=concatena("_",$1);
                        aux.arg2=NULL;
                        insertaLC($$,finalLC($$),aux);
                        guardaResLC($$,aux.res);
                }
                | INTLITERAL { 
                        $$=creaLC();
                        Operacion aux;
                        aux.op="li";
                        aux.res=getRegistroLibre();
                        aux.arg1=$1;
                        aux.arg2=NULL;
                        insertaLC($$,finalLC($$),aux);
                        guardaResLC($$,aux.res);

                };

%%             

void yyerror(const char * msg){
    errSintac++;
    printf("Fallo en linea %d: %s\n", yylineno, msg);
}

void inicializaRegs(){
    for(int i = 0; i < 10; i++){
        regs[i]=0;
    }
}

char * getRegistroLibre(){

    for(int i = 0; i < 10; i++){

        if(regs[i] == 0){
            regs[i]=1;
            char aux[4];
            sprintf(aux,"$t%d",i);
            return(strdup(aux));
        }

    }
    // En el caso de que se agoten los registros, el programa sigue su curso por aquí
    printf("Error: registros agotados\n");
    exit(1);
}


void liberarReg(char * reg){
    int aux = reg[2]-'0';
    regs[aux]= 0;
}

char * concatena(char * cad1, char * cad2){
	//Guardamos espacio para las dos cadenas
	char*aux= (char*)malloc(strlen(cad1)+strlen(cad2)+1);
	sprintf(aux, "%s%s",cad1,cad2);
	return aux;

}


char * nuevaEtiqueta(){
    char aux[16];
    sprintf(aux,"$l%d",nEtiquetas);
    nEtiquetas++;
    return strdup(aux);
}

int compruebaTabla(char * simbolo){

    PosicionLista p = buscaLS(listaSimbolos,simbolo);
    if(p!=finalLS(listaSimbolos)){
        return 1;
    }else{
        return 0;
    }

}

//Añadir cadena a lista de simbolos
int insertaCadena(char * simbolo){
    Simbolo aux;
    nCadenas++;
    aux.nombre=simbolo;
    aux.tipo = CADENA;
    aux.valor = nCadenas;
    insertaLS(listaSimbolos,finalLS(listaSimbolos), aux);
    return nCadenas;
}

int constanteComprueba(char * simbolo){

    PosicionLista pos = buscaLS(listaSimbolos,simbolo);
    if(pos != finalLS(listaSimbolos)){
        Simbolo aux = recuperaLS(listaSimbolos,pos);
        return aux.tipo == CONSTANTE;
    }else{
        return 0;
    }

}

void imprimirListaSim(){
    fichero = fopen("codigoEnsamblador.s","w");
    fprintf(fichero,"############################\n");
    fprintf(fichero,"# Seccion de datos\n");
    fprintf(fichero,"\t.data\n");
    fprintf(fichero,"\n");
    PosicionLista p=inicioLS(listaSimbolos);
    PosicionLista pf=finalLS(listaSimbolos);
    while(p!=pf){
        Simbolo aux=recuperaLS(listaSimbolos,p);
        if(aux.tipo==CADENA){
            fprintf(fichero,"$str%d:\n",aux.valor);
            fprintf(fichero,"\t.asciiz %s\n",aux.nombre);
        }
        p=siguienteLS(listaSimbolos,p);
    }
    p=inicioLS(listaSimbolos);
    while(p!=pf){
        Simbolo aux=recuperaLS(listaSimbolos,p);
        if(aux.tipo!=CADENA){
            fprintf(fichero,"_%s:\n",aux.nombre);
            fprintf(fichero,"\t.word 0\n");
        }
        p=siguienteLS(listaSimbolos,p);
    }
}

void imprimirCodigo(ListaC codigo){
    fprintf(fichero,"\n############################\n");
    fprintf(fichero,"# Seccion de codigo\n");
    fprintf(fichero,"\t.text\n");
    fprintf(fichero,"\t.globl main\n");
    fprintf(fichero,"main:\n");

    PosicionListaC p = inicioLC(codigo);
    while (p != finalLC(codigo)) {
        Operacion oper = recuperaLC(codigo,p);
        if(oper.op[0]!='$'){
            fprintf(fichero,"\t");
        }
        fprintf(fichero,"%s",oper.op);
        if (oper.res) fprintf(fichero," %s",oper.res);
        if (oper.arg1) fprintf(fichero,",%s",oper.arg1);
        if (oper.arg2) fprintf(fichero,",%s",oper.arg2);
        fprintf(fichero,"\n");
        p = siguienteLC(codigo,p);
    }
    fprintf(fichero,"\n############################\n");
    fprintf(fichero,"# Fin\n");
    fprintf(fichero,"\tli $v0, 10\n");
    fprintf(fichero,"\tsyscall\n");
    fclose(fichero);
}
