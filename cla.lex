%{
#include <cstdlib>
#include <stdlib.h>
#include <string.h> 
#include "parser.hpp"

//extern int atoi (const char *);
%}

%option nodefault

%option noyywrap

%option yylineno


/* exclusive start condition -- deals with C++ style comments */ 
%x COMMENT

DIGIT [0-9]
ID [a-zA-Z][a-zA-Z0-9]*
BLANK [\r\n\t ]
%%
{BLANK}+      

{DIGIT}+ 	          { yylval.ival = std::atoi (yytext); return INUM; }

{DIGIT}+"."{DIGIT}*   { yylval.fval = std::atof(yytext); return FNUM; }


switch           {return SWITCH;}
break            {return BREAK;}
case             {return CASE;}
default          {return DEFAULT;}

if               {return IF;}
else             { return ELSE;}

float            {return T_FLOAT;}
int               {return T_INT;}

input            {return INPUT;}
output           {return OUTPUT;}

while            {return WHILE;}


static_cast[\t ]*"<"[\t ]*int[\t ]*">"          { yylval.casts = FLOAT_TO_INT; return CAST; }
static_cast[\t ]*"<"[\t ]*float[\t ]*">"        { yylval.casts = INT_TO_FLOAT; return CAST; }

{ID}            { 
                    yylval.name = (char*)malloc(strlen(yytext)+1);
                    strcpy(yylval.name, yytext);
                    return ID; 
                }



"{"         {return '{';}
"}"         {return '}';}
"("         {return '(';}
")"         {return ')';}
":"        	{return ':';}
";"        	{return ';';}
","        	{return ',';}
"="	        {return '=';}


"!"                {return NOT;}
"&&"               {return AND;}
"||"               {return OR;}

"=="               { yylval.op = EQ; return RELOP;}
"!="               { yylval.op = NE; return RELOP;}
"<="               { yylval.op = LE; return RELOP;}
">="               { yylval.op = BE; return RELOP;}
"<"                { yylval.op = LT; return RELOP;}
">"                { yylval.op = BT; return RELOP;}

             
"*"                	{yylval.op = MUL; return MULOP;}
"/"                 {yylval.op = DIV; return MULOP;}

"+"                 {yylval.op = PLUS; return ADDOP;}

"-"                 {yylval.op = MINUS; return ADDOP;}

"/*"                { BEGIN (COMMENT); }
<COMMENT>"*/"       {  BEGIN (0); }
<COMMENT>[^*\n]*
<COMMENT>\n         { }
<COMMENT>.          { } /* skip comment */

.                   { fprintf(stderr, "line %d: unrecognized token %c\n", yylineno, yytext[0]); }

%%

