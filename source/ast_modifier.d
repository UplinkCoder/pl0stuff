import pl0_extended_ast;
import pl0_extended_analyzer;
import std.algorithm;

void removeStmt(Analyzer* a, Analyzer.nwp* stmt) {
	replaceStmts(a, stmt, []);
}
void replaceStmt (Analyzer* a, Analyzer.nwp* dst, Statement src) {
	if (auto bes = cast (BeginEndStatement)dst.parent.node) {
		foreach(ref stmt;bes.statements) {
			if (stmt is (*dst).node) {
				stmt = src;
				break;
			}
		}
	} else if (auto bl = cast (Block)dst.parent.node) {
		bl.statement = src;
	} else {
		debug {import std.stdio; writeln(typeid(dst.parent.node));}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}

void replaceStmts (Analyzer* a, Analyzer.nwp* dst, Statement[] src) {
	if (auto bes = cast (BeginEndStatement)dst.parent.node) {
		auto fspr = findSplit(bes.statements, [dst.node]);
		bes.statements = fspr[0] ~ src ~ fspr[2];
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
	} else if (auto as = cast (OutputStatement)dst.parent.node) {
		if (as.expr is dst.node) {
			as.expr = src;
		}
	} else if (auto pe = cast (ParenExpression)dst.parent.node) {
		if (pe.expr is dst.node) {
			pe.expr = src;
		} 
	} else if (auto rc = cast (RelCondition)dst.parent.node) {
		if (rc.lhs is dst.node) {
			rc.lhs = src;
		} else {
			rc.rhs = src;
		}
	} else if (auto oc = cast (OddCondition)dst.parent.node) {
		if (oc.expr is dst.node) {
			oc.expr = src;
		}
	} else {
		debug {import std.stdio; writeln(typeid(dst.parent.node));}
	}
	a.allNodesFilled = false;
	a.allNodes = a.getAllNodes();
}