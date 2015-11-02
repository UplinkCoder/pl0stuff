abstract class PLNode {}

class Identifier : PLNode {
	char[] identifier;

	this(char[] identifier) pure {
		this.identifier = identifier;
	}
}

class Number : PLNode {
	char[] number;

	this(char[] number) pure {
		this.number = number;
	}
}

class Programm : PLNode {
	Block block;

	this(Block block) pure {
		this.block = block;
	}
}

class Block : PLNode {
	ConstDecl[] constants;
	VarDecl[] variables;
	ProDecl[] procedures;
	Statement statement;

	this(ConstDecl[] constants, VarDecl[] variables, ProDecl[] procedures, Statement statement) pure {
		this.constants = constants;
		this.variables = variables;
		this.procedures = procedures;
		this.statement = statement;
	}
}

class ConstDecl : PLNode {
	Identifier name;
	Number number;

	this(Identifier name, Number number) pure {
		this.name = name;
		this.number = number;
	}
}

class VarDecl : PLNode {
	Identifier name;

	this(Identifier name) pure {
		this.name = name;
	}
}

class ProDecl : PLNode {
	Identifier name;
	Block block;

	this(Identifier name, Block block) pure {
		this.name = name;
		this.block = block;
	}
}

abstract class Statement : PLNode {}

class AssignmentStatement : Statement {
	Identifier name;
	Expression expr;

	this(Identifier name, Expression expr) pure {
		this.name = name;
		this.expr = expr;
	}
}

class BeginEndStatement : Statement {
	Statement[] statements;

	this(Statement[] statements) pure {
		this.statements = statements;
	}
}

class IfStatement : Statement {
	Condition cond;
	Statement stmt;

	this(Condition cond, Statement stmt) pure {
		this.cond = cond;
		this.stmt = stmt;
	}
}

class WhileStatement : Statement {
	Condition cond;
	Statement stmt;

	this(Condition cond, Statement stmt) pure {
		this.cond = cond;
		this.stmt = stmt;
	}
}

class CallStatement : Statement {
	Identifier name;

	this(Identifier name) pure {
		this.name = name;
	}
}

abstract class Condition : PLNode {}

class OddCondition : Condition {
	Expression expr;

	this(Expression expr) pure {
		this.expr = expr;
	}
}

class RelCondition : Condition {
	Expression lhs;
	RelOp op;
	Expression rhs;

	this(Expression lhs, RelOp op, Expression rhs) pure {
		this.lhs = lhs;
		this.op = op;
		this.rhs = rhs;
	}
}

abstract class RelOp : PLNode {}

class Equals : RelOp {}

class Greater : RelOp {}

class Less : RelOp {}

class GreaterEq : RelOp {}

class LessEq : RelOp {}

class Hash : RelOp {}

abstract class AddOp : PLNode {}

class Add : AddOp {}

class Sub : AddOp {}

abstract class MulOp : PLNode {}

class Mul : MulOp {}

class Div : MulOp {}

abstract class Expression : PLNode {}

class AddExprssion : Expression {
	Expression lhs;
	AddOp op;
	Expression rhs;

	this(Expression lhs, AddOp op, Expression rhs) pure {
		this.lhs = lhs;
		this.op = op;
		this.rhs = rhs;
	}
}

class MulExpression : Expression {
	Expression lhs;
	MulOp op;
	Expression rhs;

	this(Expression lhs, MulOp op, Expression rhs) pure {
		this.lhs = lhs;
		this.op = op;
		this.rhs = rhs;
	}
}

class ParenExpression : Expression {
	Expression expr;

	this(Expression expr) pure {
		this.expr = expr;
	}
}

class PrimaryExpression : Expression {
	Number number;
	Identifier identifier;
	ParenExpression paren;

	this(Number number, Identifier identifier, ParenExpression paren) pure {
		this.number = number;
		this.identifier = identifier;
		this.paren = paren;
	}
}

