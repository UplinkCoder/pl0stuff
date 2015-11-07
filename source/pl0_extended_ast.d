version = Location;

version (Location) {
	struct MyLocation {
		uint line;
		uint col;
		uint absPos;
		uint length;
	}

	abstract class PLNode {
		MyLocation loc;
	}
} else {
//	abstract class PLNode {}
}
final class Identifier : PLNode {
	char[] identifier;

	this(char[] identifier) pure {
		this.identifier = identifier;
	}
}

final class Number : PLNode {
	char[] number;

	this(char[] number) pure {
		this.number = number;
	}
}

final class Literal : PLNode {
	Number intp;
	Number floatp;

	this(Number intp, Number floatp) pure {
		this.intp = intp;
		this.floatp = floatp;
	}
}

final class Programm : PLNode {
	Block block;

	this(Block block) pure {
		this.block = block;
	}
}

final class Block : PLNode {
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

abstract class Declaration : PLNode {}

final class ConstDecl : Declaration {
	Identifier name;
	PrimaryExpression _init;

	this(Identifier name, PrimaryExpression _init) pure {
		this.name = name;
		this._init = _init;
	}
}

final class VarDecl : Declaration {
	Identifier name;
	PrimaryExpression _init;

	this(Identifier name, PrimaryExpression _init) pure {
		this.name = name;
		this._init = _init;
	}
}

final class ProDecl : Declaration {
	Identifier name;
	Block block;
	VarDecl[] arguments;

	this(Identifier name, Block block, VarDecl[] arguments) pure {
		this.name = name;
		this.block = block;
		this.arguments = arguments;
	}
}

abstract class Statement : PLNode {}

final class AssignmentStatement : Statement {
	Identifier name;
	Expression expr;

	this(Identifier name, Expression expr) pure {
		this.name = name;
		this.expr = expr;
	}
}

final class BeginEndStatement : Statement {
	Statement[] statements;

	this(Statement[] statements) pure {
		this.statements = statements;
	}
}

final class IfStatement : Statement {
	Condition cond;
	Statement stmt;

	this(Condition cond, Statement stmt) pure {
		this.cond = cond;
		this.stmt = stmt;
	}
}

final class WhileStatement : Statement {
	Condition cond;
	Statement stmt;

	this(Condition cond, Statement stmt) pure {
		this.cond = cond;
		this.stmt = stmt;
	}
}

final class CallStatement : Statement {
	Identifier name;
	Expression[] arguments;

	this(Identifier name, Expression[] arguments) pure {
		this.name = name;
		this.arguments = arguments;
	}
}

final class OutputStatement : Statement {
	Expression expr;

	this(Expression expr) pure {
		this.expr = expr;
	}
}

abstract class Condition : PLNode {}

final class OddCondition : Condition {
	Expression expr;

	this(Expression expr) pure {
		this.expr = expr;
	}
}

final class RelCondition : Condition {
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

final class Equals : RelOp {}

final class Greater : RelOp {}

final class Less : RelOp {}

final class GreaterEq : RelOp {}

final class LessEq : RelOp {}

final class Hash : RelOp {}

abstract class AddOp : PLNode {}

final class Add : AddOp {}

final class Sub : AddOp {}

abstract class MulOp : PLNode {}

final class Mul : MulOp {}

final class Div : MulOp {}

abstract class Expression : PLNode {}

final class AddExprssion : Expression {
	Expression lhs;
	AddOp op;
	Expression rhs;

	this(Expression lhs, AddOp op, Expression rhs) pure {
		this.lhs = lhs;
		this.op = op;
		this.rhs = rhs;
	}
}

final class MulExpression : Expression {
	Expression lhs;
	MulOp op;
	Expression rhs;

	this(Expression lhs, MulOp op, Expression rhs) pure {
		this.lhs = lhs;
		this.op = op;
		this.rhs = rhs;
	}
}

final class ParenExpression : Expression {
	Expression expr;

	this(Expression expr) pure {
		this.expr = expr;
	}
}

final class PrimaryExpression : Expression {
	bool isNegative;
	Literal literal;
	Identifier identifier;
	ParenExpression paren;

	this(bool isNegative, Literal literal, Identifier identifier, ParenExpression paren) pure {
		this.isNegative = isNegative;
		this.literal = literal;
		this.identifier = identifier;
		this.paren = paren;
	}
}


