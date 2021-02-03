# all files are compiled with g++ (the C++ compiler)
 
 

all:
		./win_bison.exe -d -o parser.cpp clp.y
		./win_flex.exe -o scaner.cpp cla.lex
		g++ -g -std=gnu++17 parser.cpp scaner.cpp -o clp.exe
	
clean :
	rm parser.cpp parser.hpp scaner.cpp clp.exe
