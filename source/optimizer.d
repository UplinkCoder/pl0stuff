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
		{
			auto procSymbol = a.getNearestSymbol(a.getParentBlock(csn), c.name);
			assert(procSymbol !is null && procSymbol.type == Analyzer.Symbol.SymbolType._ProDecl);
			ProDecl procedure = procSymbol.p;
			if (!procedure.block.variables && !procedure.block.constants && !procedure.block.procedures) {
				replaceStmt(a, csn, procedure.block.statement);
			} else 	{
				// don't replace the call with the procedures body if there are variables and stuff
			}
		}
		
		return;
		//mergeBlockSymbols(procedure.block, csn.parent);
		//Programm result = p.clone;
	}
}

//void replaceNode (PLNode dst, PLNode src) {
//
//}

void replaceStmt (Analyzer* a, Analyzer.nwp* dst, Statement src) {
	if (auto bes = cast (BeginEndStatement)dst.parent.node) {
		foreach(ref stmt;bes.statements) {
			if (stmt is (*dst).node) {
				stmt = src;
				break;
			}
		}
	} else if (auto bl = cast (Block)(*(*dst).parent).node) {
		bl.statement = src;
	} else {
		debug {import std.stdio; writeln(typeid(dst.parent.node));}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}

void replaceExpr (Analyzer* a, Analyzer.nwp* dst, Expression src) {
	if (auto ae = cast (AddExprssion)dst.parent.node) {
		if (ae.lhs is dst.node) {
			ae.lhs = src;
		} else {
			ae.rhs = src;
		}
	} else if (auto me = cast (MulExpression)dst.parent.node) {
		if (me.lhs is dst.node) {
			me.lhs = src;
		} else {
			me.rhs = src;
		}
	} else if (auto as = cast (AssignmentStatement)dst.parent.node) {
		if (as.expr is dst.node) {
			as.expr = src;
		}
	} else {
		debug {import std.stdio; writeln(typeid(dst.parent.node));}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}


void reduceBeginEnd(Analyzer* a, Analyzer.nwp* n/*BeginEndStatement s*/) {
	auto be = cast(BeginEndStatement) n.node;
	assert(be !is null, "Unexpected NodeType: " ~ typeid(n.node).stringof);
	if (be.statements.length == 1) {
		replaceStmt(a, n, be.statements[0]);
	}
}

import std.algorithm;
import std.range;
import std.array;
void rewriteConst(Analyzer *a) {
	foreach(pe_node;a.allNodes
		.filter!(n => cast(PrimaryExpression)n.node !is null)
		.filter!(n => (cast(PrimaryExpression*)&n.node).identifier !is null))
	{
		auto s = a.getNearestSymbol(a.getParentBlock(pe_node), (cast(PrimaryExpression*)&pe_node.node).identifier);
		if (s !is null && s.type == Analyzer.Symbol.SymbolType._ConstDecl) {
			debug {import std.stdio;writeln("rewriting Const ",s.c.name.identifier);}
			replaceExpr(a, pe_node, s.c.init);
		}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}

void removeUnreferancedSymbols(Analyzer *a) {
	auto UsedSymbolIds = getAllUsedSymbolIds(a);
	UsedSymbolIds = assumeSorted(UsedSymbolIds).release;
	
	if (UsedSymbolIds.length != a.stable.symbolById.length) {
		foreach(id; 0 .. a.stable.symbolById.length) {
			if (!UsedSymbolIds.length || id != UsedSymbolIds[0]) {
				a.removeSymbol(a.stable.symbolById[id]);
			} else {
				UsedSymbolIds = UsedSymbolIds [1 .. $];
			}
		}
		a.allNodesFilled = false;
		a.allNodes = a.getAllNodes();
	}
}

uint[] getAllUsedSymbolIds(Analyzer* a) {
	uint[] usedIds;
	
	//first loop over all PrimaryExpressions
	foreach(pe_node;a.allNodes
		.filter!(n => cast(PrimaryExpression)n.node !is null)
		.filter!(n => (cast(PrimaryExpression*)&n.node).identifier !is null))
	{
		auto s = a.getNearestSymbol(a.getParentBlock(pe_node), (cast(PrimaryExpression*)&pe_node.node).identifier);
		if (s !is null) {
			usedIds ~= s.id; 
		}
	}
	//then loop over all call statements
	foreach(cs_node;a.allNodes
		.filter!(n => cast(CallStatement)n.node !is null))
	{
		auto s = a.getNearestSymbol(a.getParentBlock(cs_node), (cast(CallStatement*)&cs_node.node).name);
		if (s !is null) {
			usedIds ~= s.id; 
		}
	}
	
	return sort(usedIds).uniq.array;
}