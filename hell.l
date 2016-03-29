%option noyywrap
%{
#include <stdio.h>
#include <math.h>
#include "hello.tab.h"
%}

D			[0-9]
DS			{D}+
L			[a-zA-Z_]
H			[a-fA-F0-9]+h
STR			"L"

%%

"fixed"			{ return(FIXED); }
"check"         { return(CHECK); }
"spin"          { return(SPIN); }
"display"          { return(DISPLAY); }
"displaymessage"          { return(DISPLAYMS); }
"displayhex"          { return(DISPLAYHEX); }

{DS}		{ yylval = atoi(yytext); return INT;}

{L}		{ yylval = strdup(yytext); return IDENTIFIER; }

{STR}		{ yylval = strdup(yytext); return STRING; }

{H}		{ int sizeo = strlen(yytext);
		    sizeo--;
		    int dec = 0, i = 0;
		    while (i < sizeo)
		    {
			if(yytext[i] >= 0x60) yytext[i] -= 0x20;
			if(yytext[i] >= 0x40) {
				dec += (yytext[i] - 54) * pow(16,sizeo - i - 1);
			}
			else dec += (yytext[i] - 48) * pow(16,sizeo - i - 1);
			++i;
		    }

		yylval = dec;
		return(INT); }

"("			{ return(PAR_OPEN); }
")"			{ return(PAR_CLOSE); }
"-"			{ return(MINUS); }
"+"			{ return(PLUS); }
"*"			{ return(MULTIPLY); }
"/"			{ return(DIVIDE); }
"%"			{ return(MOD); }
"<"			{ return(LINEEND); }
"="			{ return(EQ_OP); }
":"         { return(ASSIGN);}


"\n"		{ return(CRLF); }


[ \t\v\f]		{ }
.			{ return(ERROR); }

%%
