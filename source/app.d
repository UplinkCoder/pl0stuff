import pl0_ast;
import pl0_lexer;
import pl0_token;
import pl0_parser;
import pl0_printer;
import pl0_analyzer;

import std.stdio;
import std.file;
import std.algorithm;
import std.array;

void main(string[] args) {
		if (args.length == 2) {
			auto lexed = lex(readText(args[1]));
			writeln("Tokens :", lexed);
			auto parsed = parse(lexed);
			writeln(parsed);
			writeln("AST :", parsed.print);
			writeln("Programm has ", Analyzer(parsed).countBlocks(), " blocks.");
		writeln(sort(parsed.getAllNodes.filter!(n => cast(Identifier)n).map!(i => (cast(Identifier)i).identifier).array));
		} else {
			writeln ("invoke like : ",args[0]," file.pl0 \n");
		}
		
		
}