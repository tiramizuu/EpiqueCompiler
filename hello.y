%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

//#define YYSTYPE struct mint

int64_t r[26] = {0};
char* iden[26] = {0};
int isFixed[26] = {0};
int topStack = 0;

%}
%union {
        int64_t num;
        char* str;
}
%type <num> Num
%token <num> INT
%token PLUS MINUS MULTIPLY DIVIDE MOD
%token PAR_OPEN PAR_CLOSE PEAGGA_OPEN PEAGGA_CLOSE
%token DISPLAY DISPLAYMS DISPLAYHEX QUOTE
%token <str> IDENTIFIER STRING_LITERAL
%token ERROR CRLF FIXED
%token LINEEND
%token EQ_OP ASSIGN CHECK SPIN TO

%left PLUS MINUS
%left MULTIPLY DIVIDE MOD

%start Input
%%

Input:
     | Input Line
;

Line:
     CRLF
	| Expression LINEEND CRLF
	| Error CRLF
;

Expression:
     Num 
	| DISPLAYMS STRING_LITERAL { char* s = $2; 
					if(*s == '\"') {
						while(*(++s) != '\0'); 
						if(*(s-1) == '\"') printStr($2);
						else yyerror(s);
					}
					else yyerror(s); }
	| DISPLAY Num { printf("%d",$2); }
	| DISPLAYHEX Num { printf("0x%x",$2); }
    	| FIXED IDENTIFIER ASSIGN Num { if(findIdIndex($2) == -1){
								r[topStack] = $4; 
								isFixed[topStack] = 1; 
								iden[topStack++] = $2;
							}
					else printf("! ERROR : can't assign to fixed value poi~\n"); }
    	| IDENTIFIER ASSIGN Num { int index = findIdIndex($1);
					if(index == -1) {
						r[topStack] = $3; 
						isFixed[topStack] = 0; 
						iden[topStack++] = $1;
					}
					else if(isFixed[index] == 0 ) {
						r[index] = $3;
					}
					else printf("! ERROR : can't assign to fixed value poi~\n"); }
	//| CHECK PAR_OPEN Num EQ_OP Num PAR_CLOSE Expression { if($3 == $5) $$ = $7; }
	| PEAGGA_OPEN Expression PEAGGA_CLOSE
	//| SPIN PAR_OPEN Num TO Num PAR_CLOSE Expression { int i; for(i = $3 ; i < $5 ; i++) $$ = $7; }
;

Num:
    INT { $$ = $1; }
	| MINUS INT { $$ = - $2; }
	| Num MULTIPLY Num { $$ = $1 * $3; }
	| Num DIVIDE Num { $$ = $1 / $3; }
	| Num MOD Num { $$ = $1 % $3; }
	| Num PLUS Num { $$ = $1 + $3; }
	| Num MINUS Num { $$ = $1 - $3; }
    	| PAR_OPEN Num PAR_CLOSE { $$ = $2; }
	| IDENTIFIER { int s = findIdIndex($1); $$ = (s  != -1) ? r[s] : 0; }
;

Error:
	ERROR {printf("! Fuckin ERROR\n");}
	| Error ERROR {printf("! Fuckin ERROR\n");}

%%

int yyerror(char *s) {
    printf("! ERROR\n");
}

int main() {
	yyparse();
}

int findIdIndex(char* id)
{
	int i;
	for(i = 0 ; i < topStack ; i++)
	{
		if(!strcmp(id,iden[i])) return i;
	}
	return -1;
}
printStr(char* s)
{
	while(*(++s) != '\"')
		if(*s != '\\') printf("%c",*s);
		else switch(*(++s))
		{
			case('\\') : printf("\\"); break;
			case('n') : printf("\n"); break;
			case('t') : printf("\t"); break;
			case('r') : printf("\r"); break;
		}
}

