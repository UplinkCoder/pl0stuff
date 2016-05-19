import pl0_extended_analyzer;
import pl0_extended_ast;
import pl0_extended_printer;

auto findSplit(alias pred = "a == b", R1, R2)(R1 haystack, R2 needle) pure
if (isForwardRange!R1 && isForwardRange!R2)
{
	import std.algorithm.searching : find;
	import std.range : takeExactly;
	import std.functional;
	import std.traits;
   
    static struct Result(S1, S2) if (isForwardRange!S1 &&
                                     isForwardRange!S2)
    {
        this(S1 pre, S1 separator, S2 post)
        {
            asTuple = typeof(asTuple)(pre, separator, post);
        }
        Tuple!(S1, S1, S2) asTuple;
        bool opCast(T : bool)()
        {
            return !asTuple[1].empty;
        }
        alias asTuple this;
    }

    static if (isSomeString!R1 && isSomeString!R2
            || isRandomAccessRange!R1 && hasLength!R2)
    {
        auto balance = find!pred(haystack, needle);
        immutable pos1 = haystack.length - balance.length;
        immutable pos2 = balance.empty ? pos1 : pos1 + needle.length;
        return Result!(typeof(haystack[0 .. pos1]),
                       typeof(haystack[pos2 .. haystack.length]))(haystack[0 .. pos1],
                                                                  haystack[pos1 .. pos2],
                                                                  haystack[pos2 .. haystack.length]);
    }
    else
    {
        import std.range : takeExactly;
        auto original = haystack.save;
        auto h = haystack.save;
        auto n = needle.save;
        size_t pos1, pos2;
        while (!n.empty && !h.empty)
        {
            if (binaryFun!pred(h.front, n.front))
            {
                h.popFront();
                n.popFront();
                ++pos2;
            }
            else
            {
                haystack.popFront();
                n = needle.save;
                h = haystack.save;
                pos2 = ++pos1;
            }
        }
        return Result!(typeof(takeExactly(original, pos1)),
                       typeof(h))(takeExactly(original, pos1),
                                  takeExactly(haystack, pos2 - pos1),
                                  h);
    }
}


struct OptimizerState {
	uint stateSyncId;
	Analyzer.nwp*[][Analyzer.Symbol] AssignmentStatementsByVarSymbol;
}

import std.algorithm;
import std.range;
import std.array;
import ast_modifier;
pure :
/** run this at the last possible moment */
void eliminateVariableAssignments(Analyzer* a) {
	OptimizerState state;
	
	foreach (as_node;a.allNodes.filter!(n => cast(AssignmentStatement)n.node)) {
		auto as = cast(AssignmentStatement)as_node.node;
		if (auto pe = cast(PrimaryExpression) (as.expr)) {
			//Assignments to itself get eliminated directly!
			if (pe.identifier && pe.identifier.identifier == as.name.identifier) {
				removeStmt(a, as_node);
				continue;
				// do not consider statement;
			}
		}
		auto varSymbol = a.getNearestSymbol(a.getParentBlock(as_node), as.name);
		assert (varSymbol !is null && varSymbol.type == Analyzer.Symbol.SymbolType._VarDecl);
		state.AssignmentStatementsByVarSymbol[*varSymbol] ~= as_node;
	}
	//	}

	foreach (pe_node;a.allNodes.filter!(n => cast(PrimaryExpression)n.node 
			&& (cast(PrimaryExpression)n.node).identifier)) {
		auto pe = cast(PrimaryExpression)pe_node.node;
		auto varSymbol = a.getNearestSymbol(a.getParentBlock(pe_node), pe.identifier);
		assert(varSymbol);
		if (varSymbol.type == Analyzer.Symbol.SymbolType._VarDecl) {
			if (auto _pe = cast(PrimaryExpression)(cast(AssignmentStatement*)&(state.AssignmentStatementsByVarSymbol[*varSymbol][0].node)).expr) {
				if (!varSymbol.v._init && _pe.literal !is null) {
					removeStmt(a, state.AssignmentStatementsByVarSymbol[*varSymbol][0]);
					varSymbol.v._init = _pe;
					continue;
				}
			}
			auto as_node = a.getNearest!(AssignmentStatement)(Analyzer.getParentWithParent!(Statement)(pe_node), state.AssignmentStatementsByVarSymbol[*varSymbol]);
			if (as_node !is null) {
				auto as = cast(AssignmentStatement)as_node.node;
				if (auto pas = Analyzer.getParent!(AssignmentStatement)(pe_node)) {
					continue;
				}
				//writeln(as.print);
				replaceExpr(a, pe_node, as.expr);
				removeStmt(a, as_node);
			}
		} else {
			continue;
		}
	}

}

void reduceBeginEnd(Analyzer* a) {
	foreach (be_node;a.allNodes.filter!(n => cast(BeginEndStatement)n.node
			&& (((cast(BeginEndStatement)(n.node)).statements.length == 1)
				|| cast(BeginEndStatement)n.parent.node))) {
		auto be = cast(BeginEndStatement)be_node.node;
		if (be.statements.length == 1) {
			replaceStmt(a, be_node, be.statements[0]);
		} else {
			// we can merge with parent
			auto pbe = cast(BeginEndStatement)(be_node.parent.node);
			replaceStmts(a, be_node, be.statements);
		}
	}
}

void inlineCall(Analyzer* a) {
	foreach (cs_node;a.allNodes.filter!(n => cast(CallStatement)n.node)) {
		auto c = cast(CallStatement) cs_node.node;
		
		auto procSymbol = a.getNearestSymbol(a.getParentBlock(cs_node), c.name);
		assert(procSymbol !is null && procSymbol.type == Analyzer.Symbol.SymbolType._ProDecl);
		ProDecl procedure = procSymbol.p;
		if (!procedure.block.variables && !procedure.block.constants && !procedure.block.procedures) {
			replaceStmt(a, cs_node, procedure.block.statement);
		} else 	{
			// don't replace the call with the procedures body if there are variables and stuff
		}
		
	}
}

void rewriteConst(Analyzer *a) {
	foreach(pe_node;a.allNodes
		.filter!(n => cast(PrimaryExpression)n.node !is null)
		.filter!(n => (cast(PrimaryExpression)n.node).identifier !is null))
	{
		auto s = a.getNearestSymbol(a.getParentBlock(pe_node), (cast(PrimaryExpression)pe_node.node).identifier);
		if (s !is null && s.type == Analyzer.Symbol.SymbolType._ConstDecl) {
			replaceExpr(a, pe_node, s.c._init);
		}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}

void removeUnreferancedSymbols(Analyzer *a) {
	auto UsedSymbolIds = getAllUsedSymbolIds(a);
	UsedSymbolIds = assumeSorted(UsedSymbolIds).release;
	
	if (UsedSymbolIds.length != a.stable.symbolById.length) {
		foreach(id; 0 .. cast (uint) a.stable.symbolById.length) {
			if (!UsedSymbolIds.length || id != UsedSymbolIds[0]) {
				a.removeSymbol(a.stable.symbolById[id]);
			} else {
				UsedSymbolIds = UsedSymbolIds [1 .. $];
			}
		}
		a.allNodesFilled = false;
		a.allNodes = a.getAllNodes();
		a.fillSymbolTable();
	}
}

uint[] getAllUsedSymbolIds(Analyzer* a) {
	uint[] usedIds;
	
	//first loop over all PrimaryExpressions
	foreach(pe_node;a.allNodes
		.filter!(n => cast(PrimaryExpression)n.node !is null)
		.filter!(n => (cast(PrimaryExpression)n.node).identifier !is null))
	{
		auto s = a.getNearestSymbol(Analyzer.getParentBlock(pe_node), (cast(PrimaryExpression)pe_node.node).identifier);
		if (s !is null) {
			usedIds ~= s.id; 
		}
	}
	//then loop over all call statements
	foreach(cs_node;a.allNodes
		.filter!(n => cast(CallStatement)n.node !is null))
	{
		auto s = a.getNearestSymbol(Analyzer.getParentBlock(cs_node), (cast(CallStatement*)&cs_node.node).name);
		if (s !is null) {
			usedIds ~= s.id; 
		}
	}
	
	return sort(usedIds).uniq.array;
}


Programm optimize(const Programm src) pure {
	Programm result;
	auto analyzer = Analyzer(src); 
	rewriteConst(&analyzer);
	inlineCall(&analyzer);
	reduceBeginEnd(&analyzer);
	removeUnreferancedSymbols(&analyzer);
	eliminateVariableAssignments(&analyzer);
	removeUnreferancedSymbols(&analyzer);
	
	return analyzer.programm;
}