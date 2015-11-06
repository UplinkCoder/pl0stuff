version = Location;

import pl0_ast;
import pl0_token;

immutable string header = `
		version (Location) {
			Location loc;
			auto firstToken = peekToken(0);
			loc.line = firstToken.line;
			loc.col = firstToken.col;
			loc.absPos = firstToken.pos;
		}
`;

string footer(alias T)() if (is(T : PLNode) || is(typeof(T):PLNode)) {
	static if (!is(T : PLNode) && is(typeof(T):PLNode)) {
		auto m = __traits(identifier, T) ~ ";\n";
	} else {
		auto ta = [__traits(derivedMembers, T)[0 .. ((!$) ? $ : $-1)]];
		static if (is(typeof(ta)==void[])) {
			auto ms = "";
		} else {
			import std.range;
			auto ms = ta.join(", ");
		}
		auto m = "new " ~ __traits(identifier, T) ~ "(" ~ ms ~ ");\n";
	}
		immutable string footer = `
		version (Location) {
			auto lastToken = peekToken(-1);
			loc.length = lastToken.pos - firstToken.pos + lastToken.length;
			auto ret = ` ~ m ~ `
			ret.loc = loc;
			return ret;
		} else {
			return ` ~ m ~ `
		}
`;

	return footer;
}

Programm parse(in Token[] tokens) pure { 
	struct Parser {
	pure :
		const(Token[]) tokens;
		uint pos;
		Token lastMatched;
		
		const(Token) peekToken(int offset) {
			assert(pos + offset <= tokens.length && pos + offset >= 0);
			return tokens[pos + offset];
		}
		
		
		bool peekMatch(TokenType[] arr) {
			foreach (uint i,e;arr) {
				if(peekToken(i).type != e) {
					return false;
				}
			}
			return true;
		}
		
		bool opt_match(TokenType t) {
			lastMatched = cast(Token) peekToken(0);
			
			if (lastMatched.type == t) {
				pos++;
				return true;
			} else {
				lastMatched = Token.init;
				return false;
			}
		}
		
		Token match(bool _try = false)(TokenType t) {
			import std.conv;
			import std.exception:enforce;
			static if (!_try) {
				enforce(opt_match(t), "Expected : " ~ to!string(t) ~ " Got : " ~ to!string(peekToken(0)) );
				return lastMatched;
			} else {
				return ((opt_match(t) ? lastMatched : TokenType.TT_0));
			}
		}


		bool isPLNode() {
			return isProgramm();
		}

		bool isProDecl() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_11]);
		}

		bool isBlock() {
			return peekMatch([TokenType.TT_19]) 
				|| peekMatch([TokenType.TT_26])
				|| peekMatch([TokenType.TT_24])
				|| isStatement();
		}

		bool isConstDecl() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_14]);
		}

		bool isProgramm() {
			return isBlock();
		}

		bool isVarDecl() {
			return peekMatch([TokenType.TT_Identifier]);
		}

		bool isNumber() {
			return peekMatch([TokenType.TT_Number]);
		}

		bool isIdentifier() {
			return peekMatch([TokenType.TT_Identifier]);
		}

		bool isStatement() {
			return isIfStatement()
			|| isWhileStatement()
			|| isNamedExpression()
			|| isBeginEndStatement()
			|| isCallStatement();
		}

		bool isIfStatement() {
			return peekMatch([TokenType.TT_22]);
		}

		bool isWhileStatement() {
			return peekMatch([TokenType.TT_27]);
		}

		bool isNamedExpression() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_10]);
		}

		bool isBeginEndStatement() {
			return peekMatch([TokenType.TT_17]);
		}

		bool isCallStatement() {
			return peekMatch([TokenType.TT_18]);
		}

		bool isCondition() {
			return isRelCondition()
			|| isOddCondition();
		}

		bool isRelCondition() {
			return isExpression();
		}

		bool isOddCondition() {
			return peekMatch([TokenType.TT_23]);
		}

		bool isRelOp() {
			return isEquals()
			|| isGreater()
			|| isLess()
			|| isGreaterEq()
			|| isLessEq()
			|| isHash();
		}

		bool isEquals() {
			return peekMatch([TokenType.TT_14]);
		}

		bool isGreater() {
			return peekMatch([TokenType.TT_15]);
		}

		bool isLess() {
			return peekMatch([TokenType.TT_12]);
		}

		bool isGreaterEq() {
			return peekMatch([TokenType.TT_16]);
		}

		bool isLessEq() {
			return peekMatch([TokenType.TT_13]);
		}

		bool isHash() {
			return peekMatch([TokenType.TT_1]);
		}

		bool isAddOp() {
			return isAdd()
			|| isSub();
		}

		bool isAdd() {
			return peekMatch([TokenType.TT_5]);
		}

		bool isSub() {
			return peekMatch([TokenType.TT_7]);
		}

		bool isMulOp() {
			return isMul()
			|| isDiv();
		}

		bool isMul() {
			return peekMatch([TokenType.TT_4]);
		}

		bool isDiv() {
			return peekMatch([TokenType.TT_9]);
		}

		bool isExpression() {
			return isPrimaryExpression();
		}

		bool isAddExprssion() {
			return isAddOp();
		}

		bool isMulExpression() {
			return isMulOp();
		}

		bool isParenExpression() {
			return peekMatch([TokenType.TT_2]);
		}

		bool isPrimaryExpression() {
			return peekMatch([TokenType.TT_Number])
				|| peekMatch([TokenType.TT_Identifier])
				|| isParenExpression();
		}

		PLNode parsePLNode() {
			PLNode p;
			if (isProgramm()) {
				p = parseProgramm();
			}

			return p;
		}

		Identifier parseIdentifier() {
			mixin(header);
			char[] identifier;

			identifier = match(TokenType.TT_Identifier).data;

			mixin(footer!Identifier);
		}

		Number parseNumber() {
			char[] number;
			mixin(header);
			number = match(TokenType.TT_Number).data;

			mixin(footer!Number);
			}

		Programm parseProgramm() {
			Block block;
			mixin(header);
			block = parseBlock();
			match(TokenType.TT_8);

			mixin(footer!Programm);
		}

		Block parseBlock() {
			Statement statement;
			ConstDecl[] constants;
			VarDecl[] variables;
			ProDecl[] procedures;
			mixin(header);

			if (opt_match(TokenType.TT_19)) {

				constants ~= parseConstDecl();
				while(opt_match(TokenType.TT_6)) {
						constants ~= parseConstDecl();
				}
				match(TokenType.TT_11);
			}
			if (opt_match(TokenType.TT_26)) {

				variables ~= parseVarDecl();
				while(opt_match(TokenType.TT_6)) {
						variables ~= parseVarDecl();
				}
				match(TokenType.TT_11);
			}
			if (opt_match(TokenType.TT_24)) {

				procedures ~= parseProDecl();
				while(opt_match(TokenType.TT_24)) {
						procedures ~= parseProDecl();
				}
				match(TokenType.TT_11);
			}
			statement = parseStatement();

			mixin(footer!Block);
		}

		ConstDecl parseConstDecl() {
			Identifier name;
			Number number;
			mixin(header);
			name = parseIdentifier();
			match(TokenType.TT_14);
			number = parseNumber();

			mixin(footer!ConstDecl);
		}

		VarDecl parseVarDecl() {
			Identifier name;
			mixin(header);
			name = parseIdentifier();

			mixin(footer!VarDecl);
		}

		ProDecl parseProDecl() {
			Identifier name;
			Block block;
			mixin(header);
			name = parseIdentifier();
			match(TokenType.TT_11);
			block = parseBlock();
			mixin(footer!ProDecl);
		}

		Statement parseStatement() {
			Statement s;
			mixin(header);

			if (isNamedExpression()) {
				s = parseNamedExpression();
			} else if (isBeginEndStatement()) {
				s = parseBeginEndStatement();
			} else if (isIfStatement()) {
				s = parseIfStatement();
			} else if (isWhileStatement()) {
				s = parseWhileStatement();
			} else if (isCallStatement()) {
				s = parseCallStatement();
			}
			mixin(footer!s);
		}

		AssignmentStatement parseNamedExpression() {
			Identifier name;
			Expression expr;
			mixin(header);

			name = parseIdentifier();
			match(TokenType.TT_10);
			expr = parseExpression();

			mixin(footer!AssignmentStatement);
		}

		BeginEndStatement parseBeginEndStatement() {
			Statement[] statements;
			mixin(header);
			match(TokenType.TT_17);

			while(isStatement()) {
				statements ~= parseStatement();
				opt_match(TokenType.TT_11);
			}
			match(TokenType.TT_21);

			mixin(footer!BeginEndStatement);
		}

		IfStatement parseIfStatement() {
			Condition cond;
			Statement stmt;
			mixin(header);

			match(TokenType.TT_22);
			cond = parseCondition();
			match(TokenType.TT_25);
			stmt = parseStatement();

			mixin(footer!IfStatement);
		}

		WhileStatement parseWhileStatement() {
			Condition cond;
			Statement stmt;

			mixin(header);

			match(TokenType.TT_27);
			cond = parseCondition();
			match(TokenType.TT_20);
			stmt = parseStatement();

			mixin(footer!WhileStatement);
		}

		CallStatement parseCallStatement() {
			Identifier name;

			mixin(header);

			match(TokenType.TT_18);
			name = parseIdentifier();

			mixin(footer!CallStatement);
		}

		Condition parseCondition() {
			Condition c;
			mixin(header);
			if (isOddCondition()) {
				c = parseOddCondition();
			} else if (isRelCondition()) {
				c = parseRelCondition();
			}
			mixin(footer!c);
		}

		OddCondition parseOddCondition() {
			Expression expr;
			mixin(header);
			match(TokenType.TT_23);
			expr = parseExpression();

			mixin(footer!OddCondition);
		}

		RelCondition parseRelCondition() {
			Expression lhs;
			RelOp op;
			Expression rhs;

			mixin(header);

			lhs = parseExpression();
			op = parseRelOp();
			rhs = parseExpression();

			mixin(footer!RelCondition);
		}

		RelOp parseRelOp() {
			RelOp r;
			mixin(header);
			if (isEquals()) {
				r = parseEquals();
			} else if (isGreater()) {
				r = parseGreater();
			} else if (isLess()) {
				r = parseLess();
			} else if (isGreaterEq()) {
				r = parseGreaterEq();
			} else if (isLessEq()) {
				r = parseLessEq();
			} else if (isHash()) {
				r = parseHash();
			}

			mixin(footer!r);
		}

		Equals parseEquals() {
			mixin(header);
			match(TokenType.TT_14);

			mixin(footer!Equals);
		}

		Greater parseGreater() {
			mixin(header);
			match(TokenType.TT_15);

			mixin(footer!Greater);
		}

		Less parseLess() {
			mixin(header);
			match(TokenType.TT_12);
			mixin(footer!Less);
		}

		GreaterEq parseGreaterEq() {

			match(TokenType.TT_16);

			return new GreaterEq();
		}

		LessEq parseLessEq() {

			match(TokenType.TT_13);

			return new LessEq();
		}

		Hash parseHash() {

			match(TokenType.TT_1);

			return new Hash();
		}

		AddOp parseAddOp() {
			AddOp a;
			if (isAdd()) {
				a = parseAdd();
			} else if (isSub()) {
				a = parseSub();
			}

			return a;
		}

		Add parseAdd() {

			match(TokenType.TT_5);

			return new Add();
		}

		Sub parseSub() {

			match(TokenType.TT_7);

			return new Sub();
		}

		MulOp parseMulOp() {
			MulOp m;
			if (isMul()) {
				m = parseMul();
			} else if (isDiv()) {
				m = parseDiv();
			}

			return m;
		}

		Mul parseMul() {

			match(TokenType.TT_4);

			return new Mul();
		}

		Div parseDiv() {

			match(TokenType.TT_9);

			return new Div();
		}

		enum ExpressionRCEnum {
			__Init,
			__AddExprssion,
			__MulExpression
		}

		Expression parseExpression(ExpressionRCEnum __rc = ExpressionRCEnum.__Init) {
			Expression e;
			mixin(header);
			if (isPrimaryExpression()) {
				e = parsePrimaryExpression();
			} 

			if (isAddExprssion() && __rc != ExpressionRCEnum.__AddExprssion) {
				e = parseAddExprssion(e);
			} else if (isMulExpression() && __rc != ExpressionRCEnum.__MulExpression) {
				e = parseMulExpression(e);
			} 

			mixin(footer!e);
		}

		AddExprssion parseAddExprssion(Expression prev) {
			Expression lhs;
			AddOp op;
			Expression rhs;
			mixin(header);
			//lhs = parseExpression(ExpressionRCEnum.__AddExprssion);
			lhs = prev;
			op = parseAddOp();
			rhs = parseExpression();

			mixin(footer!AddExprssion);
		}

		MulExpression parseMulExpression(Expression prev) {
			Expression lhs;
			MulOp op;
			Expression rhs;
			mixin(header);
			lhs = prev;
			op = parseMulOp();
			rhs = parseExpression();

			mixin(footer!MulExpression);
		}

		ParenExpression parseParenExpression() {
			Expression expr;
			mixin(header);

			match(TokenType.TT_2);
			expr = parseExpression();
			match(TokenType.TT_3);

			mixin(footer!ParenExpression);
		}

		PrimaryExpression parsePrimaryExpression() {
			Number number;
			Identifier identifier;
			ParenExpression paren;
			mixin(header);

			if (isNumber()) {
				number = parseNumber();
			} else if (isIdentifier()) {
				identifier = parseIdentifier();
			} else if (isParenExpression()) {
				paren = parseParenExpression();
			} 

			mixin(footer!PrimaryExpression);
		}

	}

	return Parser(tokens).parseProgramm();
}
