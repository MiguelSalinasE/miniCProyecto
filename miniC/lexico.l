%{
#include <stdio.h>
#include <string.h>
#include "sinSemaMiniC.tab.h" 
int numErrorLex= 0;
int iniComment;
%}

digito              [0-9]
letra               [a-zA-Z]
entero              {digito}+
panico              [^ \r\n\t/a-zA-Z_0-9(){};,=+"*-]+
ID		     ({letra}|_|$)({letra}|{digito}|_|$)*
%x 		    COMMULTI
%option	    yylineno

%%
[ \n\t\r]+					;
"//"(.*)[\n]					;
"/*"						{BEGIN COMMULTI;}
<COMMULTI>([^*]|[*]+[^*/])*[*]*		;
<COMMULTI>"*/"					{BEGIN 0; yylineno;}
<COMMULTI><<EOF>>				{ numErrorLex++; 
						  printf("Fallo l�xico en la l�nea %d: comentario multil�nea sin cerrar\n", iniComment);
							return 0;
						}
print						return PRINT;
main						return MAIN;
begin						return BEGINN;
end						return END;
read						return READ;
write						return WRITE;
void						return VOID;
var						return VAR;
const						return CONST;
if						return IF;
else						return ELSE;
while						return WHILE;
"("                                           return LPAREN;		
")"                                           return RPAREN;
";"                                           return SEMICOLON;
","                                           return COMMA;
"="                                           return ASSIGNOP;
"+"						return PLUSOP;
"-"                                           return MINUSOP;
"*"						return MULTIP;
"/"						return DIV;
"{"						return LLAVE;
"}"						return RLLAVE;
{panico}					{ 
						numErrorLex++;
						printf("Fallo (l�xico): lexemas no v�lidos en la l�nea %d: \"%s\"\n", yylineno, yytext);
						};
\"([^"\n]|[\\]["])*[\n] 			{
						printf ("Fallo (l�xico):  cadena sin cerrar en la l�nea %d\n", yylineno-1);
						numErrorLex++;
						};
\"([^"]|[\\]["])*\" 				{
						yylval.str = strdup(yytext); 
						return STRING;
						};
{ID}						{ 
						if (strlen(yytext) > 16) {
							printf("Fallo (l�xico):  linea %d, Tama�o m�ximo de 16 caracteres superado, tiene %ld\n", yylineno, strlen(yytext));
							numErrorLex++;
						}
						      yylval.str = strdup(yytext);
						      return ID; 
                     				}

{entero}					{ 
							long integer = atol(yytext);
						  	if(integer > 2147483648){
								numErrorLex++;
								printf("Fallo (l�xico): l�nea %d, entero demasiado grande \"%s\"\n", yylineno, yytext);
							}
							yylval.str = strdup(yytext);
							return INTLITERAL;
							}						
%%
