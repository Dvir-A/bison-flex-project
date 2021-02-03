%{

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <list>
#define YYERROR_VERBOSE 1

extern int yylex();
extern int yyparse();
//extern FILE* yyin;

void yyerror(std::string s);
%}


%code {
	Store * my_store;
}

%code requires {
	#include "clp.hpp"
}


%union {
   int ival;
   float fval;
   char * name;

	enum yytokentype op,casts,types;
   
   std::list<std::string> * idLstPtr;       

   
   //  pointers to AST nodes:
   Stmt *stmt;
   StmtBlock *stmt_block;
   AssignStmt *assignment_stmt;
   InputStmt *input_stmt;
   OutputStmt * output_stmt;
   IfStmt *if_stmt;
   BreakStmt *break_stmt;
   WhileStmt *while_stmt;
   SwitchStmt *switch_stmt;

   Exp  * exp;
}

%token <name> ID
%token <fval> FNUM
%token <ival> INUM
%token <op> ADDOP MULOP RELOP BT BE LT LE EQ NE 
			MINUS PLUS DIV MUL
			NOT AND OR  
%token <casts> CAST INT_TO_FLOAT FLOAT_TO_INT
%token	IF ELSE
%token	SWITCH CASE BREAK DEFAULT
%token	WHILE
%token	INPUT OUTPUT
%token	T_INT T_FLOAT

%type <types> type
%type <exp> expression factor term
%type <stmt> stmt 
%type <input_stmt> input_stmt
%type <output_stmt> output_stmt
%type <break_stmt> break_stmt
%type <assignment_stmt> assignment_stmt 
%type <stmt_block> stmtlist caselist stmt_block 
%type <prog_store> declarations
%type <idLstPtr> idlist
%type <while_stmt> while_stmt
%type <if_stmt>  if_stmt
%type <switch_stmt> switch_stmt
%type <exp> boolexpr boolfactor boolterm

%left PLUS MINUS
%left MUL DIV

%%

program: declarations stmt_block 			
	{ toQuad($2);};

declarations: declarations declaration 		{ }
			| 								{    my_store = new Store();};

declaration: idlist ':' type ';'			
{ 
	if(!my_store->addAll(*($1),($3 == T_INT)))
		yyerror("define more then one variable with the same name is not allowed");
};

type: T_INT									{ $$ = T_INT;}
	| T_FLOAT								{ $$ = T_FLOAT;};

idlist: idlist ',' ID
{	
	$1->push_back($3);
	$$ = $1;
}
| ID
{ 
	$$ = new std::list<std::string>();
	$$->push_back($1);
};

stmt: assignment_stmt 						{ $$ = $1;}
	| input_stmt						  	{ $$ = $1;}
	| output_stmt						  	{ $$ = $1;}
	| if_stmt								{ $$ = $1;}
	| while_stmt							{ $$ = $1;}
	| switch_stmt						  	{ $$ = $1;}
	| break_stmt							{ $$ = $1;}
	| stmt_block 							{ $$ = $1;}
;

assignment_stmt: ID '=' expression ';'		
{ 	
	IdNode * idn = my_store->get($1);
	if(idn == nullptr){
		yyerror(" error: the id, " + std::string($1) + "is not defined.");
		$$ = new AssignStmt (new IdNode(std::string($1),TYPE_INT), $3);
	}else{
		if(idn->type == TYPE_INT && $3->type == TYPE_FLOAT)
			yyerror(" error: can not assign id, "+ idn->_name + ", of type: " + idn->type + ", a value of type: " + $3->type);
		$$ = new AssignStmt (idn, $3);
	}
};

input_stmt: INPUT '(' ID ')' ';'			
{ 
	IdNode * idn = my_store->get($3);
	if(idn == nullptr){
		yyerror(" error: the id, " + std::string($3) + "is not defined.");
		$$ = new InputStmt(new IdNode($3,TYPE_INT));
	}else{
		$$ = new InputStmt(idn);
	}
};

output_stmt: OUTPUT '(' expression ')' ';'  
	{ $$ = new OutputStmt($3); };

if_stmt: IF '(' boolexpr ')' stmt ELSE stmt 				
{ 
	if(typeid(*($5)) == typeid(BreakStmt) || typeid(*($7)) == typeid(BreakStmt)){
		yyerror(" error: break statment allowed only in while,switch statment!");
	}
	if($3->type != TYPE_BOOL){
		yyerror(" error: excpect for bool at the condition, but recieved: " + $3->type);
	}
	$$ = new IfStmt ($3, $5, $7);
};

while_stmt: WHILE '(' boolexpr ')' stmt		
{ 
	if($3->type != TYPE_BOOL){
		yyerror(" error: excpect for bool at the while condition, but recieved: " + $3->type);
	}
	$$ = new WhileStmt ($3, $5); 
};

switch_stmt: SWITCH '(' expression ')' '{' caselist DEFAULT ':' stmtlist '}' 
{ 
	if($3->type == TYPE_FLOAT){
		yyerror(" error: excpect for integer at the switch expretion, but recieved float");
	}
	$$ = new SwitchStmt($3, $6, $9);
};
											
caselist: caselist CASE INUM ':' stmtlist    
{   
	$1->insert(new CaseStmt(new IntNode($3), $5));
	$$ = $1;
}
	| { $$ = new StmtBlock(NULL, NULL,true); }; //%empty

break_stmt: BREAK ';' { $$ = new BreakStmt();};

stmt_block: '{' stmtlist '}'	{ $$ = $2;};

stmtlist: stmtlist stmt			
 { 
	$1->insert($2);
	$$ = $1;
 }
 | 	 { $$ = new StmtBlock(NULL, NULL); }; //empty

boolexpr: boolexpr OR boolterm	
			{ $$ = new BoolOp(OR, $1, $3); }
		| boolterm  			{ $$ = $1;};
		
boolterm: boolterm AND boolfactor 
			{ $$ = new BoolOp(AND, $1, $3);}
		| boolfactor			
			{ $$ = $1;};
		
boolfactor: NOT '(' boolexpr ')'
			 { $$ = new OnaryOp($1, $3);}
		  | expression RELOP expression
			 { $$ = new NumOp($2, $1, $3);};
								
expression: expression ADDOP term 							
				{ $$ = new NumOp( $2, $1, $3); }
		  | term				
		  		{ $$ = $1;};
		  
term: term MULOP factor			
		{ $$ = new NumOp( $2, $1, $3); }
	| factor
		{ $$ = $1;};

factor: '(' expression ')'
	{ $$ = $2;}
 | CAST '(' expression ')'
	{ $$ = new CastExp($3, $1 == FLOAT_TO_INT);}
 | ID
	{   IdNode * idn = my_store->get($1);
		if(idn == nullptr) yyerror(" error: " + std::string($1) + " is not a recognized id.");
		$$ = idn;
	}
 | FNUM
	{ $$ = new FloatNode($1);}
 | INUM
	{ $$ = new IntNode($1);};

%%

int main (int argc, char **argv){
    extern FILE * yyin;
	const char * ETEN = "ou";
    if (argc != 2) {
        fprintf (stderr, "Usage: %s <input-file-name>.%s\n", argv[0],ETEN);
	    return 1;
    }
	std::string name, exten, fname = std::string(argv[1]);
	const size_t ETEN_LEN = 2, FNAME_SIZE = fname.size();
	name = fname.substr(0,FNAME_SIZE-ETEN_LEN-1);
	if((fname.substr(FNAME_SIZE-ETEN_LEN,ETEN_LEN)).compare(ETEN) != 0){
		fprintf (stderr, "Usage: %s <input-file-name>.%s\n", argv[0],ETEN);
	    return 1;
	}
	if(name.empty()){
		fprintf (stderr, "excpect to see a file name befor \'.%s\', in: %s\n", argv[1],ETEN);
		return 1;
	}
    yyin = fopen (argv [1], "r");
    if (yyin == NULL) {
        fprintf (stderr, "failed to open %s\n", argv[1]);
	    return 2;
    }
	
    int val = yyparse();
    fclose(yyin);
	
	name += ".qud";
	if(std::rename("test.qud",name.c_str()) == 0){
		std::cout << "The process complete" << std::endl;
	}
    return val;
}

#ifndef TEMPGEN_H
#define TEMPGEN_H 1
	namespace TmpGen{
		static int lblCnt;
		static int tmpCnt;
		static int linesCnt;

		std::string getLbl(){ return "#"+std::to_string(lblCnt);};

		std::string newLbl(){ return "#"+std::to_string(++lblCnt); };

		std::string getTmp(){ return "$"+std::to_string(tmpCnt);};

		std::string newTmp(){ return "$"+std::to_string(++tmpCnt); };

		int getLinesCnt(){ return TmpGen::linesCnt;};

		std::string simpleTemplete(std::string opName,std::string arg0="", std::string arg1="",std::string arg2=""){
			linesCnt++;
			return opName + " " + arg0 + " " + arg1 + " " + arg2 + "\n";
		}
	}
#endif



void toQuad(StmtBlock* ast){
	std::list<std::string> proglbls;
	std::string res;
	bool errFlg = false;
	try{
		res = ast->toQuad(proglbls,errFlg);
	}catch(std::exception & e){
		std::cerr << e.what() << std::endl;
		return;
	}
	res += TmpGen::simpleTemplete("HALT");
	if(errFlg){ return ;}
	std::ofstream out;
	out.open("test.qud",std::ios::out);
	out << res << std::endl;
	out.close();
}

void yyerror (std::string s){
  extern int yylineno;  
  fprintf (stderr, "line %d: %s\n", yylineno, s.c_str ());
}

std::string CastExp::toQuad(){
	std::string res = this->_tocast->toQuad();
	const std::string tmp = TmpGen::getTmp();
	if(!_toint) {
		if(this->_tocast->type != TYPE_FLOAT)
			res += TmpGen::simpleTemplete("ITOR",TmpGen::newTmp(),tmp);
	}else{
		res += (this->_tocast->type == TYPE_FLOAT ? TmpGen::simpleTemplete("RTOI",TmpGen::newTmp(),tmp) : "");
	}
	return res;
};

std::string OnaryOp::toQuad(){
	std::string res = _left->toQuad();
	std::string tmp = TmpGen::getTmp();
	return res + TmpGen::simpleTemplete("INQL",TmpGen::newTmp(),tmp,"1");
};

NumOp::NumOp (enum yytokentype op, Exp *left, Exp *right) {
	this->_op = op;
	this->_left = left;
	this->_right = right;
	if(BT <= _op && _op <= NE){
		this->type = TYPE_BOOL;
	}else if(MINUS <= _op && _op <= MUL){
		this->type = (_left->type == TYPE_INT && _right->type == TYPE_INT) ? TYPE_INT : TYPE_FLOAT;
	}else{
		this->type = "None";
		yyerror("bad operation. "+std::to_string(_op)+" " +std::to_string(BT));
	}
};

std::string NumOp::toQuad(){
	std::string res = "",prevRes,prefix,addition = "",ltmp,rtmp;
	const int len = 10;
	const char * opsNames[] = {"GRT","LSS","LSS","GRT","EQL","NQL","SUB","ADD","DIV","MLT"};
	prefix = (_left->type == TYPE_FLOAT || _right->type == TYPE_FLOAT) ? "R" : "I";
	prevRes = _left->toQuad();
	ltmp = TmpGen::getTmp();
	prevRes += _right->toQuad();
	rtmp = TmpGen::getTmp();
	if(_left->type == TYPE_INT && _right->type != TYPE_INT){
		addition = TmpGen::simpleTemplete("ITOR",TmpGen::newTmp(), ltmp);
		res = addition + res ;
		ltmp = TmpGen::getTmp();
	}else if(_right->type == TYPE_INT && _left->type != TYPE_INT){
		addition = TmpGen::simpleTemplete("ITOR",TmpGen::newTmp(), rtmp);
		res = addition + res;
		rtmp = TmpGen::getTmp();
	}
	const std::string tmp = TmpGen::newTmp();
	if(_op-BT >= len || _op < BT){std::cerr << "in numop: bad op"<<std::endl; throw std::exception();}
	res += TmpGen::simpleTemplete(prefix+opsNames[_op-BT],tmp,ltmp,rtmp);
	if(_op == LE || _op == BE) {
		res += TmpGen::simpleTemplete("IEQL",TmpGen::newTmp(),tmp,"0");
	}
	return  prevRes + res;
}

std::string BoolOp::toQuad(){
	std::string res,ltmp , rtmp , tmp;
	res = this->_left->toQuad();
	ltmp = TmpGen::getTmp();
	res += this->_right->toQuad();
	rtmp = TmpGen::getTmp();
	tmp = TmpGen::newTmp();
	if(this->_op == OR){
		res += TmpGen::simpleTemplete("IADD",tmp,ltmp,rtmp);
	}else if (_op == AND){ // AND operator
		res += TmpGen::simpleTemplete("IMLT",tmp,ltmp,rtmp);
	}else{
		std::cerr << "bad bool operation " + std::to_string(this->_op) << std::endl;
		//throw std::exception();//"Binary operation should be one of: \'AND\' , \'OR\'. \n");
	}
	return res + TmpGen::simpleTemplete("INQL",TmpGen::newTmp(),tmp,"0");
}

std::string WhileStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	int lines = TmpGen::getLinesCnt()+1;//##
	std::string body,res = _condition->toQuad(), jump,
				jmpz, jmpzlbl = TmpGen::newLbl(), tmp;
	tmp = TmpGen::getTmp();
	jmpz = TmpGen::simpleTemplete("JMPZ",jmpzlbl,tmp);
	body = this->_body->toQuad(lblQueue,hasErr);
	jump = TmpGen::simpleTemplete("JUMP",std::to_string(lines));
	std::string end = std::to_string(TmpGen::getLinesCnt()+1); // ##
	while(!lblQueue.empty()){ 
		body = replace(body, lblQueue.back(), end);
		lblQueue.pop_back();
	}
	return res + replace(jmpz,jmpzlbl,end) + body +  jump;
}

std::string IfStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	std::string thenS,elseS, res = _condition->toQuad(),tmp, jump,jmpz,jumplbl, jmpzlbl = TmpGen::newLbl();
	tmp = TmpGen::getTmp();
	bool thenEmpty = this->_thenStmt->empty(), elseEmpty = this->_elseStmt->empty();
	if(thenEmpty && elseEmpty){
		return res;
	}else if(thenEmpty){
		elseS = _elseStmt->toQuad(lblQueue,hasErr);
		return res + /*TmpGen::simpleTemplete("JUMP",std::to_string(TmpGen::getLinesCnt()+1)) +*/ elseS;
	}
	jmpz = TmpGen::simpleTemplete("JMPZ",jmpzlbl,tmp);
	thenS = _thenStmt->toQuad(lblQueue,hasErr);
	if(elseEmpty){
		return res + replace(jmpz,jmpzlbl,std::to_string(TmpGen::getLinesCnt()+1)) + thenS;
	}
	jumplbl = TmpGen::newLbl();
	jump = TmpGen::simpleTemplete("JUMP",jumplbl);
	res += replace(jmpz,jmpzlbl,std::to_string(TmpGen::getLinesCnt()+1)) + thenS;
	elseS = _elseStmt->toQuad(lblQueue,hasErr);
	if(!lblQueue.empty() && !this->_breakAllowed){
		hasErr = true;
		yyerror(" error: break statment allowed only in while block and in switch statment.");
	}
	return res + replace(jump,jumplbl,std::to_string(TmpGen::getLinesCnt()+1)) + elseS;
}

/*notice: if this SwitchStmt been init with StmtBlock who's contain a non-CaseStmt object, exceprion will raise*/
std::string SwitchStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	std::string numQuad , res , caseQuad , jmpz, jmpzLbl = "" , jump = "", jumpLbl = "", tmp;
	res = this->_switchExp->toQuad(); 
	const std::string condTmp = TmpGen::getTmp();
	Stmt * stmt = this->_cases->_first;
	CaseStmt * currCase;
	int lines;
	while (stmt != NULL){
		currCase = (CaseStmt *)stmt;
		numQuad = currCase->_nump->toQuad();
		tmp = TmpGen::getTmp();
		numQuad += TmpGen::simpleTemplete("IEQL",TmpGen::newTmp(),condTmp,tmp);
		jmpz = TmpGen::simpleTemplete("JMPZ", (jmpzLbl = TmpGen::newLbl()),TmpGen::getTmp());
		lines = TmpGen::getLinesCnt();
		caseQuad = currCase->toQuad(lblQueue,hasErr);
		if (!jump.empty()) {res += replace(jump,jumpLbl,std::to_string(lines+1));}
		jump = TmpGen::simpleTemplete("JUMP",(jumpLbl = TmpGen::newLbl()));
		res += numQuad + replace(jmpz,jmpzLbl,std::to_string(TmpGen::getLinesCnt()+1)) + caseQuad;// + jump;
		stmt = stmt->_next;
	}
	if (!jump.empty()) {res += replace(jump,jumpLbl,std::to_string(TmpGen::getLinesCnt()+1));}
	res += this->_default->toQuad(lblQueue,hasErr);
	while(!lblQueue.empty()){
		 res = replace(res,lblQueue.back(),std::to_string(TmpGen::getLinesCnt()+1));
		 lblQueue.pop_back();
	}
	return res; 
}


std::string CaseStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	return this->_stmts->toQuad(lblQueue,hasErr);
}

std::string BreakStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	std::string tmpLbl = TmpGen::newLbl();
	lblQueue.push_back(tmpLbl);
	return TmpGen::simpleTemplete("JUMP",tmpLbl);
}

std::string StmtBlock::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	Stmt * stmtP = this->_first;
	std::string res = "",lbl = "";
	bool breaked = false;
	while (stmtP != NULL){
		stmtP->_breakAllowed = this->_breakAllowed;
		res += stmtP->toQuad(lblQueue,hasErr);
		if(typeid(stmtP) == typeid(BreakStmt)){
			if(this->_breakAllowed == false){
				yyerror(" error: break statment allowed only in while block and in switch statment.");
				hasErr = true;
			}
			breaked = true;
			stmtP = NULL;
		}
		stmtP = stmtP->_next;
	}
	/*if(breaked){ 
		std::string replacedRes = replace(res, lbl, std::to_string(TmpGen::getLinesCnt()+1));
		if(!replacedRes.empty()){ res = replacedRes;}
	}*/
	return res;
}


std::string AssignStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	std::string tmp , res = this->_rhs->toQuad(), prefix = "I";
	tmp = TmpGen::getTmp();
	bool needCasting = false , toFloat = false;
	if(this->_id->type == TYPE_FLOAT){
		prefix = "R";
		needCasting = toFloat = (this->_rhs->type != TYPE_FLOAT);
	} else if ((this->_rhs->type).compare(TYPE_FLOAT) == 0){
		// id is int but the right hand expression is float, this is not allowed.
		// one should cast the right hand expression befor the assignment
		throw std::exception();//"failed to assign value to the id: " + this->_id->val());
	}

	if (needCasting){
		std::string opName = toFloat ? "ITOR" : "RTOI";
		res += TmpGen::simpleTemplete(opName,TmpGen::newTmp(),tmp);
		tmp = TmpGen::getTmp();
	}
	return res + TmpGen::simpleTemplete(prefix + "ASN",this->_id->val(),tmp);
}

std::string InputStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	return ((this->id->type == TYPE_FLOAT) ? "R" : "I") + TmpGen::simpleTemplete("INP",this->id->val());
};

std::string OutputStmt::toQuad(std::list<std::string> & lblQueue,bool & hasErr){
	std::string res = this->outExp->toQuad();
	return res + ((this->outExp->type == TYPE_FLOAT) ? "R" : "I") + TmpGen::simpleTemplete("PRT",TmpGen::getTmp());
};

std::string IntNode::toQuad(){
	return TmpGen::simpleTemplete("IASN",TmpGen::newTmp(),std::to_string(this->val()));
};

std::string FloatNode::toQuad(){
	return TmpGen::simpleTemplete("RASN",TmpGen::newTmp(),std::to_string(this->val()));
};

std::string IdNode::toQuad(){
	std::string prefix,res;
	prefix = this->type == TYPE_INT ? "I" : "R";
	return TmpGen::simpleTemplete(prefix+"ASN",TmpGen::newTmp(),this->val());
};

std::string replace(std::string str,std::string key,std::string newkey){
	std::size_t found = str.rfind(key);
	if (found == std::string::npos)
		return str;
	str.replace(found,key.length(),newkey);
	return str;
}