struct Token {
	TokenType type;
	
	uint pos;
	uint line;
	uint col;
	uint length;
	
	char[] data;
}
enum TokenType {
	TT_0, // Invalid Token

	TT_Identifier,
	TT_Number,

	TT_1, // !
	TT_2, // #
	TT_3, // (
	TT_4, // )
	TT_5, // *
	TT_6, // +
	TT_7, // ,
	TT_8, // -
	TT_9, // .
	TT_10, // /
	TT_11, // :=
	TT_12, // ;
	TT_13, // <
	TT_14, // <=
	TT_15, // =
	TT_16, // >
	TT_17, // >=
	TT_18, // ARG
	TT_19, // BEGIN
	TT_20, // CALL
	TT_21, // CONST
	TT_22, // DO
	TT_23, // END
	TT_24, // IF
	TT_25, // ODD
	TT_26, // PROCEDURE
	TT_27, // THEN
	TT_28, // VAR
	TT_29, // WHILE
}
uint TokenSize(TokenType t) pure {
	switch(t) {
		case TokenType.TT_11 : return 2;
		case TokenType.TT_14 : return 2;
		case TokenType.TT_17 : return 2;
		case TokenType.TT_18 : return 3;
		case TokenType.TT_19 : return 5;
		case TokenType.TT_20 : return 4;
		case TokenType.TT_21 : return 5;
		case TokenType.TT_22 : return 2;
		case TokenType.TT_23 : return 3;
		case TokenType.TT_24 : return 2;
		case TokenType.TT_25 : return 3;
		case TokenType.TT_26 : return 9;
		case TokenType.TT_27 : return 4;
		case TokenType.TT_28 : return 3;
		case TokenType.TT_29 : return 5;
		default : return 1;
	}
}

