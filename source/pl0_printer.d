import pl0_ast;
import std.range;
string print(const Programm root) pure {
	
	struct Printer {
		Appender!(char[]) sink;

		void print(const char c) {
			sink.put([c]);
		}

		void print(const char[] s) {
			sink.put(s);
		}

		void print(PLNode _p) {
			if(auto _g = cast(Expression) _p) {
				return print(_g);
			} else if(auto _g = cast(MulOp) _p) {
				return print(_g);
			} else if(auto _g = cast(AddOp) _p) {
				return print(_g);
			} else if(auto _g = cast(RelOp) _p) {
				return print(_g);
			} else if(auto _g = cast(Condition) _p) {
				return print(_g);
			} else if(auto _g = cast(Statement) _p) {
				return print(_g);
			} else if(auto _g = cast(ProDecl) _p) {
				return print(_g);
			} else if(auto _g = cast(VarDecl) _p) {
				return print(_g);
			} else if(auto _g = cast(ConstDecl) _p) {
				return print(_g);
			} else if(auto _g = cast(Block) _p) {
				return print(_g);
			} else if(auto _g = cast(Programm) _p) {
				return print(_g);
			} else if(auto _g = cast(Number) _p) {
				return print(_g);
			} else if(auto _g = cast(Identifier) _p) {
				return print(_g);
			} 
		}

		void print(Statement _p) {
			if(auto _g = cast(AssignmentStatement) _p) {
				return print(_g);
			} else if(auto _g = cast(BeginEndStatement) _p) {
				return print(_g);
			} else if(auto _g = cast(IfStatement) _p) {
				return print(_g);
			} else if(auto _g = cast(WhileStatement) _p) {
				return print(_g);
			} else if(auto _g = cast(CallStatement) _p) {
				return print(_g);
			} 
		}

		void print(Condition _p) {
			if(auto _g = cast(OddCondition) _p) {
				return print(_g);
			} else if(auto _g = cast(RelCondition) _p) {
				return print(_g);
			} 
		}

		void print(RelOp _p) {
			if(auto _g = cast(Equals) _p) {
				return print(_g);
			} else if(auto _g = cast(Greater) _p) {
				return print(_g);
			} else if(auto _g = cast(Less) _p) {
				return print(_g);
			} else if(auto _g = cast(GreaterEq) _p) {
				return print(_g);
			} else if(auto _g = cast(LessEq) _p) {
				return print(_g);
			} else if(auto _g = cast(Hash) _p) {
				return print(_g);
			} 
		}

		void print(AddOp _p) {
			if(auto _g = cast(Add) _p) {
				return print(_g);
			} else if(auto _g = cast(Sub) _p) {
				return print(_g);
			} 
		}

		void print(MulOp _p) {
			if(auto _g = cast(Mul) _p) {
				return print(_g);
			} else if(auto _g = cast(Div) _p) {
				return print(_g);
			} 
		}

		void print(Expression _p) {
			if(auto _g = cast(AddExprssion) _p) {
				return print(_g);
			} else if(auto _g = cast(MulExpression) _p) {
				return print(_g);
			} else if(auto _g = cast(ParenExpression) _p) {
				return print(_g);
			} else if(auto _g = cast(PrimaryExpression) _p) {
				return print(_g);
			} 
		}

		void print(Identifier g) {
			sink.put(g.identifier);
			sink.put(" ");
		}


		void print(Number g) {
			sink.put(g.number);
			sink.put(" ");
		}


		void print(Programm g) {
			print(g.block);
			sink.put(" ");
			sink.put(".");
			sink.put(" ");
		}


		void print(Block g) {
			sink.put(" ");
			if (g.variables) {
				sink.put("VAR ");
				foreach(v;g.variables) {
					print(v);
					if (v !is g.variables[$-1]) sink.put(",");
				}
			}
			sink.put(" ");
			if (g.constants) {
				sink.put("CONST ");
				foreach(c;g.constants) {
					print(c);
					if (c !is g.constants[$-1]) sink.put(",");
				}
			}
			sink.put(" ");
			if (g.procedures) {
				sink.put("PROCEDURE \n");
				foreach(p;g.procedures) {
					print(p);
					if (p !is g.procedures[$-1]) sink.put(",");
				}
			}
			print(g.statement);
			sink.put(" ");
		}


		void print(ConstDecl g) {
			print(g.name);
			sink.put(" ");
			sink.put("=");
			sink.put(" ");
			print(g.number);
		}


		void print(VarDecl g) {
			print(g.name);
		}


		void print(ProDecl g) {
			print(g.name);
			sink.put(" ");
			sink.put(";");
			sink.put(" ");
			print(g.block);
			sink.put(" ");
			sink.put(";");
		}


		void print(AssignmentStatement g) {
			print(g.name);
			sink.put(" ");
			sink.put(":=");
			sink.put(" ");
			print(g.expr);
			sink.put(" ");
		}


		void print(BeginEndStatement g) {
			sink.put("BEGIN");
			sink.put(" ");
			foreach(_e;g.statements) {
				print(_e);
				print(";");
			}
			sink.put(" ");
			sink.put("END");
			sink.put(" ");
		}


		void print(IfStatement g) {
			sink.put("IF");
			sink.put(" ");
			print(g.cond);
			sink.put(" ");
			sink.put("THEN");
			sink.put(" ");
			print(g.stmt);
			sink.put(" ");
		}


		void print(WhileStatement g) {
			sink.put("WHILE");
			sink.put(" ");
			print(g.cond);
			sink.put(" ");
			sink.put("DO");
			sink.put(" ");
			print(g.stmt);
			sink.put(" ");
		}


		void print(CallStatement g) {
			sink.put("CALL");
			sink.put(" ");
			print(g.name);
			sink.put(" ");
		}


		void print(OddCondition g) {
			sink.put("ODD");
			sink.put(" ");
			print(g.expr);
			sink.put(" ");
		}


		void print(RelCondition g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
			sink.put(" ");
		}


		void print(Equals g) {
			sink.put("=");
			sink.put(" ");
		}


		void print(Greater g) {
			sink.put(">");
			sink.put(" ");
		}


		void print(Less g) {
			sink.put("<");
			sink.put(" ");
		}


		void print(GreaterEq g) {
			sink.put(">=");
			sink.put(" ");
		}


		void print(LessEq g) {
			sink.put("<=");
			sink.put(" ");
		}


		void print(Hash g) {
			sink.put("#");
			sink.put(" ");
		}


		void print(Add g) {
			sink.put("+");
			sink.put(" ");
		}


		void print(Sub g) {
			sink.put("-");
			sink.put(" ");
		}


		void print(Mul g) {
			sink.put("*");
			sink.put(" ");
		}


		void print(Div g) {
			sink.put("/");
			sink.put(" ");
		}


		void print(AddExprssion g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
			sink.put(" ");
		}


		void print(MulExpression g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
			sink.put(" ");
		}


		void print(ParenExpression g) {
			sink.put("(");
			sink.put(" ");
			print(g.expr);
			sink.put(" ");
			sink.put(")");
			sink.put(" ");
		}


		void print(PrimaryExpression g) {
			if (g.number) {
			print(g.number);
			}			if (g.identifier) {
			print(g.identifier);
			}			if (g.paren) {
			print(g.paren);
			}			sink.put(" ");
		}

	}
	auto ptr = Printer();
	ptr.print(cast(Programm)root);
	return cast(string)ptr.sink.data;
}

