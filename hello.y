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
int toplabel = 0, incheck = 0,inloop = 0;
FILE* f;

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
							if(incheck) { fprintf(f,"L%d:",toplabel++); incheck = 0; }
							if(inloop) { fprintf(f,"\tj\tL%d\nL%d:",toplabel,toplabel+1); inloop = 0; toplabel++; }
						}
						else yyerror(s); 
						} 
	| DISPLAY Num { fprintf(f,"\tli\t$v0,1\n\tmove\t$a0,$r%d\n\tsyscall\n",topreg-1); if(incheck) { fprintf(f,"L%d:",toplabel++); incheck = 0; } 
						if(inloop) { fprintf(f,"\tj\tL%d\nL%d:",toplabel,toplabel+1); inloop = 0; toplabel++; } }
	| DISPLAYHEX Num { fprintf(f,"0x%x",$2); if(incheck) { fprintf(f,"L%d:",toplabel++); incheck = 0; }
						if(inloop) { fprintf(f,"\tj\tL%d\nL%d:",toplabel,toplabel+1); inloop = 0; toplabel++; } }
    	| FIXED Identifying ASSIGN Num {
						r[topStack] = $4; 
						isFixed[topStack] = 1; 
						iden[topStack++] = $2;
						fprintf(f,"\t%s:\t.word\t%d\n",iden[topStack++],$4);
					}
    	| Identifying ASSIGN Num { int index = findIdIndex($1);
					if(index == -1) {
						r[topStack] = $3; 
						isFixed[topStack] = 0; 
						iden[topStack] = $1;
						fprintf(f,"\t%s:\t.word\t%d\n",iden[topStack++],$3);
					}
					else {
						r[index] = $3;
						fprintf(f,"\tsw\t$t%d,%s\n",topreg-1,iden[index]);
						if(incheck) { fprintf(f,"L%d:",toplabel++); incheck = 0; }
						if(inloop) { fprintf(f,"\tj\tL%d\nL%d:",toplabel,toplabel+1); inloop = 0; toplabel++; }
						topreg = 0;
					} } 
	| CHECK Comparing Expression 
	| PEAGGA_OPEN Expression PEAGGA_CLOSE
	| SPIN Iterating Expression
;

Comparing :
	PAR_OPEN Num EQ_OP Num PAR_CLOSE { fprintf(f,"\tbne\t$t%d,$t%d,L%d\n",topreg-2,topreg-1,toplabel); incheck = 1; }
;

Iterating :
	PAR_OPEN Num TO Num PAR_CLOSE { fprintf(f,"L%d:\tbeq\t$t%d,$t%d,L%d\n",toplabel,topreg-2,topreg-1,toplabel+1); inloop = 1; }
;
Identifying :
	IDENTIFIER { int index = findIdIndex($1);
					if(index != -1) {
						if(isFixed[index] == 0 ) {
							printText();
						}
						else { fprintf(f,"! ERROR : can't assign to fixed value poi~\n"); exit(0); 
						}
					} $$ = $1; } 
;

Num:
    INT { if(!isData) fprintf(f,"\tli\t$t%d,%d\n",topreg++,$1); $$ = $1; }
	| MINUS INT { if(!isData) fprintf(f,"\tli\t$t%d,%d\n",topreg++, - $2); $$ = - $2; }
	| Num MULTIPLY Num { if(!isData) fprintf(f,"\tmult\t$t%d,$t%d\n\tmfhi\t$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 * $3; topreg--; }
	| Num DIVIDE Num { if(!isData) fprintf(f,"\tdiv\t$t%d,$t%d\n\tmflo\t$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 / $3; topreg--; }
	| Num MOD Num { $$ = $1 % $3; }
	| Num PLUS Num { if(!isData) fprintf(f,"\tadd\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 + $3; topreg--; }
	| Num MINUS Num { if(!isData) fprintf(f,"\tsub\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); $$ = $1 - $3; topreg--; }
    	| PAR_OPEN Num PAR_CLOSE { $$ = $2; }
	| IDENTIFIER { int s = findIdIndex($1); $$ = (s  != -1) ? r[s] : 0; if(!isData) fprintf(f,"\tlw\t$t%d,%s\n",topreg++,iden[s]); }
;

Error:
	ERROR {fprintf(f,"! ERROR\n");}
	| Error ERROR {fprintf(f,"! ERROR\n");}

%%

int yyerror(char *s) {
    fprintf(f,"! ERROR\n");
}

int main() {
	f = fopen("temp.s","w");
	fprintf(f,".data");
	yyparse();
}
printText()
{
	if(isData) {
		isData = 0;
		fprintf(f,".text\nmain:");
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
		if(*s != '\\') fprintf(f,"%c",*s);
		else switch(*(++s))
		{
			case('\\') : fprintf(f,"\\"); break;
			case('n') : fprintf(f,"\n"); break;
			case('t') : fprintf(f,"\t"); break;
			case('r') : fprintf(f,"\r"); break;
		}
}

