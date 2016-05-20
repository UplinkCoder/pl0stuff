

import pl0_extended_ast;
import pl0_extended_lexer;
import pl0_extended_token;
import pl0_extended_parser;
import pl0_extended_printer;
import pl0_extended_analyzer;

import std.algorithm;
import std.array;
import pl0_testsource;
import optimizer;
import codeGen;
import sdc.terminal;

static const static_parsed = test0.lex.parse;
static const static_patsed_1 = test1.lex.parse;


static const extended_test_0 = test0_extended.lex.parse;
static const extended_test_1 = test1_extended.lex.parse;
static const extended_test_2 = test2_extended.lex.parse;

//pragma(msg, static_parsed.genCode);

//pragma(msg, extended_test_1);
pragma(msg, test1_extended);
//pragma(msg, extended_test_1.optimize.genCode(false, TargetLanguage.D));

mixin(q{
CONST one = 1;
VAR x, squ;
PROCEDURE superflous;
 squ := squ
;

PROCEDURE square;
BEGIN
   squ:= x * x
END;

BEGIN
   WHILE x <= 10 DO
   BEGIN
	  CALL superflous; 
      CALL square;
      IF ODD x THEN ! squ;
      x := x + one
   END
END.
}.lex.parse.optimize.genCode(false, TargetLanguage.D)
);


void main(string[] args) {
	import std.getopt;
	import std.file;
	import std.stdio;

	
	bool optimize;
	bool _debug;
	bool compile;
	bool format;
	string compiler = "clang";
	string outputFile;


	getopt(
		args, std.getopt.config.caseSensitive,
		//Flags first
		"O|optimize", &optimize,
		"debug", &_debug,
		"C|compile", &compile,
		"compiler", &compiler,
		"format", &format,
		//Arguments second
		"o|output-file", &outputFile,
	);

	if (args.length == 2) {
		auto source = readText(args[1]);
		auto lexed = lex(source);
		auto parsed = parse(lexed);

		auto analyzer = Analyzer(parsed);
		if (_debug) writeln(print(parsed));

		foreach(k,v;analyzer.stable.symbolsByName) {
			if (v.length > 1) {
				writeln("Symbol '", k, "' is Defined multiple times");
				foreach(s;v) {
					writeln ("in line ",s.d.loc.line);
				}
			}
		}

		foreach(node;analyzer.allNodes
			.filter!(n => cast(PrimaryExpression)n.node !is null)
			.filter!(n => (cast(PrimaryExpression*)&n.node).identifier !is null)) {
			auto pe = (cast(PrimaryExpression*)&node.node);
			if (analyzer.getNearestSymbol(analyzer.getParentBlock(node), pe.identifier) is null) {
				analyzer.errors ~= Analyzer._Error("Undeclared Symbol: " ~ cast(string)pe.identifier.identifier, pe.loc);
			}
		}
		foreach(node;analyzer.allNodes
			.filter!(n => cast(AssignmentStatement)n.node !is null)) {
			analyzer.isInvaildAssignment(node);
		}

		if (optimize && analyzer.errors.length == 0) {
			if (_debug) writeln("Before Inlining", analyzer.programm.print);
			
			inlineCall(&analyzer);
			if (_debug) writeln("After Inlining", analyzer.programm.print);

			rewriteConst(&analyzer);
			if (_debug) writeln("After ConstRewrite", analyzer.programm.print);

			reduceBeginEnd(&analyzer);
			if (_debug) writeln("After BeginEndReduce (1)", analyzer.programm.print);

			removeUnreferancedSymbols(&analyzer);
			if (_debug) writeln("After Removeing unreferenced Symbols (1)", analyzer.programm.print);

			eliminateVariableAssignments(&analyzer);
			if (_debug) writeln("After VariableAssignmen elimination", analyzer.programm.print);

			removeUnreferancedSymbols(&analyzer);
			if (_debug) writeln("After Removeing unreferenced Symbols (2)", analyzer.programm.print);

			reduceBeginEnd(&analyzer);
			if (_debug) writeln("After BeginEndReduce (2)", analyzer.programm.print);
		}


		
		void OutputErrors() {
			FileSource fs = new FileSource();
			fs.content = source;
			fs.filename = args[1];
			foreach(e;analyzer.errors) {
				Location loc;
				loc.source = fs; 
				loc.line = e.loc.line;
				loc.index = e.loc.absPos;
				loc.length = e.loc.length;
				outputCaretDiagnostics(loc, e.reason);
			}

		}

		
		//			writeln("Programm has ", analyzer.countBlocks(), " blocks and ", analyzer.countBeginEndStatements, " BEGIN .. END Statements.");
		//writeln(analyzer.genDot);
		//		writeln("AllVariables : ", sort(analyzer.getAllNodes.map!(i => (cast(VarDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array).uniq);
		//		writeln("AllConstants : ", sort(analyzer.getAllNodes.map!(i => (cast(ConstDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array).uniq);
		//		writeln("AllProcedures : ", sort(analyzer.getAllNodes.map!(i => (cast(ProDecl)i.node)).filter!(n => n !is null).map!(i => i.name.identifier).array));
		
		if (analyzer.errors.length > 1) {
			OutputErrors();
		}
		
		if (compile && !outputFile) {
			import std.process;
			string base_name = "__" ~ args[1];
			File tmp = File(base_name ~ ".c", "wb");
			tmp.writeln(analyzer.programm.genCode());
			tmp.flush();
			executeShell(compiler ~ " -o " ~ base_name ~ ".exe " ~ base_name ~ ".c");
			auto pid = spawnProcess("./" ~ base_name ~ ".exe" );
			wait(pid);
			executeShell("rm " ~ base_name ~ ".c");	
			//remove(tmp);
		}
		
		if (outputFile) {
			File f = File(outputFile ~ ".pl0e", "wb");
			File cf = File(outputFile ~ ".c", "wb");
			if (format) f.writeln(analyzer.programm.print());
			cf.writeln(analyzer.programm.genCode());
		}
	} else {
		writeln ("invoke like : ", args[0], " file.pl0 \n");
	}
	plMain();

	q{
		CONST one = 1;
		VAR x, squ;
		PROCEDURE superflous;
	squ := squ
			;
		
		PROCEDURE square;
		BEGIN
			squ:= x * x;
			CALL superflous
		END;
		
		BEGIN
			WHILE x <= 10 DO
				BEGIN
				CALL square;
		IF ODD x THEN ! squ;
	x := x + one
		END
				END.
	}.lex.parse.optimize.genCode.writeln;


	
}
