%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

//#define YYSTYPE struct mint

int r[26] = {0};
char* iden[26] = {0};
int isFixed[26] = {0};
int topStack = 0;
int isData = 1;
int topreg = 0;
//FILE* f = fopen("temp.s","w");

%}
%union {
        int num;
        char* str;
}
%type <num> Num
%type <str> Identifying
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
						else yyerror(s); 
						} 
	| DISPLAY Num { printf("%d",$2); }
	| DISPLAYHEX Num { printf("0x%x",$2); }
    	| FIXED Identifying ASSIGN Num {
						r[topStack] = $4; 
						isFixed[topStack] = 1; 
						iden[topStack++] = $2;
					}
    	| Identifying ASSIGN Num { int index = findIdIndex($1);
					if(index == -1) {
						r[topStack] = $3; 
						isFixed[topStack] = 0; 
						iden[topStack] = $1;
						printf("\t%s:\t.word\t%d\n",iden[topStack++],$3);
					}
					else {
						r[index] = $3;
						printf("\tsw\t$t%d,%s\n",topreg-1,iden[index]);
						topreg = 0;
					} } 
	| CHECK Comparing Expression 
	| PEAGGA_OPEN Expression PEAGGA_CLOSE
	| SPIN Iterating Expression
;

Comparing :
	PAR_OPEN Num EQ_OP Num PAR_CLOSE { if($2 != $4) ; }
;

Iterating :
	PAR_OPEN Num TO Num PAR_CLOSE 
;
Identifying :
	IDENTIFIER { int index = findIdIndex($1);
					if(index != -1) {
						if(isFixed[index] == 0 ) {
							printText();
						}
						else { printf("! ERROR : can't assign to fixed value poi~\n"); exit(0); 
						}
					} $$ = $1; } 
;

Num:
    INT { if(!isData) printf("\tli\t$t%d,%d\n",topreg++,$1); $$ = $1; }
	| MINUS INT { if(!isData) printf("\tli\t$t%d,%d\n",topreg++, - $2); $$ = - $2; }
	| Num MULTIPLY Num { if(!isData) printf("\tmult\t$t%d,$t%d\n\tmfhi\t$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 * $3; topreg--; }
	| Num DIVIDE Num { if(!isData) printf("\tdiv\t$t%d,$t%d\n\tmflo\t$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 / $3; topreg--; }
	| Num MOD Num { $$ = $1 % $3; }
	| Num PLUS Num { if(!isData) printf("\tadd\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 + $3; topreg--; }
	| Num MINUS Num { if(!isData) printf("\tsub\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 - $3; topreg--; }
    	| PAR_OPEN Num PAR_CLOSE { $$ = $2; }
	| IDENTIFIER { int s = findIdIndex($1); $$ = (s  != -1) ? r[s] : 0; if(!isData) printf("\tlw\t$t%d,%s\n",topreg++,iden[s]); }
;

Error:
	ERROR {printf("! ERROR\n");}
	| Error ERROR {printf("! ERROR\n");}

%%

int yyerror(char *s) {
    printf("! ERROR\n");
}

int main() {
	printf(".data");
	yyparse();
}
printText()
{
	if(isData) {
		isData = 0;
		printf(".text");
	}
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

