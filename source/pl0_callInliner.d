version = Extended;
version (Extended) {
	import pl0_extended_analyzer;
	import pl0_extended_ast;
	import pl0_extended_printer;
} else {
	import pl0_ast;
	import pl0_analyzer;
}

struct CallInliner {
	Analyzer* a;

	void inlineCall(Analyzer.nwp *csn/*CallStatement c*/) {
		auto c = cast(CallStatement) *csn;
		assert(c !is null, "Unexpected NodeType: " ~ typeid(csn.node).stringof);
		if (auto s = c.name.identifier in a.stable.symbolsByName) {
			Analyzer.Symbol[] procSymbols = a.stable.symbolsByName[cast(string)c.name.identifier];
			assert(procSymbols.length == 1 && procSymbols[0].type == Analyzer.Symbol.SymbolType._ProDecl);
			ProDecl procedure = procSymbols[0].p;
			replaceStmt(csn, procedure.block.statement);
//			x = cast(CallStatement*)new CallStatement(new Identifier(cast(char[])"thisOtherFunction"), null);
		}

		return;
		//mergeBlockSymbols(procedure.block, csn.parent);
		//Programm result = p.clone;
	}
}

//void replaceNode (PLNode dst, PLNode src) {
//
//}

void replaceStmt (Analyzer.nwp* dst, Statement src) {
		if (auto bes = cast (BeginEndStatement)dst.parent.node) {
			foreach(ref stmt;bes.statements) {
				if (stmt is (*dst).node) {
					stmt = src;
					return;
				}
			}
			assert(0, "src cold not be found");
	} else if (auto bl = cast (Block)(*(*dst).parent).node) {
		bl.statement = src;
	} else {
		debug {import std.stdio; writeln(typeid(dst.parent.node));}
	}
}

void reduceBeginEnd(Analyzer.nwp* n/*BeginEndStatement s*/) {
	auto be = cast(BeginEndStatement) n.node;
	assert(be !is null, "Unexpected NodeType: " ~ typeid(n.node).stringof);
	debug {import std.stdio;writeln(be.statements.length);}
	if (be.statements.length == 1) {
		replaceStmt(n, be.statements[0]);
	}
}