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
int isData = 1, isDataOnWrite = 1, loopreg;
int topreg = 0,topstring = 0;
int toplabel = 0, incheck = 0,inloop = 0;
FILE* f;
typedef struct node{
	char* data;
	struct node* next;
}node;
node* h;
node* tdata;
node* ttext;
char* replaceStr(char* s);
char* replaceStr2(char* s);

%}
%union {
        int num;
        char *str;
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
	| DISPLAYMS STRING_LITERAL { char *s = $2; 
						if(*s == '\"') {
							while(*(++s) != '\0'); 
							if(*(s-1) == '\"') {
								//char* stringg;
								//stringg = replaceStr2($2);
								char *printdata = (char*)calloc(40,sizeof(char)); 
								sprintf(printdata,"\tString%d\t.asciiz\t%s\n",topstring++,$2);
								appendData(printdata);
								char *printcode = (char*)calloc(40,sizeof(char)); 
								sprintf(printcode,"\tli\t$v0,4\n\tla\t$a0,String%d\n\tsyscall\n",topstring-1); 
								appendText(printcode);
							}
							else yyerror("expected \" at the end of string");
							if(incheck) { char *t = (char*)calloc(20,sizeof(char)); 
									sprintf(t,"L%d:",toplabel++); appendText(t); incheck = 0; }
							if(inloop) { char *t = (char*)calloc(40,sizeof(char)); 
									sprintf(t,"\tli\t$t%d,1\n\tadd\t$t%d,$t%d,$t%d\n\tj\tL%d\nL%d:",topreg-1,loopreg,topreg-1,loopreg,toplabel,toplabel+1); appendText(t); inloop = 0; toplabel++; }
						}
						else yyerror("expected \" at the begin of string"); 
						} 
	| DISPLAY Num { if(isData) {
				isData = 0;
				char *s = (char*)calloc(20,sizeof(char)); sprintf(s,"\tli\t$t%d,%d\n",topreg++,$2); appendText(s);
			}
			char *s = (char*)calloc(40,sizeof(char)); 
			sprintf(s,"\tli\t$v0,1\n\tmove\t$a0,$t%d\n\tsyscall\n",topreg-1); appendText(s); 
			if(incheck) { char *t = (char*)calloc(20,sizeof(char)); ; sprintf(t,"L%d:",toplabel++); appendText(t); incheck = 0; } 
			if(inloop) { char *t = (char*)calloc(40,sizeof(char)); ; 
					sprintf(t,"\tli\t$t%d,1\n\tadd\t$t%d,$t%d,$t%d\n\tj\tL%d\nL%d:",topreg-1,loopreg,topreg-1,loopreg,toplabel,toplabel+1); appendText(t); inloop = 0; toplabel++; } }
	| DISPLAYHEX Num { char *s = (char*)calloc(15,sizeof(char));  
				sprintf(s,"\tString%d\t.asciiz\t\"0x%x\"",topstring++,$2); appendData(s);
				char *printcode = (char*)calloc(40,sizeof(char)); 
				sprintf(printcode,"\tli\t$v0,4\n\tla\t$a0,String%d\n\tsyscall\n",topstring-1); 
				appendText(printcode); 
						if(incheck) { char *t = (char*)calloc(20,sizeof(char)); 
								sprintf(t,"L%d:",toplabel++); appendText(t); incheck = 0; }
						if(inloop) { char *t = (char*)calloc(40,sizeof(char)); 
								sprintf(t,"\tli\t$t%d,1\n\tadd\t$t%d,$t%d,$t%d\n\tj\tL%d\nL%d:",topreg-1,loopreg,topreg-1,loopreg,toplabel,toplabel+1); appendText(t); inloop = 0; toplabel++; } }
    	| FIXED Identifying ASSIGN Num {
						r[topStack] = $4; 
						isFixed[topStack] = 1; 
						iden[topStack] = $2;
						char *s = (char*)calloc(30,sizeof(char)); 
						sprintf(s,"\t%s:\t.word\t%d\n",iden[topStack++],$4); appendData(s);
					}
    	| Identifying ASSIGN Num { int index = findIdIndex($1);
					if(index == -1) {
						r[topStack] = $3; 
						isFixed[topStack] = 0; 
						iden[topStack] = $1;
						char *s = (char*)calloc(30,sizeof(char)); 
						sprintf(s,"\t%s:\t.word\t%d\n",iden[topStack++],$3); appendData(s);
						if(incheck || inloop) yyerror("can't assign to fixed variable more than once poi~.");
					}
					else {
						r[index] = $3;
						char *s = (char*)calloc(20,sizeof(char)); 
						sprintf(s,"\tsw\t$t%d,%s\n",topreg-1,iden[index]); appendText(s);
						if(incheck) { char *t = (char*)calloc(20,sizeof(char)); 
							sprintf(t,"L%d:",toplabel++); incheck = 0; appendText(t); }
						if(inloop) { char *t = (char*)calloc(40,sizeof(char)); 
							sprintf(t,"\tli\t$t%d,1\n\tadd\t$t%d,$t%d,$t%d\n\tj\tL%d\nL%d:",topreg-1,loopreg,topreg-1,loopreg,toplabel,toplabel+1); inloop = 0; toplabel++; appendText(t); }
						topreg = 0;
					} } 
	| CHECK Comparing Expression 
	| PEAGGA_OPEN Expression PEAGGA_CLOSE
	| SPIN Iterating Expression
;

Comparing :
	PAR_OPEN Num EQ_OP Num PAR_CLOSE { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tbne\t$t%d,$t%d,L%d\n",topreg-2,topreg-1,toplabel); appendText(s); incheck = 1; }
;

Iterating :
	PAR_OPEN Num TO Num PAR_CLOSE { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"L%d:\tbeq\t$t%d,$t%d,L%d\n",toplabel,topreg-2,topreg-1,toplabel+1); 
					appendText(s); inloop = 1; loopreg = topreg - 2; }
;
Identifying :
	IDENTIFIER { int index = findIdIndex($1);
					if(index != -1) {
						if(isFixed[index] == 0 ) {
							isData = 0;
						}
						else { printf("! ERROR : can't assign to fixed value poi~\n"); exit(0); 
						}
					} $$ = $1; } 
;

Num:
    INT {  if(!isData) { char *s = (char*)calloc(20,sizeof(char)); sprintf(s,"\tli\t$t%d,%d\n",topreg++,$1); appendText(s); } 
$$ = $1; }
	| MINUS Num { if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tli\t$t%d,%d\n",topreg++, - $2); appendText(s); } $$ = - $2; }
	| Num MULTIPLY Num { if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tmult\t$t%d,$t%d\n\tmfhi\t$t%d\n",topreg-2,topreg-1,topreg-2); 
					appendText(s); } $$ = $1 * $3; topreg--; }
	| Num DIVIDE Num { if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tdiv\t$t%d,$t%d\n\tmflo\t$t%d\n",topreg-2,topreg-1,topreg-2); 
					appendText(s); } $$ = $1 / $3; topreg--; }
	| Num MOD Num { if(!isData) { char *s = (char*)calloc(40,sizeof(char)); 
					sprintf(s,"L%d\tblt\t$t%d,$t%d,L%d\n\tsub\t$t%d,$t%d\nL%d",toplabel,topreg-2,topreg-1,toplabel+1,topreg-2,topreg-1,topreg-2,toplabel+1); 
					toplabel++; appendText(s); } $$ = $1 % $3; topreg--; }
	| Num PLUS Num { if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tadd\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); 
					appendText(s); } $$ = $1 + $3; topreg--; }
	| Num MINUS Num { if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tsub\t$t%d,$t%d,$t%d\n",topreg-2,topreg-1,topreg-2); 
					appendText(s); }  $$ = $1 - $3; topreg--; }
    	| PAR_OPEN Num PAR_CLOSE { $$ = $2; }
	| IDENTIFIER { int inde = findIdIndex($1); if(inde  != -1) $$ = r[inde]; else {
						char *errormsg = (char*)calloc(30,sizeof(char));
						sprintf(errormsg,"Variable undeclared : %s",$1);
						yyerror(errormsg); 
					}
					if(!isData) { char *s = (char*)calloc(20,sizeof(char)); 
					sprintf(s,"\tlw\t$t%d,%s\n",topreg++,iden[inde]); appendText(s); } }
;

Error:
	ERROR {printf("! ERROR\n");}
	| Error ERROR {printf("! ERROR\n");}

%%

int yyerror(char *s) {
    	printf("! ERROR %s\n",s);
	node* runner = h;
	while(runner){
		node* prerun = runner;
		runner = runner->next;
		free(prerun);
	}
	exit(0);
}

int main() {
	f = fopen("temp.s","w");
	yyparse();
	printAll();
	fclose(f);
}
printText()
{
	isDataOnWrite = 0;
	fprintf(f,"\n.TEXT\nmain:\n");
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
char* replaceStr(char* s)
{
	char* newStr = (char*) calloc(40,sizeof(char));
	char* runner = newStr;
	while(*(++s) != '\"') {
		if(*s != '\\') *runner = *s;
		else switch(*(++s))
		{
			case('\\') : *runner = '\\'; break;
			case('n') : *runner = '\n'; break;
			case('t') : *runner = '\t'; break;
			case('r') : *runner = '\r'; break;
		}
		printf("%c %c\n",*s,*runner);
		runner++;
	}
	return newStr;
}
char* replaceStr2(char* s)
{
	char* newStr = (char*) calloc(40,sizeof(char));
	char* runner = newStr;
	*runner = *s;
	runner++;
	while(*(++s) != '\"') {
		if(*s != '\\') *runner = *s;
		else switch(*(++s))
		{
			case('\\') : *runner = '\\'; break;
			case('n') : *runner = '\n'; break;
			case('t') : *runner = '\t'; break;
			case('r') : *runner = '\r'; break;
		}
		runner++;
	}
	*runner = *s;
	runner++;
	return newStr;
}
node* getNode(char* s)
{
	node* n = (node*)malloc(sizeof(node));
	n->data = s;
	n->next = NULL;
	return n;
}
appendData(char* s)
{
	node* n = getNode(s);
	if(!tdata) {
		n->next = h;
		h = n;
	}
	else{
		n->next = tdata->next;
		tdata->next = n;
	}
	tdata = n;
}
appendText(char* s)
{
	node* n = getNode(s);
	if(!h){
		h = n;
	}
	else if(!ttext) {
		tdata->next = n;
	}
	else{
		ttext->next = n;
	}
	ttext = n;
}
printAll()
{
	node* runner = h;
	if(tdata) fprintf(f,".DATA");
	//printf("%s",runner->data);
	while(runner){
		if((!tdata && isDataOnWrite) || (tdata && isDataOnWrite && runner == tdata->next)) printText();
		fprintf(f,"%s",runner->data);
		node* prerun = runner;
		runner = runner->next;
		free(prerun);
	}
}

