#!/bin/bash
flex  -o yy.lex.c hell.l
bison -d hello.y
gcc  -o epique yy.lex.c hello.tab.c -lfl -lm
./epique < test2.ezy
