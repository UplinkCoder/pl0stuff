
import pl0_extended_ast;
import pl0_extended_token;

version = Location;

immutable string header = `
		version (Location) {
			MyLocation loc;
			auto firstToken = peekToken(0);
			loc.line = firstToken.line;
			loc.col = firstToken.col;
			loc.absPos = firstToken.pos;
		}
`;

string footer(alias T)() if (is(T : PLNode) || is(typeof(T):PLNode)) {
	static if (!is(T : PLNode) && is(typeof(T):PLNode)) {
		auto m = __traits(identifier, T);
		auto r = m ~ ".loc = loc;\n\t\t\t return " ~ m ~ ";\n";
	} else {
		auto ta = [__traits(derivedMembers, T)[0 .. ((!$) ? $ : $-1)]];
		static if (is(typeof(ta)==void[])) {
			auto ms = "";
		} else {
			import std.range;
			auto ms = ta.join(", ");
		}
		auto m = "new " ~ __traits(identifier, T) ~ "(" ~ ms ~ ")\n";
		auto r = "auto ret = " ~ m ~ ";\n\t\t\t"  ~"ret.loc = loc;\n\t\t\treturn ret;\n";
	}
	immutable string footer = `
		version (Location) {
			auto lastToken = peekToken(-1);
			loc.length = lastToken.pos -  firstToken.pos + lastToken.length;
			` ~ r ~ `
		} else {
			return ` ~ m ~ `;
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
			if (pos + offset > tokens.length - 1) {
				return Token.init;
			}
			assert(pos + offset >= 0, "Trying to read outside of sourceCode");
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
				return ((opt_match(t) ? lastMatched : Token.init));
			}
		}


		bool isPLNode() {
			return isProgramm();
		}
		bool isBlock() {
			return peekMatch([TokenType.TT_21]) 
				|| peekMatch([TokenType.TT_26])
				|| peekMatch([TokenType.TT_28])
				|| isStatement();
		}
		bool isProgramm() {
			return isBlock();
		}

		bool isLiteral() {
			return peekMatch([TokenType.TT_Number]);
		}

		bool isNumber() {
			return peekMatch([TokenType.TT_Number]);
		}

		bool isIdentifier() {
			return peekMatch([TokenType.TT_Identifier]);
		}

		bool isProDecl() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_12]);
		}

		bool isConstDecl() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_15]);
		}

		bool isVarDecl() {
			return peekMatch([TokenType.TT_Identifier]);
		}

		bool isStatement() {
			return isIfStatement()
			|| isWhileStatement()
			|| isAssignmentStatement()
			|| isBeginEndStatement()
			|| isCallStatement()
			|| isOutputStatement();
		}


		bool isIfStatement() {
			return peekMatch([TokenType.TT_24]);
		}

		bool isWhileStatement() {
			return peekMatch([TokenType.TT_29]);
		}


		bool isAssignmentStatement() {
			return peekMatch([TokenType.TT_Identifier, TokenType.TT_11]);
		}

		bool isBeginEndStatement() {
			return peekMatch([TokenType.TT_19]);
		}

		bool isCallStatement() {
			return peekMatch([TokenType.TT_20]);
		}

		bool isOutputStatement() {
			return peekMatch([TokenType.TT_1]);
		}

		bool isCondition() {
			return isOddCondition()
				|| isExpression();
		}

//		bool isRelCondition() {
//			return peekMatch([TokenType.TT_Expression, TokenType.TT_RelOp]);
//		}

		bool isOddCondition() {
			return peekMatch([TokenType.TT_25]);
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
			return peekMatch([TokenType.TT_15]);
		}

		bool isGreater() {
			return peekMatch([TokenType.TT_16]);
		}

		bool isLess() {
			return peekMatch([TokenType.TT_13]);
		}

		bool isGreaterEq() {
			return peekMatch([TokenType.TT_17]);
		}

		bool isLessEq() {
			return peekMatch([TokenType.TT_14]);
		}

		bool isHash() {
			return peekMatch([TokenType.TT_2]);
		}

		bool isAddOp() {
			return isAdd()
			|| isSub();
		}

		bool isAdd() {
			return peekMatch([TokenType.TT_6]);
		}

		bool isSub() {
			return peekMatch([TokenType.TT_8]);
		}

		bool isMulOp() {
			return isMul()
			|| isDiv();
		}

		bool isMul() {
			return peekMatch([TokenType.TT_5]);
		}

		bool isDiv() {
			return peekMatch([TokenType.TT_10]);
		}

		bool isExpression() {
			return isAddExprssion()
			|| isMulExpression()
			|| isPrimaryExpression();
		}

		bool isAddExprssion() {
			return isAddOp();
		}

		bool isMulExpression() {
			return isMulOp();
		}

		bool isParenExpression() {
			return peekMatch([TokenType.TT_3]);
		}

		bool isPrimaryExpression() {
			return peekMatch([TokenType.TT_Identifier])
			|| peekMatch([TokenType.TT_Number])
			|| peekMatch([TokenType.TT_3])
			|| peekMatch([TokenType.TT_8, TokenType.TT_Identifier])
			|| peekMatch([TokenType.TT_8, TokenType.TT_Number])
			|| peekMatch([TokenType.TT_8, TokenType.TT_3]);
		}

		PLNode parsePLNode() {
			PLNode p;
			if (isLiteral()) {
				p = parseLiteral();
			} else if (isProgramm()) {
				p = parseProgramm();
			} 

			return p;
		}

		Identifier parseIdentifier() {
			char[] identifier;
			mixin(header);
			identifier = match(TokenType.TT_Identifier).data;
			mixin(footer!Identifier);
		}

		Number parseNumber() {
			char[] number;
			mixin(header);
			number = match(TokenType.TT_Number).data;
			mixin(footer!Number);
		}

		Literal parseLiteral() {
			Number intp;
			Number floatp;
			mixin(header);

			intp = parseNumber();
			if (opt_match(TokenType.TT_9)) {
				floatp = parseNumber();
			}

			mixin(footer!Literal);
		}

		Programm parseProgramm() {
			Block block;
			 
			mixin(header);

			block = parseBlock();
			match(TokenType.TT_9);

			mixin(footer!Programm);
		}

		Block parseBlock() {
			ConstDecl[] constants;
			VarDecl[] variables;
			ProDecl[] procedures;
			Statement statement;
			mixin(header);

			if (opt_match(TokenType.TT_21)) {

				constants ~= parseConstDecl();
				while(opt_match(TokenType.TT_7)) {
						constants ~= parseConstDecl();
				}
				match(TokenType.TT_12);
			}
			if (opt_match(TokenType.TT_28)) {

				variables ~= parseVarDecl();
				while(opt_match(TokenType.TT_7)) {
						variables ~= parseVarDecl();
				}
				match(TokenType.TT_12);
			}
			if (opt_match(TokenType.TT_26)) {

				procedures ~= parseProDecl();
				while(opt_match(TokenType.TT_26)) {
						procedures ~= parseProDecl();
				}
			}
			statement = parseStatement();


			mixin(footer!Block);
		}

		ConstDecl parseConstDecl() {
			Identifier name;
			PrimaryExpression _init;
			mixin(header);

			name = parseIdentifier();
			match(TokenType.TT_15);
			_init = parsePrimaryExpression();

			mixin(footer!ConstDecl);
		}

		VarDecl parseVarDecl() {
			Identifier name;
			PrimaryExpression _init;
			mixin(header);

			name = parseIdentifier();
			if (opt_match(TokenType.TT_15)) {
				_init = parsePrimaryExpression();
			}

			mixin(footer!VarDecl);
		}

		ProDecl parseProDecl() {
			Identifier name;
			bool isFunction;
			Block block;
			VarDecl[] arguments;
			mixin(header);

			name = parseIdentifier();
			match(TokenType.TT_12);
			if (opt_match(TokenType.TT_18)) {
				isFunction = true;
				if(!opt_match(TokenType.TT_12)) {
					arguments ~= parseVarDecl();
					while(opt_match(TokenType.TT_7)) {
							arguments ~= parseVarDecl();
					}
					match(TokenType.TT_12);
				}
			}
			block = parseBlock();
			match(TokenType.TT_12);

			mixin(footer!ProDecl);
		}

		Statement parseStatement() {
			Statement s;
			mixin(header);
			if (isAssignmentStatement()) {
				s = parseAssignmentStatement();
			} else if (isBeginEndStatement()) {
				s = parseBeginEndStatement();
			} else if (isIfStatement()) {
				s = parseIfStatement();
			} else if (isWhileStatement()) {
				s = parseWhileStatement();
			} else if (isCallStatement()) {
				s = parseCallStatement();
			} else if (isOutputStatement()) {
				s = parseOutputStatement();
			} else {
				import std.conv;
				debug {
					import std.stdio;
				//	__ctfeWriteln(isStatement());
				}
				assert(s !is null, to!(string)(peekToken(0)));
			}

			mixin(footer!s);
		}

		AssignmentStatement parseAssignmentStatement() {
			Identifier name;
			Expression expr;
			mixin(header);

			name = parseIdentifier();
			match(TokenType.TT_11);
			expr = parseExpression();

			mixin(footer!AssignmentStatement);
		}

		BeginEndStatement parseBeginEndStatement() {
			Statement[] statements;
			mixin(header);

			match(TokenType.TT_19);
			do {
				statements ~= parseStatement();
			} while(opt_match(TokenType.TT_12));

			match!(false)(TokenType.TT_23);

			mixin(footer!BeginEndStatement);
		}

		IfStatement parseIfStatement() {
			Condition cond;
			Statement stmt;
			mixin(header);

			match(TokenType.TT_24);
			cond = parseCondition();
			match(TokenType.TT_27);
			stmt = parseStatement();

			mixin(footer!IfStatement);
		}

		WhileStatement parseWhileStatement() {
			Condition cond;
			Statement stmt;
			mixin(header);

			match(TokenType.TT_29);
			cond = parseCondition();
			match(TokenType.TT_22);
			stmt = parseStatement();

			mixin(footer!WhileStatement);
		}

		CallStatement parseCallStatement() {
			Identifier name;
			Expression[] arguments;
			mixin(header);

			match(TokenType.TT_20);
			name = parseIdentifier();
			if (opt_match(TokenType.TT_18)) {
				arguments ~= parseExpression;
				while(opt_match(TokenType.TT_7)) {
					arguments ~= parseExpression();
				}
			}

			mixin(footer!CallStatement);
		}

		OutputStatement parseOutputStatement() {
			Expression expr;
			mixin(header);

			match(TokenType.TT_1);
			expr = parseExpression();

			mixin(footer!OutputStatement);
		}

		Condition parseCondition() {
			Condition c;
			mixin(header);

			if (isOddCondition()) {
				c = parseOddCondition();
			} else {
				c = parseRelCondition();
			}

			mixin(footer!c);
		}

		OddCondition parseOddCondition() {
			Expression expr;

			match(TokenType.TT_25);
			expr = parseExpression();

		return new OddCondition(expr);
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

			return r;
		}

		Equals parseEquals() {

			match(TokenType.TT_15);

		return new Equals();
		}

		Greater parseGreater() {

			match(TokenType.TT_16);

		return new Greater();
		}

		Less parseLess() {

			match(TokenType.TT_13);

		return new Less();
		}

		GreaterEq parseGreaterEq() {

			match(TokenType.TT_17);

		return new GreaterEq();
		}

		LessEq parseLessEq() {

			match(TokenType.TT_14);

		return new LessEq();
		}

		Hash parseHash() {

			match(TokenType.TT_2);

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

			match(TokenType.TT_6);

		return new Add();
		}

		Sub parseSub() {

			match(TokenType.TT_8);

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

			match(TokenType.TT_5);

		return new Mul();
		}

		Div parseDiv() {

			match(TokenType.TT_10);

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

			if (isAddExprssion()) {
				e = parseAddExprssion(e);
			} else if (isMulExpression()) {
				e = parseMulExpression(e);
			}

			mixin(footer!e);
		}

		AddExprssion parseAddExprssion(Expression prev) {
			Expression lhs;
			AddOp op;
			Expression rhs;
			mixin(header);

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

			match(TokenType.TT_3);
			expr = parseExpression();
			match(TokenType.TT_4);

			mixin(footer!ParenExpression);
		}

		PrimaryExpression parsePrimaryExpression() {
			bool isNegative;
			Literal literal;
			Identifier identifier;
			ParenExpression paren;
			mixin(header);

			if (opt_match(TokenType.TT_8)) {
				isNegative = true;
			}
			if (isLiteral()) {
				literal = parseLiteral();
			} else if (isIdentifier()) {
				identifier = parseIdentifier();
			} else if (isParenExpression()) {
				paren = parseParenExpression();
			} 

			mixin(footer!PrimaryExpression);
		}


	}

	return Parser(tokens).parseProgramm;
}
