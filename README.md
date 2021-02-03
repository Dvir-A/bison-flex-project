# bison-flex-project
## Summary:
This project shows how to use both Flex and Bison to generate code in a simple low-level programming language, 
called QUAD, from a simple high-level programming language, called CPL(Compiler Project Language).

The project contain the files:
  - token.hpp : tokens declarations
  - cla.lex   : lexical declarations
  - cpl.y , cpl.hpp : syntax and AST declarations


# Build:
$ make all


# Usage: 
$ ./cpl.exe <input-file-name>.ou


# Grammar for the programming language CPL:

      program -> declarations stmt_block 

      declarations -> declarations declaration
                    | epsilon

      declaration -> idlist ':' type ';'

      type -> INT
            | FLOAT

      idlist -> idlist ',' ID
              | ID

      stmt -> assignment_stmt
            | input_stmt
            | output_stmt
            | if_stmt
            | while_stmt
            | switch_stmt
            | break_stmt 
            | stmt_block


      assignment_stmt -> ID '=' expression ';'

      input_stmt -> INPUT '(' ID ')' ';' 

      output stmt -> OUTPUT '(' expression ')'

      if stmt -> IF '(' boolexpr ')' stmt ELSE stmt 

      while_stmt -> WHILE '(' boolexpr ')' stmt

      switch_stmt -> SWITCH '(' expression ')' '{' caselist DEFAULT ':' stmtlist '}'

      caselist -> caselist CASE NUM ':' stmtlist
                | epsilon

      break_stmt -> BREAK ';'

      stmt_block -> { stmtlist }

      stmtlist	->	stmtlist stmt
                  | epsilon

      boolexpr -> boolexpr OR boolterm
                | boolterm

      boolterm -> boolterm AND boolfactor 
                | boolfactor

      boolfactor ->	NOT ( boolexpr )
                 | expression	RELOP	expression

      expression -> expression ADDOP	term
                  | term

      term -> term MULOP factor
           | factor

      factor -> ( expression )
              | static_cast<type>( expression )
              | ID
              | NUM

