# bison-flex-project
## Summary:
This project shows how to use both Flex and Bison to generate code in a simple low-level programming language, 
called QUAD, from a simple high-level programming language, called CPL(Compiler Project Language).

The project contain the files:
  - token.hpp : tokens declarations
  - cla.lex   : lexical declarations
  - cpl.y , cpl.hpp : syntax and AST declarations


Build:
$ make all

Usage: 
$ ./cpl.exe <input-file-name>.ou
