%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

#define YYSTYPE struct mint

int64_t r[26] = {0};
int iden[26] = {0};
int isFixed[26] = {0};
int topStack = 0;
struct mint{
	long num;
        char *str;
};
%}
/*%union {
        long num;
        char *str;
};*/
%token INT
%token PLUS MINUS MULTIPLY DIVIDE MOD
%token PAR_OPEN PAR_CLOSE PEAGGA_OPEN PEAGGA_CLOSE
%token DISPLAY DISPLAYMS DISPLAYHEX
%token IDENTIFIER QUOTE
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
	| Error CRLF {printf("! ERROR\n");}
;

Expression:
     Numeric { $$ = $1; }
	| DISPLAYMS QUOTE IDENTIFIER QUOTE { printf("%s",$3); }
	| DISPLAY Numeric { printf("%d",$2); }
	| DISPLAYHEX Numeric { printf("0x%x",$2); }
    	| FIXED IDENTIFIER ASSIGN Numeric { if(findIdIndex($2) == -1){
								r[topStack] = $4; 
								isFixed[topStack] = 1; 
								iden[topStack++] = $2;
							}
					else printf("! ERROR\n"); }
    	| IDENTIFIER ASSIGN Numeric { int index = findIdIndex($1);
					if(index == -1) {
						r[topStack] = $3; 
						isFixed[topStack] = 0; 
						iden[topStack++] = $1;
					}
					else if(isFixed[index] == 0 ) {
						r[index] = $3;
					}
					else printf("! ERROR\n"); }
	| CHECK PAR_OPEN Numeric EQ_OP Numeric PAR_CLOSE Expression { if($3 == $5) $$ = $7; }
	| PEAGGA_OPEN Expression PEAGGA_CLOSE
	| SPIN PAR_OPEN Numeric TO Numeric PAR_CLOSE Expression { int i; for(i = $3 ; i < $5 ; i++) $$ = $7; }
;

Numeric:
    INT { $$ = $1; }
	| MINUS INT { $$ = - $2; }
	| Numeric MULTIPLY Numeric { $$ = $1 * $3; }
	| Numeric DIVIDE Numeric { $$ = $1 / $3; }
	| Numeric MOD Numeric { $$ = $1 % $3; }
	| Numeric PLUS Numeric { $$ = $1 + $3; }
	| Numeric MINUS Numeric { $$ = $1 - $3; }
    	| PAR_OPEN Numeric PAR_CLOSE { $$ = $2; }
	| IDENTIFIER { int s = findIdIndex($1); $$ = (s  != -1) ? r[s] : 0; }
;

Error:
	ERROR {}
	| Error ERROR {}

%%

int yyerror(char *s) {
    printf("! ERROR\n");
}

int main() {
	yyparse();
}

int findIdIndex(int id)
{
	int i;
	for(i = 0 ; i < topStack ; i++)
	{
		if(iden[i] == id) return i;
	}
	return -1;
}

