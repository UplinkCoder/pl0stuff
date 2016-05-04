import std.algorithm;
import std.array;
import std.range;
import pl0_extended_ast;
import pl0_extended_analyzer;
import ast_modifier;

const(char)[] indentBy(const char[] str, const int indentLevel) pure {
	char[] indent;
	if (!__ctfe)indent.reserve(str.length + indentLevel);
	foreach(t;0..indentLevel) {
		indent ~= "\t";
	}
	return indent ~ str;
}


enum TargetLanguage {
	C,
	D
}

string genCode(const Programm p, const bool omitMain = false, const TargetLanguage targetLanguage = TargetLanguage.C) pure {
	
	struct CodeGen {	
	pure :
		Appender!(const (char)[]) output;
		//const (char)[] output;
		uint iLvl;
		
		void genCode(const Programm _p) {
			output ~= "/*************************/\n";
			output ~= "/***** Uplink Coders *****/\n";
			output ~= "/******* PL/0 to C *******/\n";
			output ~= "/******* Compiler ********/\n";
			output ~= "/*************************/\n";
			
			if (targetLanguage == TargetLanguage.C) 
				output ~= "#include <stdio.h> // for printf\n\n";
			if (targetLanguage == TargetLanguage.D)
				output ~= "\nimport core.stdc.stdio : printf;\n\n";
			if (p.block.variables || p.block.constants) {
				output ~= "/*************************/\n";
				output ~= "/******* Globals *********/\n";
				output ~= "/*************************/\n";
			 
				genCode(p.block.constants);
				genCode(p.block.variables);
			
				//p.block.constants = [];
				//p.block.variables = [];
			}
			if (p.block.procedures) {
				output ~= "/*************************/\n";
				output ~= "/****** Procedures *******/\n";
				output ~= "/*************************/\n";
				genCode(p.block.procedures);
			}
			
			if (!omitMain) {
				output ~= "/*************************/\n";
				output ~= "/***** main function *****/\n";
				output ~= "/*************************/\n";
				if (targetLanguage == TargetLanguage.D) {
					output ~= q{	void plMain() } ~ "{\n";
					iLvl++;
				} else {
					output ~= "void main() ";
				}
				
				genCode(p.block.statement);
				
				if (targetLanguage == TargetLanguage.D) {
					output ~= "}".indentBy(--iLvl); 
				}
			}
		}
		
		void genCode(const VarDecl[] vars) {
			foreach(v;vars) {
				output ~= "int ".indentBy(iLvl) ~ (targetLanguage == TargetLanguage.D ?	 "_GLOBAL_" : "") ~  v.name.identifier;
				if (v._init) {
					output ~= " = ";
					genCode(v._init);
				}
				output ~= ";\n";
			}
		}
		
		void genCode(const ConstDecl[] consts) {
			foreach(c;consts) {
				output ~= "const int ".indentBy(iLvl) ~ (targetLanguage == TargetLanguage.D ?	 "_GLOBAL_" : "") ~ c.name.identifier;
				if (c._init) {
					output ~= " = ";
					genCode(c._init);
				}
				output ~= ";\n";
			}
		}
		
		void genCode(const ProDecl[] procedures) {
			foreach(p;procedures) {
				output ~= "void ".indentBy(iLvl) ~ p.name.identifier ~ "(";
				if (p.arguments) {
					foreach(arg;p.arguments[0 .. $]) {
						output ~= "int " ~ arg.name.identifier ~ ", ";
					}
					output ~= "int " ~ p.arguments[$-1].name.identifier;
				}
				output ~= ") {\n";
				iLvl++;
				genCode(p.block);
				output ~= "}\n".indentBy(--iLvl);
			}
		}
		
		void genCode(const Block b) {
			
			output ~= "{\n".indentBy(iLvl++);
			genCode(b.variables);
			genCode(b.constants);
			
			
			genCode(b.statement);
			output ~= "return ;\n".indentBy(iLvl) ~ "}\n".indentBy(iLvl-1);
			iLvl--;
		}
		
		void genCode(const Statement _p) {
			if(auto _g = cast(AssignmentStatement) _p) {
				genCode(_g);
			} else if(auto _g = cast(BeginEndStatement) _p) {
				genCode(_g);
			} else if(auto _g = cast(IfStatement) _p) {
				genCode(_g);
			} else if(auto _g = cast(WhileStatement) _p) {
				genCode(_g);
			} else if(auto _g = cast(CallStatement) _p) {
				genCode(_g);
			} else if(auto _g = cast(OutputStatement) _p) {
				genCode(_g);
			}
		}
		
		void genCode(const BeginEndStatement bes) {
			output ~= "{\n".indentBy(iLvl++);
			foreach(ref stmt;bes.statements) {
				genCode(stmt);
			}
			output ~= "}\n".indentBy(--iLvl);
		}
		
		void genCode(const AssignmentStatement as) {
			output ~= (targetLanguage == TargetLanguage.D ? "_GLOBAL_": "").indentBy(iLvl) ~ as.name.identifier ~ " = ";
			genCode(as.expr);		
			output ~= ";\n";
		}
		
		void genCode(const IfStatement ifs) {
			output ~= "if (".indentBy(iLvl);
			genCode(ifs.cond);
			output ~= ")\n";
			genCode(ifs.stmt);
		}
		
		
		void genCode(const WhileStatement ws) {
			output ~= "while (".indentBy(iLvl);
			genCode(ws.cond);
			output ~= ")\n";
			genCode(ws.stmt);
		}
		
		void genCode(const CallStatement cs) {
			output ~= cs.name.identifier.indentBy(iLvl) ~ "(";
			if (cs.arguments) {
				foreach(arg;cs.arguments[0 .. $]) {
					genCode(arg);
					output ~= ", ";
				}
				genCode(cs.arguments[$-1]);
			}
			output ~= ");\n";
		}
		
		void genCode(const OutputStatement os) {
			output ~= `printf("%d\n",`.indentBy(iLvl);
			genCode(os.expr);		
			output ~= ");\n";
		}
		
		void genCode(const Condition _p) {
			if(auto _g = cast(OddCondition) _p) {
				genCode(_g);
			} else if(auto _g = cast(RelCondition) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(const Expression _p) {
			if(auto _g = cast(AddExprssion) _p) {
				genCode(_g);
			} else if(auto _g = cast(MulExpression) _p) {
				genCode(_g);
			} else if(auto _g = cast(ParenExpression) _p) {
				genCode(_g);
			} else if(auto _g = cast(PrimaryExpression) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(const RelOp _p) {
			if(auto _g = cast(Equals) _p) {
				genCode(_g);
			} else if(auto _g = cast(Greater) _p) {
				genCode(_g);
			} else if(auto _g = cast(Less) _p) {
				genCode(_g);
			} else if(auto _g = cast(GreaterEq) _p) {
				genCode(_g);
			} else if(auto _g = cast(LessEq) _p) {
				genCode(_g);
			} else if(auto _g = cast(Hash) _p) {
				genCode(_g);
			}
		}
		
		void genCode(const AddOp _p) {
			if(auto _g = cast(Add) _p) {
				genCode(_g);
			} else if(auto _g = cast(Sub) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(const MulOp _p) {
			if(auto _g = cast(Mul) _p) {
				genCode(_g);
			} else if(auto _g = cast(Div) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(const RelCondition g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}

		void genCode(const OddCondition c) {
			genCode(c.expr);
			output ~= "&1";
		}
		
		
		void genCode(const Equals g) {
			output ~= "==";
		}
		
		
		void genCode(const Greater g) {
			output ~= ">";
		}
		
		
		void genCode(const Less g) {
			output ~= "<";
		}
		
		
		void genCode(const GreaterEq g) {
			output ~= ">=";
		}
		
		
		void genCode(const LessEq g) {
			output ~= "<=";
		}
		
		
		void genCode(const Hash g) {
			output ~= "!=";
		}
		
		
		void genCode(const Add g) {
			output ~= "+";
		}
		
		
		void genCode(const Sub g) {
			output ~= "-";
		}
		
		
		void genCode(const Mul g) {
			output ~= "*";
		}
		
		
		void genCode(const Div g) {
			output ~= "/";
		}
		
		
		void genCode(const AddExprssion g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}
		
		
		void genCode(const MulExpression g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}
		
		
		void genCode(const ParenExpression g) {
			output ~= "(";
			genCode(g.expr);
			output ~= ")";
		}
		
		
		void genCode(const PrimaryExpression g) {
			if (g.isNegative) {
				output ~= "-";
			}
			if (g.literal) {
				output ~= g.literal.intp.number;
			} else if (g.identifier) {
				output ~= (targetLanguage == TargetLanguage.D ? "_GLOBAL_" : "") ~ g.identifier.identifier;
			} else if (g.paren) {
				genCode(g.paren);
			}
		}
		
		
		
		
		
	}
	auto cg = CodeGen();
	cg.genCode(p);
	return cast (string) cg.output.data;
	
}
