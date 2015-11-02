import pl0_ast;

struct Analyzer {
	Programm programm;

	this(Programm programm) {
		this.programm = programm;
	}


	uint countBlocks() {
		return countBlocks(programm.block);
	}
	
	uint countBlocks(Block b) {
		uint a = 1;
		foreach(p;b.procedures) {
			a += countBlocks(p.block);
		}
		return a;
	}

//	uint nestingLevel (Block b) {
//		uint level = 0;
//		Block _b = programm.block;
//		if (b == _b) {
//			return level;
//		} else {
//			level++;
//			foreach(p;_b.procedures) {
//
//			}
//		}
//	}

}

pure :
PLNode[] getAllNodes(Programm p) {
	PLNode[] result = [p];
	result ~= getAllNodes(p.block);
	return result;
}

PLNode[] getAllNodes(Block b) {
	PLNode[] result;
	result ~= b;
	foreach(c;b.constants) {
		result ~= getAllNodes(c);
	}
	foreach(v;b.variables) {
		result ~= getAllNodes(v);
	}
	foreach(p;b.procedures) {
		result ~= getAllNodes(p);
	}
	result ~= getAllNodes(b.statement);
	return result;
}

PLNode[] getAllNodes(ConstDecl c) {
	PLNode[] result;
	result ~= [c, c.name, c.number];
	return result;
}
PLNode[] getAllNodes(VarDecl v) {
	PLNode[] result;
	result ~= [v, v.name];
	return result;
}
PLNode[] getAllNodes(ProDecl p) {
	PLNode[] result;
	result ~= [p, p.name] ~ getAllNodes(p.block);
	return result;
}


PLNode[] getAllNodes(Statement s) {
	if (auto a = cast(AssignmentStatement)s) {
		return [a, a.name, a.expr];
	} else if (auto c = cast(CallStatement)s) {
		return [c, c.name];
	} else if (auto b = cast(BeginEndStatement)s) {
		PLNode[] result = [b];
		foreach(stmt;b.statements) {
			result ~= getAllNodes(stmt);
		}
		return result;
	} else if (auto i = cast(IfStatement)s) {
		return i ~ getAllNodes(i.cond) ~ getAllNodes(i.stmt);
	} else if (auto w = cast(WhileStatement)s) {
		return w ~ getAllNodes(w.cond) ~ getAllNodes(w.stmt);
	} assert(0, "We should never get here!");
}

PLNode[] getAllNodes(Condition c) {
	if (auto o = cast (OddCondition)c) {
		return o ~ getAllNodes(o.expr);
	} else if (auto r = cast(RelCondition)c) {
		return r ~ getAllNodes(r.lhs) ~ getAllNodes(r.rhs);
	} else assert(0, "We should never get here!");
}

PLNode[] getAllNodes(Expression e) {
	if(auto a = cast(AddExprssion) e) {
		return a ~ getAllNodes(a.lhs) ~ getAllNodes(a.rhs);
	} else if(auto m = cast(MulExpression) e) {
		return m ~ getAllNodes(m.lhs) ~ getAllNodes(m.rhs);
	} else if(auto p = cast(ParenExpression) e) {
		return p ~ getAllNodes(p.expr);
	} else if(auto pr = cast(PrimaryExpression) e) {
		if (pr.identifier) {
			return [pr, pr.identifier];
		} else if (pr.number) {
			return [pr, pr.number];
		} else if (pr.paren) {
			return pr ~ getAllNodes(pr.paren);
		} else assert(0);
	} else assert(0, "We should never get here!");
}