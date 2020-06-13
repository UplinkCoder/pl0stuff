module bc_gen;

import std.algorithm;
import std.array;
import std.range;
import pl0_extended_ast;
import pl0_extended_analyzer;
import ast_modifier;
import ddmd.ctfe.bc_common;

enum RelopEnum
{
	Equals,
	Less,
	Greater,
	GreaterEq,
	LessEq,
	Hash,
}

enum invalidConst = long.min;

long getConst(PrimaryExpression pe)
{
	long result;
	if (pe.literal) {
		if (pe.literal.floatp)
			goto Linvalid;
		foreach_reverse(i,n;pe.literal.intp.number)
		{
			result *= 10;
			result += n;
		}
		result *= pe.isNegative ? -1 : 1;
	} else {
	Linvalid :
		result = invalidConst;
	}
}

auto genBC(BCGen)(const Programm p) pure {

	struct CodeGen {
		BCGen gen;
		alias gen this;
		BCValue[string] _vars;
	pure :
		void genBC(const Programm _p) {
				genBC(p.block.constants);
				genBC(p.block.variables);
				
			if (p.block.procedures) {
				genBC(p.block.procedures);
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
				
				genBC(p.block.statement);
				
				if (targetLanguage == TargetLanguage.D) {
					output ~= "}".indentBy(--iLvl); 
				}
			}
		}
		
		void genBC(const VarDecl[] vars) {
			foreach(v;vars) {
			_vars[v] = genTemporary(BCType(BCTypeEnum.i32));
				if (v._init) {
					output ~= " = ";
					genBC(v._init);
				}
				output ~= ";\n";
			}
		}
		
		void genBC(const ConstDecl[] consts) {
			foreach(c;consts) {
		//		output ~= "const int ".indentBy(iLvl) ~ (targetLanguage == TargetLanguage.D ?	 "_GLOBAL_" : "") ~ c.name.identifier;
				if (c._init) {
					auto v = getConst(c._init);
					if (v != invalidConst) {
						_vars[cast(string)c.name.identifier] = BCValue(Imm64(v));
					} else {
						assert(0, "currently only numeric constans are supported");
					}
				}
			}
		}
		
		void genBC(const ProDecl[] procedures) {
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
				genBC(p.block);
				output ~= "}\n".indentBy(--iLvl);
			}
		}
		
		void genBC(const Block b) {
			
			output ~= "{\n".indentBy(iLvl++);
			genBC(b.variables);
			genBC(b.constants);
			
			
			genBC(b.statement);
			output ~= "return ;\n".indentBy(iLvl) ~ "}\n".indentBy(iLvl-1);
			iLvl--;
		}
		
		void genBC(const Statement _p) {
			if(auto _g = cast(AssignmentStatement) _p) {
				genBC(_g);
			} else if(auto _g = cast(BeginEndStatement) _p) {
				genBC(_g);
			} else if(auto _g = cast(IfStatement) _p) {
				genBC(_g);
			} else if(auto _g = cast(WhileStatement) _p) {
				genBC(_g);
			} else if(auto _g = cast(CallStatement) _p) {
				genBC(_g);
			} else if(auto _g = cast(OutputStatement) _p) {
				genBC(_g);
			}
		}
		
		void genBC(const BeginEndStatement bes) {
			//TODO maybe we want a beginLabel here ?
			foreach(ref stmt;bes.statements) {
				genBC(stmt);
			}
			//TODO maybe we want an endLabel ?
		}
		
		void genBC(const AssignmentStatement as) {
			output ~= (targetLanguage == TargetLanguage.D ? "_GLOBAL_": "").indentBy(iLvl) ~ as.name.identifier ~ " = ";
			genBC(as.expr);		
			output ~= ";\n";
		}
		
		void genBC(const IfStatement ifs) {
			genBC(ifs.cond);
			auto ij = beginCndJmp();
			genBC(ifs.stmt);
			endCndJmp(genLabel());
		}
		
		
		void genBC(const WhileStatement ws) {
			auto Lcond = genLabel();
			genBC(ws.cond);
			auto ij = beginCndJmp();
			genBC(ifs.stmt);
			genJump(Lcond);
			endCndJmp(genLabel());
		}
		
		void genBC(const CallStatement cs) {
			output ~= cs.name.identifier.indentBy(iLvl) ~ "(";
			if (cs.arguments) {
				foreach(arg;cs.arguments[0 .. $]) {
					genBC(arg);
					output ~= ", ";
				}
				genBC(cs.arguments[$-1]);
			}
			output ~= ");\n";
		}
		
		void genBC(const OutputStatement os) {
			output ~= `printf("%d\n",`.indentBy(iLvl);
			genBC(os.expr);		
			output ~= ");\n";
		}
		
		void genBC(const Condition _p) {
			if(auto _g = cast(OddCondition) _p) {
				genBC(_g);
			} else if(auto _g = cast(RelCondition) _p) {
				genBC(_g);
			} 
		}
		
		void genBC(const Expression _p) {
			if(auto _g = cast(AddExprssion) _p) {
				genBC(_g);
			} else if(auto _g = cast(MulExpression) _p) {
				genBC(_g);
			} else if(auto _g = cast(ParenExpression) _p) {
				genBC(_g);
			} else if(auto _g = cast(PrimaryExpression) _p) {
				genBC(_g);
			} 
		}
		
		RelOpEnum toRelOpEnum(const RelOp _p) {
			if(auto _g = cast(Equals) _p) {
				return RelOpEnum.Equals;
			} else if(auto _g = cast(Greater) _p) {
				return RelOpEnum.Greater;
			} else if(auto _g = cast(Less) _p) {
				return RelOpEnum.Less;
			} else if(auto _g = cast(GreaterEq) _p) {
				return RelOpEnum.GreaterEq;
			} else if(auto _g = cast(LessEq) _p) {
				return RelOpEnum.LessEq;
			} else if(auto _g = cast(Hash) _p) {
				return RelOpEnum.Hash;
			}
		}
		
		void genBC(const AddOp _p) {
			if(auto _g = cast(Add) _p) {
				genBC(_g);
			} else if(auto _g = cast(Sub) _p) {
				genBC(_g);
			} 
		}
		
		void genBC(const MulOp _p) {
			if(auto _g = cast(Mul) _p) {
				genBC(_g);
			} else if(auto _g = cast(Div) _p) {
				genBC(_g);
			} 
		}
		
		void genBC(const RelCondition g) {
			BCValue lhs = toBCValue(g.lhs);
			BCValue rhs = toBCValue(g.rhs);

			final switch(toRelOpEnum(g.op))
			{
				case RelopEnum.Equals :
				{
					Eq3(BCValue.init, lhs, rhs);
				} break;
				case RelopEnum.Greater :
				{
					Gt3(BCValue.init, lhs, rhs);
				} break;
				case RelopEnum.Less :
				{
					Lt3(BCValue.init, lhs, rhs);
				} break;
				case RelopEnum.GreaterEq :
				{
					Ge3(BCValue.init, lhs, rhs);
				} break;
				case RelopEnum.LessEq :
				{
					Le3(BCValue.init, lhs, rhs);
				} break;
				case RelopEnum.Hash :
				{
					Neq3(BCValue.init, lhs, rhs);
				} break;
			}
		}
		
		void genBC(const OddCondition c) {
			genBC(c.expr);
			output ~= "&1";
		}

		void genBC(const Add g) {
			output ~= "+";
		}
		
		
		void genBC(const Sub g) {
			output ~= "-";
		}
		
		
		void genBC(const Mul g) {
			output ~= "*";
		}
		
		
		void genBC(const Div g) {
			output ~= "/";
		}
		
		
		void genBC(const AddExprssion g) {
			genBC(g.lhs);
			output ~= " ";
			genBC(g.op);
			output ~= " ";
			genBC(g.rhs);
		}
		
		
		void genBC(const MulExpression g) {
			genBC(g.lhs);
			output ~= " ";
			genBC(g.op);
			output ~= " ";
			genBC(g.rhs);
		}
		
		
		void genBC(const ParenExpression g) {
			output ~= "(";
			genBC(g.expr);
			output ~= ")";
		}
		
		
		void genBC(const PrimaryExpression g) {
			if (g.isNegative) {
				output ~= "-";
			}
			if (g.literal) {
				output ~= g.literal.intp.number;
			} else if (g.identifier) {
				output ~= (targetLanguage == TargetLanguage.D ? "_GLOBAL_" : "") ~ g.identifier.identifier;
			} else if (g.paren) {
				genBC(g.paren);
			}
		}
	}
	auto cg = CodeGen();
	cg.genBC(p);
	return cast (string) cg.output.data;
	
}
