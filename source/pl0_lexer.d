import pl0_token;
import std.exception;

extern (C) Token[] lex(in string source) pure {
	uint col;
	uint line = 1;
	uint pos;
	Token[] result;
	
	char peek(int offset) {
		if (pos + offset > source.length - 1) return '\0';
		enforce(pos + offset >= 0);
		return source[pos + offset];
	}
	
	void putToken(TokenType ttype, char[] data, uint offset=0) {
		
		uint length = offset ? offset : cast(uint) data.length;
		
		result ~= Token(ttype, pos, line, col, length, data);
		
		col += length;
		pos += length;
	}
	
	bool isWhiteSpace(char c) pure {
		return (c == ' ' || c == '\t' || c == '\n' || c == '\r');
	}
	
	bool isIdentifier(char c) pure {
		return ((c >= 'a' && c <= 'z'));
	}

	bool isNumber(char c) pure {
		return ((c >= '0' && c <= '9'));
	}

	void lexIdentifier() {
		char[] __a;
		char __c  = peek(0);
		do {
			__a ~= __c;
			__c = peek(cast(uint)__a.length);
		} while(isIdentifier(__c) || isNumber(__c));

		putToken(TokenType.TT_Identifier, __a, cast(uint) __a.length);

		return;	
	}

	void lexNumber() {
		char[] __a;
		char __c;

		while(isNumber(__c = peek(cast(uint)__a.length))) {
			__a ~= __c;
		}

		putToken(TokenType.TT_Number, __a, cast(uint) __a.length);

		return;	
	}

	TokenType fixedToken(char[9] _chrs) {
		switch(_chrs[0]) {
		default :
			return TokenType.TT_0;

		case '#' :
			return TokenType.TT_1;

		case '(' :
			return TokenType.TT_2;

		case ')' :
			return TokenType.TT_3;

		case '*' :
			return TokenType.TT_4;

		case '+' :
			return TokenType.TT_5;

		case ',' :
			return TokenType.TT_6;

		case '-' :
			return TokenType.TT_7;

		case '.' :
			return TokenType.TT_8;

		case '/' :
			return TokenType.TT_9;

		case ':' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case '=' :
				return TokenType.TT_10;
			}

		case ';' :
			return TokenType.TT_11;


		case '<' :
			switch (_chrs[1]) {
			default :
			return TokenType.TT_12;
			case '=' :
				return TokenType.TT_13;
			}

		case '=' :
			return TokenType.TT_14;


		case '>' :
			switch (_chrs[1]) {
			default :
			return TokenType.TT_15;
			case '=' :
				return TokenType.TT_16;
			}

		case 'B' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'E' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'G' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'I' :
						switch (_chrs[4]) {
						default : return TokenType.TT_0;
						case 'N' :
							return TokenType.TT_17;
						}
					}
				}
			}


		case 'C' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'A': 
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'L' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'L' :
						return TokenType.TT_18;
					}
				}
				
			case 'O' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'N' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'S' :
						switch (_chrs[4]) {
						default : return TokenType.TT_0;
						case 'T' :
							return TokenType.TT_19;
						}
					}
				}
			}

		case 'D' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'O' :
				return TokenType.TT_20;
			}

		case 'E' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'N' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'D' :
					return TokenType.TT_21;
				}
			}

		case 'I' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'F' :
				return TokenType.TT_22;
			}

		case 'O' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'D' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'D' :
					return TokenType.TT_23;
				}
			}

		case 'P' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'R' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'O' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'C' :
						switch (_chrs[4]) {
						default : return TokenType.TT_0;
						case 'E' :
							switch (_chrs[5]) {
							default : return TokenType.TT_0;
							case 'D' :
								switch (_chrs[6]) {
								default : return TokenType.TT_0;
								case 'U' :
									switch (_chrs[7]) {
									default : return TokenType.TT_0;
									case 'R' :
										switch (_chrs[8]) {
										default : return TokenType.TT_0;
										case 'E' :
											return TokenType.TT_24;
										}
									}
								}
							}
						}
					}
				}
			}

		case 'T' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'H' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'E' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'N' :
						return TokenType.TT_25;
					}
				}
			}

		case 'V' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'A' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'R' :
					return TokenType.TT_26;
				}
			}

		case 'W' :
			switch (_chrs[1]) {
			default : return TokenType.TT_0;
			case 'H' :
				switch (_chrs[2]) {
				default : return TokenType.TT_0;
				case 'I' :
					switch (_chrs[3]) {
					default : return TokenType.TT_0;
					case 'L' :
						switch (_chrs[4]) {
						default : return TokenType.TT_0;
						case 'E' :
							return TokenType.TT_27;
						}
					}
				}
			}

		}	
	}
	
	
	while(pos<source.length) {
		char p = source[pos];
		if(isWhiteSpace(p)) {
			if (p == '\n') {
				pos++;col=0;line++;
			} else {
				pos++;col++;
			}
		} else if (auto t = fixedToken([p, peek(1), peek(2), peek(3), peek(4), peek(5), peek(6),peek(7), peek(8)])) {
			switch(t) {
				default : putToken(t, null, TokenSize(t));
			}

		} else if (isIdentifier(p)) {
			lexIdentifier();
		} else if (isNumber(p)) {
			lexNumber();
		} else {
			import std.conv:to;
			enforce(0, "Cannot advance lexer : ASCII Code [" ~ to!string(to!int(p)) ~ "] at line: " ~ to!string(line+1));
		}
	}

	return result;
}
