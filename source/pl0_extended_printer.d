import pl0_extended_ast;
import std.array;

const(char)[] indentBy(const char[] str, const int indentLevel) pure {
	char[] indent;
	//indent.reserve(5);
	foreach(t;0..indentLevel) {
		indent ~= "\t";
	}
	return indent ~ str;
}

//printer_boilerplate
string print(const PLNode root) pure {
	
	struct Printer {
		Appender!(char[]) sink;
		uint iLvl;
		bool newlineAfterStatement = true;
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
			} else if(auto _g = cast(Declaration) _p) {
				return print(_g);
			} else if(auto _g = cast(Statement) _p) {
				return print(_g);
			} else if(auto _g = cast(Block) _p) {
				return print(_g);
			} else if(auto _g = cast(Programm) _p) {
				return print(_g);
			} else if(auto _g = cast(Literal) _p) {
				return print(_g);
			} else if(auto _g = cast(Number) _p) {
				return print(_g);
			} else if(auto _g = cast(Identifier) _p) {
				return print(_g);
			} 
		}

		void print(Declaration _p) {
			if(auto _g = cast(ConstDecl) _p) {
				return print(_g);
			} else if(auto _g = cast(VarDecl) _p) {
				return print(_g);
			} else if(auto _g = cast(ProDecl) _p) {
				return print(_g);
			} 
		}

		void print(Statement _p) {
			sink.put("\n");
			sink.put("".indentBy(iLvl));

			if(auto _g = cast(AssignmentStatement) _p) {
				print(_g);
			} else if(auto _g = cast(BeginEndStatement) _p) {
				print(_g);
			} else if(auto _g = cast(IfStatement) _p) {
				print(_g);
			} else if(auto _g = cast(WhileStatement) _p) {
				print(_g);
			} else if(auto _g = cast(CallStatement) _p) {
				print(_g);
			} else if(auto _g = cast(OutputStatement) _p) {
				print(_g);
			}
			if (newlineAfterStatement) sink.put("\n");
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
		}


		void print(Number g) {
			sink.put(g.number);
		}


		void print(Literal g) {
			print(g.intp);
			if (g.floatp) {
				sink.put(".");
				print(g.floatp);
			}
		}


		void print(Programm g) {
			sink.put("\n");
			print(g.block);
			sink.put("\n");
			sink.put(".");
		}


		void print(Block g) {
			iLvl++;
			if (g.constants) {
				print("CONST ".indentBy(iLvl));
				foreach(c;g.constants) {
					print(c);
					print(", ");
				}
				print(";\n");
			}
			if (g.variables) {
				print("VAR ".indentBy(iLvl));
				foreach(v;g.variables) {
					print(v);
					print(", ");
				}
				print(";\n");
			}
			if (g.procedures) {
				foreach(p;g.procedures) {
					print("PROCEDURE ".indentBy(iLvl));
					print(p);
				}
			}
		
			print(g.statement);
		}


		void print(ConstDecl g) {
			print(g.name);
			sink.put(" ");
			sink.put("=");
			sink.put(" ");
			print(g.init);
		}


		void print(VarDecl g) {
			print(g.name);
			sink.put(" ");
			if (g.init) {
				sink.put("=");
				sink.put(" ");
				print(g.init);
			}
		}


		void print(ProDecl g) {
			print(g.name);
			sink.put(";");
			print(g.block);
			--iLvl;
			sink.put(";\n".indentBy(iLvl));
		}


		void print(AssignmentStatement g) {
			print(g.name);
			sink.put(" ");
			sink.put(":=");
			sink.put(" ");
			print(g.expr);
		}


		void print(BeginEndStatement g) {
			sink.put("BEGIN");
			iLvl++;
			newlineAfterStatement = false;
			foreach(_e;g.statements[0..$-1]) {
				print(_e);
				sink.put(";");
			}

			if (g.statements.length >= 1) {
				print(g.statements[$-1]);
				sink.put("\n");
			}
			newlineAfterStatement = true;
			iLvl--;
			sink.put("END".indentBy(iLvl));
		}


		void print(IfStatement g) {
			sink.put("IF");
			sink.put(" ");
			print(g.cond);
			sink.put(" ");
			sink.put("THEN");
			sink.put(" ");
			print(g.stmt);
		}


		void print(WhileStatement g) {
			sink.put("WHILE");
			sink.put(" ");
			print(g.cond);
			sink.put(" ");
			sink.put("DO");
			sink.put(" ");
			print(g.stmt);
		}


		void print(CallStatement g) {
			sink.put("CALL");
			sink.put(" ");
			print(g.name);
		}


		void print(OutputStatement g) {
			sink.put("!");
			sink.put(" ");
			print(g.expr);
		}


		void print(OddCondition g) {
			sink.put("ODD");
			sink.put(" ");
			print(g.expr);
		}


		void print(RelCondition g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
		}


		void print(Equals g) {
			sink.put("=");
		}


		void print(Greater g) {
			sink.put(">");
		}


		void print(Less g) {
			sink.put("<");
		}


		void print(GreaterEq g) {
			sink.put(">=");
		}


		void print(LessEq g) {
			sink.put("<=");
		}


		void print(Hash g) {
			sink.put("#");
		}


		void print(Add g) {
			sink.put("+");
		}


		void print(Sub g) {
			sink.put("-");
		}


		void print(Mul g) {
			sink.put("*");
		}


		void print(Div g) {
			sink.put("/");
		}


		void print(AddExprssion g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
		}


		void print(MulExpression g) {
			print(g.lhs);
			sink.put(" ");
			print(g.op);
			sink.put(" ");
			print(g.rhs);
		}


		void print(ParenExpression g) {
			sink.put("(");
			print(g.expr);
			sink.put(")");
		}


		void print(PrimaryExpression g) {
			if (g.isNegative) {
				sink.put("-");
			}
			if (g.literal) {
				print(g.literal);
			} else if (g.identifier) {
				print(g.identifier);
			} else if (g.paren) {
				print(g.paren);
			}
		}

	}
	auto ptr = Printer();
	ptr.print(cast(PLNode)root);
	return cast(string)ptr.sink.data;
}

