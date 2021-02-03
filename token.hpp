
/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     ID = 258,
     FNUM = 259,
     INUM = 260,
     ADDOP = 261,
     MULOP = 262,
     RELOP = 263,
     BT = 264,
     BE = 265,
     LT = 266,
     LE = 267,
     EQ = 268,
     NE = 269,
     MINUS = 270,
     PLUS = 271,
     DIV = 272,
     MUL = 273,
     NOT = 274,
     AND = 275,
     OR = 276,
     CAST = 277,
     INT_TO_FLOAT = 278,
     FLOAT_TO_INT = 279,
     IF = 280,
     ELSE = 281,
     SWITCH = 282,
     CASE = 283,
     BREAK = 284,
     DEFAULT = 285,
     WHILE = 286,
     INPUT = 287,
     OUTPUT = 288,
     T_INT = 289,
     T_FLOAT = 290
   };
#endif