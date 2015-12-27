PLNode {
	Identifier @internal {
		[a-z][] identifier
	}

	Number @internal {
		[0-9][] number
	}
	
	Literal @internal {
		Number intp, ? "." : Number floatp
	}

	Programm @parent {
		Block block, "."
	}
	
	Block @internal {
		? "CONST" :  (ConstDecl[] constants : ",", ";"),
		? "VAR" : (VarDecl[] variables : ",", ";"),
		? "PROCEDURE" : (ProDecl[] procedures : "PROCEDURE", ";"),
		Statement statement
	}

	Declaration @internal {
		ConstDecl @internal {
			Identifier name, "=", PrimaryExpression init
		}

		VarDecl @internal {
			Identifier name, ? "=" : PrimaryExpression init
		}

		ProDecl @internal {
			Identifier name, ";",? "ARG" : (VarDecl[] arguments : ",", ";"), Block block, ";"
		}
	}
	
	Statement @internal {
		AssignmentStatement {
			Identifier name, ":=", Expression expr
		}
		BeginEndStatement {
			"BEGIN", Statement[] statements : ";", "END"	
		}
		IfStatement {
			"IF", Condition cond, "THEN", Statement stmt
		}
		WhileStatement {
			"WHILE", Condition cond, "DO", Statement stmt
		}
		CallStatement {
			"CALL", Identifier name, ? "ARG" : Expression[] arguments
		}
		OutputStatement {
			"!", Expression expr
		}
		
	}

	Condition @internal {
		OddCondition {
			"ODD", Expression expr
		}
		
		RelCondition {
			Expression lhs, RelOp op, Expression rhs
		}
	}

	RelOp @internal {
		Equals {"="}
		Greater {">"}
		Less {"<"}
		GreaterEq {">="}
		LessEq {"<="}
		Hash {"#"} 
	}

	AddOp @internal {
		Add {"+"}
		Sub {"-"}
	}

	MulOp @internal {
		Mul {"*"}
		Div {"/"}
	}

	Expression @internal {
		AddExprssion { 
			Expression lhs, AddOp op, Expression rhs
		}
		
		MulExpression {
			Expression lhs, MulOp op, Expression rhs
		}
		
		ParenExpression @internal {
			"(", Expression expr, ")"
		}
		
		PrimaryExpression {
			? "-" : bool isNegative, Literal number / Identifier identifier / ParenExpression paren
		}
	}
}
