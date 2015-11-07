import std.algorithm;
import std.array;
import std.range;
import pl0_extended_ast;
import pl0_extended_analyzer;
import ast_modifier;

const(char)[] indentBy(const char[] str, const int indentLevel) pure {
	char[] indent;
	indent.reserve(str.length + indentLevel);
	foreach(t;0..indentLevel) {
		indent ~= "\t";
	}
	return indent ~ str;
}


string genCode(Programm p) {
	
	struct CodeGen {	
	pure :
		Appender!(const (char)[]) output;
		//const (char)[] output;
		uint iLvl;
		
		void genCode(Programm p) {
			output ~= "/*************************/\n";
			output ~= "/***** Uplink Coders *****/\n";
			output ~= "/******* PL/0 to C *******/\n";
			output ~= "/******* Compiler ********/\n";
			output ~= "/*************************/\n";
			
			output ~= "#include <stdio.h> // for printf\n\n";
			if (p.block.variables || p.block.constants) {
				output ~= "/*************************/\n";
				output ~= "/******* Globals *********/\n";
				output ~= "/*************************/\n";
				
				genCode(p.block.constants);
				genCode(p.block.variables);
				p.block.constants = [];
				p.block.variables = [];
			}
			if (p.block.procedures) {
				genCode(p.block.procedures);
				
				output ~= "/*************************/\n";
				output ~= "/****** Procedures *******/\n";
				output ~= "/*************************/\n";
			}
			
			
			output ~= "/*************************/\n";
			output ~= "/***** main function *****/\n";
			output ~= "/*************************/\n";
			output ~= "void main() ";
			
			genCode(p.block);
		}
		
		void genCode(VarDecl[] vars) {
			foreach(v;vars) {
				output ~= "int ".indentBy(iLvl) ~ v.name.identifier;
				if (v._init) {
					output ~= " = ";
					genCode(v._init);
				}
				output ~= ";\n";
			}
		}
		
		void genCode(ConstDecl[] consts) {
			foreach(c;consts) {
				output ~= "const int ".indentBy(iLvl) ~ c.name.identifier;
				if (c._init) {
					output ~= " = ";
					genCode(c._init);
				}
				output ~= ";\n";
			}
		}
		
		void genCode (ProDecl[] procedures) {
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
		
		void genCode(Block b) {
			
			output ~= "{\n".indentBy(iLvl++);
			genCode(b.variables);
			genCode(b.constants);
			
			
			genCode(b.statement);
			output ~= "return ;\n".indentBy(iLvl) ~ "}\n".indentBy(iLvl-1);
			iLvl--;
		}
		
		void genCode(Statement _p) {
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
		
		void genCode(BeginEndStatement bes) {
			output ~= "{\n".indentBy(iLvl++);
			foreach(ref stmt;bes.statements) {
				genCode(stmt);
			}
			output ~= "}\n".indentBy(--iLvl);
		}
		
		void genCode(AssignmentStatement as) {
			output ~= as.name.identifier.indentBy(iLvl) ~ " = ";
			genCode(as.expr);		
			output ~= ";\n";
		}
		
		void genCode(IfStatement ifs) {
			output ~= "if (".indentBy(iLvl);
			genCode(ifs.cond);
			output ~= ")\n";
			genCode(ifs.stmt);
		}
		
		
		void genCode(WhileStatement ws) {
			output ~= "while (".indentBy(iLvl);
			genCode(ws.cond);
			output ~= ")\n";
			genCode(ws.stmt);
		}
		
		void genCode(CallStatement cs) {
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
		
		void genCode(OutputStatement os) {
			output ~= `printf("%d\n",`.indentBy(iLvl);
			genCode(os.expr);		
			output ~= ");\n";
		}
		
		void genCode(Condition _p) {
			if(auto _g = cast(OddCondition) _p) {
				genCode(_g);
			} else if(auto _g = cast(RelCondition) _p) {
				genCode(_g);
			} 
		}
		
		void genCode (Expression _p) {
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
		
		void genCode(RelOp _p) {
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
		
		void genCode(AddOp _p) {
			if(auto _g = cast(Add) _p) {
				genCode(_g);
			} else if(auto _g = cast(Sub) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(MulOp _p) {
			if(auto _g = cast(Mul) _p) {
				genCode(_g);
			} else if(auto _g = cast(Div) _p) {
				genCode(_g);
			} 
		}
		
		void genCode(RelCondition g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}

		void genCode(OddCondition c) {
			genCode(c.expr);
			output ~= "&1";
		}
		
		
		void genCode(Equals g) {
			output ~= "==";
		}
		
		
		void genCode(Greater g) {
			output ~= ">";
		}
		
		
		void genCode(Less g) {
			output ~= "<";
		}
		
		
		void genCode(GreaterEq g) {
			output ~= ">=";
		}
		
		
		void genCode(LessEq g) {
			output ~= "<=";
		}
		
		
		void genCode(Hash g) {
			output ~= "!=";
		}
		
		
		void genCode(Add g) {
			output ~= "+";
		}
		
		
		void genCode(Sub g) {
			output ~= "-";
		}
		
		
		void genCode(Mul g) {
			output ~= "*";
		}
		
		
		void genCode(Div g) {
			output ~= "/";
		}
		
		
		void genCode(AddExprssion g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}
		
		
		void genCode(MulExpression g) {
			genCode(g.lhs);
			output ~= " ";
			genCode(g.op);
			output ~= " ";
			genCode(g.rhs);
		}
		
		
		void genCode(ParenExpression g) {
			output ~= "(";
			genCode(g.expr);
			output ~= ")";
		}
		
		
		void genCode(PrimaryExpression g) {
			if (g.isNegative) {
				output ~= "-";
			}
			if (g.literal) {
				output ~= g.literal.intp.number;
			} else if (g.identifier) {
				output ~= g.identifier.identifier;
			} else if (g.paren) {
				genCode(g.paren);
			}
		}
		
		
		
		
		
	}
	auto cg = CodeGen();
	cg.genCode(p);
	return cast (string) cg.output.data;
	
}
