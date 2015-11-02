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

	TT_1, // #
	TT_2, // (
	TT_3, // )
	TT_4, // *
	TT_5, // +
	TT_6, // ,
	TT_7, // -
	TT_8, // .
	TT_9, // /
	TT_10, // :=
	TT_11, // ;
	TT_12, // <
	TT_13, // <=
	TT_14, // =
	TT_15, // >
	TT_16, // >=
	TT_17, // BEGIN
	TT_18, // CALL
	TT_19, // CONST
	TT_20, // DO
	TT_21, // END
	TT_22, // IF
	TT_23, // ODD
	TT_24, // PROCEDURE
	TT_25, // THEN
	TT_26, // VAR
	TT_27, // WHILE
}
uint TokenSize(TokenType t) pure {
	switch(t) {
		case TokenType.TT_10 : return 2;
		case TokenType.TT_13 : return 2;
		case TokenType.TT_16 : return 2;
		case TokenType.TT_17 : return 5;
		case TokenType.TT_18 : return 4;
		case TokenType.TT_19 : return 5;
		case TokenType.TT_20 : return 2;
		case TokenType.TT_21 : return 3;
		case TokenType.TT_22 : return 2;
		case TokenType.TT_23 : return 3;
		case TokenType.TT_24 : return 9;
		case TokenType.TT_25 : return 4;
		case TokenType.TT_26 : return 3;
		case TokenType.TT_27 : return 5;
		default : return 1;
	}
}
