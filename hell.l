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

%%

"fixed"			{ return(FIXED); }
"check"         { return(CHECK); }
"spin"          { return(SPIN); }
"to"          { return(TO); }
"display"          { return(DISPLAY); }
"displaymessage"          { return(DISPLAYMS); }
"displayhex"          { return(DISPLAYHEX); }

{DS}		{ yylval.num = atoi(yytext); return INT; }

{L}		{ yylval.str = strdup(yytext); return IDENTIFIER; }

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

		yylval.num = dec;
		return(INT); }

"("			{ return(PAR_OPEN); }
")"			{ return(PAR_CLOSE); }
"{"			{ return(PEAGGA_OPEN); }
"}"			{ return(PEAGGA_CLOSE); }
"-"			{ return(MINUS); }
"+"			{ return(PLUS); }
"*"			{ return(MULTIPLY); }
"/"			{ return(DIVIDE); }
"%"			{ return(MOD); }
"<"			{ return(LINEEND); }
"="			{ return(EQ_OP); }
"\""			{ return(QUOTE); }
":"         { return(ASSIGN);}


"\n"		{ return(CRLF); }


[ \t\v\f]		{ }
.			{ return(ERROR); }

%%
