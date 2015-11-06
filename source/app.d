version = Location;
version = Extended;

version (Extended) {
	import pl0_extended_ast;
	import pl0_extended_lexer;
	import pl0_extended_token;
	import pl0_extended_parser;
	import pl0_extended_printer;
	import pl0_extended_analyzer;
} else {
	import pl0_ast;
	import pl0_lexer;
	import pl0_token;
	import pl0_parser;
	import pl0_printer;
	import pl0_analyzer;
}

import std.stdio;
import std.file;
import std.algorithm;
import std.array;
import pl0_testsource;
import pl0_callInliner;

void main(string[] args) {
	static const static_parsed = test0.lex.parse;
	static const static_patsed_1 = test1.lex.parse;

	version(Extended) {
		static const extended_test_0 = test0_extended.lex.parse;
		static const extended_test_1 = test1_extended.lex.parse;
	//	static const extended_test_2 = test2_extended.lex.parse;
	}
		
	pragma(msg, static_parsed);
	version(Extended) {
		pragma(msg, extended_test_1);
	}

		if (args.length == 2) {
		auto source = readText(args[1]);
			auto lexed = lex(source);
			//writeln("Tokens :", lexed);
			auto parsed = parse(lexed);
			//writeln(parsed);
			//writeln("AST :", parsed.print);
			auto analyzer = Analyzer(parsed);
		foreach(k,v;analyzer.stable.symbolsByName) {
			if (v.length > 1) {
				writeln("Symbol '", k, "' is Defined multiple times");
				foreach(s;v) {
					writeln ("in line ",s.d.loc.line);
				}
			}
		}
		auto ci = CallInliner(&analyzer);
		writeln("Before Inlining", analyzer.programm.print);
		foreach (be;analyzer.allNodes.filter!(n => cast(BeginEndStatement)n.node)) {
			reduceBeginEnd(be);
		}
		foreach (cs;analyzer.allNodes.filter!(n => cast(CallStatement)n.node)) {
			ci.inlineCall(cs);
		}
		writeln("After Inlining", analyzer.programm.print);

		foreach(node;analyzer.allNodes
			.filter!(n => cast(PrimaryExpression)n.node !is null)
			.filter!(n => (cast(PrimaryExpression*)&n.node).identifier !is null)) {
			auto pe = (cast(PrimaryExpression*)&node.node);
			if (pe.identifier.identifier !in analyzer.stable.symbolsByName) {
			//	auto expr = Analyzer.getAllNodes(pe
				analyzer.errors ~= analyzer.Error("Undeclared Symbol Refernced", pe.loc);
				writeln(analyzer.errors[$-1].toString(source));
				version (Location) {
				//	writeln(" in Line ", pe.loc.line,"!","\n",source[pe.loc.absPos .. pe.loc.absPos + pe.loc.length +1]); 
				} else {
					writeln();
				}
			}
		}
		foreach(node;analyzer.allNodes
			.filter!(n => cast(AssignmentStatement)n.node !is null)) {
			if (auto e = analyzer.isInvaildAssignment(node)) {
				writeln(e.toString(source));
			}
		}

			writeln("Programm has ", analyzer.countBlocks(), " blocks and ", analyzer.countBeginEndStatements, " BEGIN .. END Statements.");
		//writeln(analyzer.genDot);
		writeln("AllVariables : ", sort(analyzer.getAllNodes.map!(i => (cast(VarDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array).uniq);
		writeln("AllConstants : ", sort(analyzer.getAllNodes.map!(i => (cast(ConstDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array).uniq);
		writeln("AllProcedures : ", sort(analyzer.getAllNodes.map!(i => (cast(ProDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array));
		writeln(analyzer.programm.block.procedures.length);
	} else {
			writeln ("invoke like : ", args[0], " file.pl0 \n");
		}
		
		
}