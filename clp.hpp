#ifndef __CLP_H
#define __CLP_H 1
	#include <iostream>
	#include <fstream>
	#include <list>
	#include <string>
	#include <string.h>
	#include <algorithm>
	#include "token.hpp"

	#define TYPE_INT "int"
	#define TYPE_FLOAT "float"
	#define TYPE_BOOL "bool"

	extern void yyerror(std::string s);

	std::string replace(std::string str,std::string key,std::string newkey);

	// all nodes  in the AST (Abstract Syntax Tree) are of types derived from ASTnode 
	class ASTnode {};
	
	class Store;

	// expressions 

	// this is an abstract class
	class Exp : public  ASTnode {
		public:
			// every subclass should
			// override this (or be abstract too)
			virtual std::string toQuad() = 0;
			
			std::string type;

			Exp(std::string expType = "None") : type(expType) {};	
	};
	
	class CastExp : public Exp {
		public:
			Exp * _tocast;
			bool _toint;

			CastExp(Exp * tocast, bool toint=false) : Exp() {
				this->_tocast = tocast; 
				this->_toint = toint;
				type = this->_toint ? TYPE_INT : TYPE_FLOAT; 
			};

			std::string toQuad(); 
	};

	class OnaryOp : public Exp {
		public:
			enum yytokentype _op;
			Exp *_left;
			
			OnaryOp(enum yytokentype op, Exp *left) : Exp(TYPE_BOOL){ 
				this->_op = op;
				this->_left = left;
			};

			std::string toQuad();
	};


	class BinaryOp : public Exp { 
		public:
			//enum op _op;
			enum yytokentype _op;
			Exp *_left; // left operand
			Exp *_right; // right operand
			
			virtual std::string toQuad() = 0;
	};

	class NumOp : public BinaryOp {
		public:
			NumOp (enum yytokentype op, Exp *left, Exp *right) ;

			std::string toQuad();
	};

	class BoolOp : public BinaryOp {
		public:
			BoolOp (enum yytokentype op, Exp *left, Exp *right) {
				this->_op = op;
				this->_left = left;
				this->_right = right; 
				if(this->_left->type != TYPE_BOOL || this->_right->type != TYPE_BOOL){
					yyerror(" error: expect to see bool in this operation. ");
				}
				this->type = TYPE_BOOL;
			};
			
			std::string toQuad();
	};
	
	// this is an abstract class
	class NumNode : public Exp {
		public:
			virtual std::string toQuad() = 0;
	};

	class IntNode : public NumNode {
		public:
			int _val;
			
			IntNode (const int val) { 
				this->_val = val;
				this->type = TYPE_INT;
			};
			
			auto val() {return this->_val;};
			std::string toQuad();
	};

	class FloatNode : public NumNode {
		public:
			float _val;
			
			FloatNode (float val) { 
				this->_val = val;
				this->type = TYPE_FLOAT;
			};
			auto val() {return this->_val;};
			std::string toQuad();
	};

	class BoolNode : public IntNode {
		public:
			BoolNode(bool istrue) : IntNode((istrue ? 1 : 0)){ this->type = TYPE_BOOL;}
			auto val() {return (this->_val != 0) ? 1 : 0;};
	};

	class IdNode : public Exp {
		public:
			std::string _name;

			IdNode (std::string name,std::string type) : Exp(type) { this->_name = std::string(name);};
			
			std::string toQuad();

			bool operator==(IdNode & other){
				return this->_name.compare(other._name) == 0;
			};

			auto val() {return this->_name;}
	};

		 // statements
	// this is an abstract class
	class Stmt: public ASTnode {
		public:
		    Stmt () {this->_next = NULL; this->_breakAllowed = false;};
		   
		   // every subclass should override this (or be abstract too)
			virtual std::string toQuad(std::list<std::string> &,bool &) = 0;
			virtual bool empty(){ return false;};

			bool _breakAllowed;
		    Stmt *_next;  // used to link together statements in the same block
	};


	class AssignStmt : public Stmt {
	public:
		IdNode * _id; // left hand side
		Exp *_rhs; // right hand side
		AssignStmt (IdNode * id, Exp *rhs) : Stmt(), _rhs(rhs), _id(id) {};

		std::string toQuad(std::list<std::string> &,bool &);
	};
	
	class StmtBlock : public Stmt {
		public:
			Stmt *_first, *_last;
			std::string _type;

			StmtBlock(Stmt *first, Stmt *last,bool breakAllowed=false) 
			: Stmt() , _first (first) , _last (last) {this->_breakAllowed = breakAllowed;};
			
			std::string toQuad(std::list<std::string> & ,bool &);
			void insert(Stmt* stmt){
				if (this->_first == NULL) { 
					this->_first = this->_last = stmt; 
				}else {  
					this->_last->_next = stmt; 
					this->_last = stmt; 
				}
			}
			bool empty(){ return this->_first == NULL; };
	};
	
	class BreakStmt : public Stmt{
		public:
		BreakStmt() : Stmt() {};
		std::string toQuad(std::list<std::string> & ,bool &);
	};

	class InputStmt : public Stmt {
		public:
			IdNode * id;

			InputStmt(IdNode * id) : Stmt() { this->id = id;};

			std::string toQuad(std::list<std::string> &,bool &);
	};

	class OutputStmt : public Stmt {
		public:
			Exp * outExp;

			OutputStmt(Exp * outexp) : Stmt() { this->outExp = outexp;};

			std::string toQuad(std::list<std::string> &,bool &);
	};

	class CaseStmt: public Stmt {
		public:
			Exp *_nump;
			StmtBlock * _stmts;
		
			CaseStmt (Exp *numnode,StmtBlock *stmts) : Stmt() {
				this->_nump = numnode;
				this->_stmts = stmts;
				this->_stmts->_breakAllowed = this->_breakAllowed = true;
			};
			std::string toQuad(std::list<std::string> & ,bool &);
			bool empty(){ return this->_stmts->empty(); };
	};
	
	class SwitchStmt: public Stmt {
		public:
			Exp *_switchExp;
			StmtBlock *_cases;
			StmtBlock *_default;
		
			SwitchStmt (Exp * switchExp, StmtBlock * cases, StmtBlock * defaultStmts)
			: Stmt() {
				this->_switchExp = switchExp;
				this->_cases = cases;
				this->_default = defaultStmts;
				this->_breakAllowed = true;
			};
			std::string toQuad(std::list<std::string> &,bool &);
			bool empty(){ return this->_cases->empty() && this->_default->empty(); };
	};


	class WhileStmt: public Stmt {
	public: 
		WhileStmt (Exp *condition, Stmt *stmt) 
		 : Stmt () {
			this->_condition = condition;
			this->_body = stmt; 
			this->_breakAllowed = this->_body->_breakAllowed = true;
		};

		std::string toQuad(std::list<std::string> &,bool &);
		bool empty(){ return this->_body->empty(); };
		
		Stmt * _body; // points to first stmt of linked list of 'Stmt's
		Exp *_condition;
	};
	  
	class IfStmt : public Stmt {
	public:
		IfStmt (Exp *condition, Stmt *thenStmt, Stmt *elseStmt)
				: Stmt ()
				{ this->_condition = condition;
				  this->_thenStmt = thenStmt;
				  this->_elseStmt = elseStmt;
				  this->_breakAllowed = false; };

		std::string toQuad(std::list<std::string> &,bool &);

		Exp *_condition;
		Stmt *_thenStmt; 
		Stmt *_elseStmt; 
		bool empty(){ return this->_thenStmt->empty() && this->_elseStmt->empty(); };
	};

	

	class Store {
		private:
			std::list<IdNode*> _ids;
		public:			
			Store() : _ids() {}

			bool exist(const std::string& str){
				return this->get(str) != nullptr;
			}
			IdNode * get(std::string name){
				for(auto * id : this->_ids){
					if(name.compare(id->_name) == 0) return id;
				}
				return nullptr;
			}
			bool add(std::string toAdd,bool isInt){
				if(this->exist(toAdd)){
					return false;
				}
				this->_ids.push_back(new IdNode(toAdd,isInt ? TYPE_INT : TYPE_FLOAT));
				return true;
			}

			bool addAll(std::list<std::string> toAdd,bool isInt){
				bool res = true;
				for(auto a : toAdd){
					if(!this->add(a,isInt)) res = false;
				}
				return res;
			}

	};

	void toQuad(StmtBlock*);
#endif 