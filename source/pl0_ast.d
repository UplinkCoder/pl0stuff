version = Location;

version (Location) {
	struct Location {
		uint line;
		uint col;
		uint absPos;
		uint length;
	}

	abstract class PLNode {
		Location loc;
	}
} else {
	abstract class PLNode {}
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

	this(Block b) {
		this.variables = b.variables.dup;
		this.constants = b.constants.dup;
		this.procedures = b.procedures.dup;

		this.statement = null;
	}
}

abstract class Declaration : PLNode {}

final class ConstDecl : Declaration {
	Identifier name;
	Number number;

	this(Identifier name, Number number) pure {
		this.name = name;
		this.number = number;
	}
}

final class VarDecl : Declaration {
	Identifier name;

	this(Identifier name) pure {
		this.name = name;
	}
}

final class ProDecl : Declaration {
	Identifier name;
	Block block;

	this(Identifier name, Block block) pure {
		this.name = name;
		this.block = block;
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

	this(Identifier name) pure {
		this.name = name;
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
	Number number;
	Identifier identifier;
	ParenExpression paren;

	this(Number number, Identifier identifier, ParenExpression paren) pure {
		this.number = number;
		this.identifier = identifier;
		this.paren = paren;
	}
}

