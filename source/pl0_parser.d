import pl0_ast;
import pl0_token;

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
			char[] identifier;

			identifier = match(TokenType.TT_Identifier).data;

			return new Identifier(identifier);
		}

		Number parseNumber() {
			char[] number;

			number = match(TokenType.TT_Number).data;

			return new Number(number);
		}

		Programm parseProgramm() {
			Block block;

			block = parseBlock();
			match(TokenType.TT_8);

			return new Programm(block);
		}

		Block parseBlock() {
			Statement statement;
			ConstDecl[] constants;
			VarDecl[] variables;
			ProDecl[] procedures;

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

			return new Block(constants, variables, procedures, statement);
		}

		ConstDecl parseConstDecl() {
			Identifier name;
			Number number;

			name = parseIdentifier();
			match(TokenType.TT_14);
			number = parseNumber();

			return new ConstDecl(name, number);
		}

		VarDecl parseVarDecl() {
			Identifier name;

			name = parseIdentifier();

			return new VarDecl(name);
		}

		ProDecl parseProDecl() {
			Identifier name;
			Block block;

			name = parseIdentifier();
			match(TokenType.TT_11);
			block = parseBlock();

			return new ProDecl(name, block);
		}

		Statement parseStatement() {
			Statement s;
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

			return s;
		}

		AssignmentStatement parseNamedExpression() {
			Identifier name;
			Expression expr;

			name = parseIdentifier();
			match(TokenType.TT_10);
			expr = parseExpression();

			return new AssignmentStatement(name, expr);
		}

		BeginEndStatement parseBeginEndStatement() {
			Statement[] statements;

			match(TokenType.TT_17);

			while(isStatement()) {
				statements ~= parseStatement();
				match(TokenType.TT_11);
			}
			match(TokenType.TT_21);

			return new BeginEndStatement(statements);
		}

		IfStatement parseIfStatement() {
			Condition cond;
			Statement stmt;

			match(TokenType.TT_22);
			cond = parseCondition();
			match(TokenType.TT_25);
			stmt = parseStatement();

			return new IfStatement(cond, stmt);
		}

		WhileStatement parseWhileStatement() {
			Condition cond;
			Statement stmt;

			match(TokenType.TT_27);
			cond = parseCondition();
			match(TokenType.TT_20);
			stmt = parseStatement();

			return new WhileStatement(cond, stmt);
		}

		CallStatement parseCallStatement() {
			Identifier name;

			match(TokenType.TT_18);
			name = parseIdentifier();

			return new CallStatement(name);
		}

		Condition parseCondition() {
			Condition c;
			if (isOddCondition()) {
				c = parseOddCondition();
			} else if (isRelCondition()) {
				c = parseRelCondition();
			}

			return c;
		}

		OddCondition parseOddCondition() {
			Expression expr;

			match(TokenType.TT_23);
			expr = parseExpression();

			return new OddCondition(expr);
		}

		RelCondition parseRelCondition() {
			Expression lhs;
			RelOp op;
			Expression rhs;

			lhs = parseExpression();
			op = parseRelOp();
			rhs = parseExpression();

			return new RelCondition(lhs, op, rhs);
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

			match(TokenType.TT_14);

			return new Equals();
		}

		Greater parseGreater() {

			match(TokenType.TT_15);

			return new Greater();
		}

		Less parseLess() {

			match(TokenType.TT_12);

			return new Less();
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
			if (isPrimaryExpression()) {
				e = parsePrimaryExpression();
			} 

			if (isAddExprssion() && __rc != ExpressionRCEnum.__AddExprssion) {
				e = parseAddExprssion(e);
			} else if (isMulExpression() && __rc != ExpressionRCEnum.__MulExpression) {
				e = parseMulExpression(e);
			} 

			return e;
		}

		AddExprssion parseAddExprssion(Expression prev) {
			Expression lhs;
			AddOp op;
			Expression rhs;

			//lhs = parseExpression(ExpressionRCEnum.__AddExprssion);
			lhs = prev;
			op = parseAddOp();
			rhs = parseExpression();

			return new AddExprssion(lhs, op, rhs);
		}

		MulExpression parseMulExpression(Expression prev) {
			Expression lhs;
			MulOp op;
			Expression rhs;

			lhs = prev;
			op = parseMulOp();
			rhs = parseExpression();

			return new MulExpression(lhs, op, rhs);
		}

		ParenExpression parseParenExpression() {
			Expression expr;

			match(TokenType.TT_2);
			expr = parseExpression();
			match(TokenType.TT_3);

			return new ParenExpression(expr);
		}

		PrimaryExpression parsePrimaryExpression() {
			Number number;
			Identifier identifier;
			ParenExpression paren;

			if (isNumber()) {
				number = parseNumber();
			} else if (isIdentifier()) {
				identifier = parseIdentifier();
			} else if (isParenExpression()) {
				paren = parseParenExpression();
			} 

			return new PrimaryExpression(number, identifier, paren);
		}

	}

	return Parser(tokens).parseProgramm();
}
