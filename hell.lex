%option noyywrap
%{
#include <stdio.h>
#include <math.h>
#include "hello.tab.h"
%}

D			[0-9]
DS			{D}+
H			[a-fA-F0-9]+h
B			[0-1]+b
MD			-{D}+

%%

"fixed"			{ count(); return(FIXED); }
"check"         { count(); return(CHECK); }
"SPIN"          { count(); return(SPIN); }

{DS}		{ yylval = atoi(yytext); return INT;}
{MD}		{ yylval = atoi(yytext); return INT;}

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
		return(HEX); }
{B}		{ int sizeo = strlen(yytext);
		    sizeo--;
		    int dec = 0, i = 0;
		    while (i < sizeo)
		    {
			if(yytext[i] - 48) dec += pow(2,sizeo - i - 1);
			++i;
		    }

		yylval = dec;
		return(BIN); }

"$r"		{ return(REG); }

"("			{ return(PAR_OPEN); }
")"			{ return(PAR_CLOSE); }
"-"			{ return(MINUS); }
"+"			{ return(PLUS); }
"*"			{ return(MULTIPLY); }
"/"			{ return(DIVIDE); }
"%"			{ return(MOD); }
"<"			{ count(); return('<'); }
"="			{ count(); return(EQ_OP); }
":"         { count(); return(';');}

"$acc"			{ return(ACC); }
"$top"			{ return(TOP); }
"$size"			{ return(SIZE); }


"\n"		{ return(CRLF); }


[ \t\v\f]		{ }
.			{ return(ERROR); }

%%

