import pl0_extended_ast;

struct Analyzer {
//pure :
	struct NodeWithParentBlock {
		PLNode node;
		NodeWithParentBlock *parent;
		alias node this;

		this(PLNode node, NodeWithParentBlock *parent) pure {
			this.node = node;
			this.parent = parent;
		}

		static NodeWithParentBlock opCall(ref PLNode node, NodeWithParentBlock *parent) pure {
			return NodeWithParentBlock(node, parent);
		}
	}

	static struct _Error {
		string reason;
		MyLocation loc;
	}


	alias nwp = NodeWithParentBlock; 
	import std.algorithm : map, filter;
	import optimizer : findSplit;
	bool symbolTableFilled = false;
	bool allNodesFilled = false;

	uint stateSyncId;
	Programm programm;
	NodeWithParentBlock*[] allNodes;
	Block[Block] parentMap;
	Condition[] condStack;
	shared _Error[] errors;

	struct SymbolTable {
//	pure :
		int running_id = 0;
		static struct Symbol {
			uint id;
			Block definedIn;
			bool isReferenced;
			union {
				Declaration d;
				VarDecl v;
				ConstDecl c;
				ProDecl p;
			}
			enum SymbolType {
				_VarDecl,
				_ConstDecl,
				_ProDecl
			}
			
			SymbolType type;
			
			this(VarDecl v, Block definedIn) pure {
				this.v = v;
				this.definedIn = definedIn;
				this.type = SymbolType._VarDecl;
			}
			
			this(ConstDecl c, Block definedIn) pure {
				this.c = c;
				this.definedIn = definedIn;
				this.type = SymbolType._ConstDecl;
			}
			
			this(ProDecl p, Block definedIn) pure {
				this.p = p;
				this.definedIn = definedIn;
				this.type = SymbolType._ProDecl;
			}
			
			const (char)[] getSymbolName() pure {
				final switch(type) with (Symbol.SymbolType) {
					case _VarDecl :
						return cast(const (char)[]) v.name.identifier;
					case _ConstDecl :
						return cast(const (char)[]) c.name.identifier;
					case _ProDecl :
						return cast(const (char)[]) p.name.identifier;
				}
				
			}
		}

		void addSymbol(Symbol s) pure {
			s.id = running_id++;
			
			symbolsByName[s.getSymbolName()] ~= s;
			symbolsByBlock[s.definedIn] ~= s;
			symbolById[s.id] = s;
			
			return;
		}

		Symbol[] getSymbolsWithSameName (Symbol s) {
			return symbolsByName[s.getSymbolName];
		}

		Symbol[][string] symbolsByName;
		Symbol[][Block] symbolsByBlock;
		Symbol[uint] symbolById;
	}
	
	SymbolTable stable; 
	alias Symbol = SymbolTable.Symbol;

	void fillSymbolTable() pure {
		stable = typeof(stable).init;
		foreach(b;getAllNodes()
			.map!(n => cast(Block)n.node)
			.filter!(b => b !is null && (!!b.variables.length || !!b.constants.length || !!b.procedures.length))) {

			foreach(v;b.variables) {
				stable.addSymbol(SymbolTable.Symbol(v, b));
			}
			foreach(c;b.constants) {
				stable.addSymbol(SymbolTable.Symbol(c, b));
			}
			foreach(p;b.procedures) {
				stable.addSymbol(SymbolTable.Symbol(p, b));
				foreach(a;p.arguments) {
					stable.addSymbol(SymbolTable.Symbol(a, p.block));
				}
			}
		}
	}

	void fillParentMap() pure {
		void fillParentMap(Block child, Block parent) {
			parentMap[child] = parent;
			foreach(p; child.procedures) {
				fillParentMap(p.block, child);
			}
		}
		parentMap = parentMap.init;
		fillParentMap(programm.block, null);
	}
	
	this(const Programm programm, bool skip_analysis = false) pure {
		this.programm = cast(Programm) programm;
		if (!skip_analysis) {
			fillSymbolTable();
			fillParentMap();
			allNodes = getAllNodes();
			symbolTableFilled = true;
			allNodesFilled = true;
		}
	}

	void removeSymbol(Symbol s) pure {
		Block b = s.definedIn;
		import std.array;
			final switch(s.type) with (Symbol.SymbolType) {
				case _VarDecl :
				auto findSplitResult = findSplit!((a,b) => a is b)(b.variables, [s.v]);
				b.variables = findSplitResult[0] ~ findSplitResult[2];
				break;
				case _ConstDecl :
				auto findSplitResult = findSplit!((a,b) => a is b)(b.constants, [s.c]);
				b.constants = findSplitResult[0] ~ findSplitResult[2];
				break;
				case _ProDecl :
					auto findSplitResult = findSplit!((a,b) => a is b)(b.procedures, [s.p]);
				b.procedures = findSplitResult[0] ~ findSplitResult[2];
				break;
		}
	}

	alias getParentBlock = getParent!(Block);

	static nwp* getParentWithParent(T)(nwp *n) {
		nwp *parent = n;
	findParent :
		while(!cast(T) parent.node && parent.parent !is null) {
			parent = parent.parent;
		}
		return parent;
	}

	static T getParent(T)(nwp* n) {
		auto p = getParentWithParent!(T)(n);
		return cast(T) p.node;
	}

	nwp* getNearest(T, bool controlflowsensitive = true)(nwp* node, nwp*[] canidates) if(is(T:PLNode)) {
		nwp* currentClosestCanidate = null;
		if (auto bes = cast(BeginEndStatement) node.parent.node) {
			foreach(stmt;bes.statements) {
				if (stmt is node.node) {
					break;
				} else {
					foreach(c;canidates.filter!(n => n.parent.node is bes && !!cast(T)n.node)) {
						currentClosestCanidate = c;
					}
				}
			}
		} else if (auto bl = cast (Block) node.parent.node) {
			foreach(c;canidates.filter!(n => n.parent.node is bl && !!cast(T)n.node)) {
				currentClosestCanidate = c;
			}
		} else if (auto p = cast(Programm) node.parent.node) {
			return null;
		} else if (controlflowsensitive && (!!cast(IfStatement) node.parent.node && !!cast(WhileStatement) node.parent.node)) {
			return null;
		} else if (auto nd = cast(PLNode) node.parent.node) {
			foreach(c;canidates.filter!(n => n.parent.node is nd && !!cast(T)n.node)) {
				currentClosestCanidate = c;
			}
		} else {
			assert(0, "Unexpected Type" ~ typeid(node.parent.node).toString);
		}

		if (currentClosestCanidate !is null) {
			return currentClosestCanidate;
		} else if (node.parent !is null) {
			return getNearest!T(node.parent, canidates);
		} else {
			return null;
		}
	}

	Symbol* getNearestSymbol(Block b, Identifier i) pure {
		auto syms = stable.symbolsByBlock.get(b, null);
		if (syms !is null) {
			import std.algorithm : find;
			auto s = find!(s => s.getSymbolName == i.identifier)(syms);
			if (s.length >= 1) {
				s[0].isReferenced = true;
				return &s[0];
			} else {
				//assert(0, "Symbol '" ~ i.identifier ~ "' could not be resolved unamigouisly");
			}
		}

		if (auto p = parentMap.get(b, null)) {
			return getNearestSymbol(p, i); 
		} else {
			return null;
		}
	}

	shared(_Error)* isInvaildAssignment(nwp* n) in {
		assert(!!cast(AssignmentStatement)n.node, "only for AssignmentStaement nwps");
	} body {
		auto as = cast(AssignmentStatement) n.node;
		auto nearestSymbol = getNearestSymbol(getParentBlock(n), as.name);

		if (nearestSymbol is null) {
			errors ~= _Error("Assignment to undefined Symbol", as.loc);
			return &errors[$-1];
		} else if (nearestSymbol.type == Symbol.SymbolType._ConstDecl) {
			errors ~= _Error("Assignment to Constant", as.loc);
			return &errors[$-1];
		} else if (nearestSymbol.type == Symbol.SymbolType._ProDecl) {
			errors ~= _Error("Assignment to procedure", as.loc);
			return &errors[$-1];
		}

		return null;
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
	
	uint countBeginEndStatements() {
		uint result;
		foreach(beginWhileNode;allNodes.map!(n => cast(BeginEndStatement)(*n).node).filter!(bes => bes !is null)) {
			++result;
		}
		return result;
	}
	
	nwp*[] getAllNodes() pure {
		static if  (true) { 
		if (allNodesFilled) {
			return allNodes;
		} else {
			allNodes = getAllNodes(programm.block, new nwp(programm, null));
		}
		return allNodes;
		} else {
			return getAllNodes(programm.block, new nwp(programm, null));
		}
	}
	
	static pure {

		nwp*[] getAllNodes(Block b, nwp* p) {
			nwp*[] result;
			auto bp = new nwp(b, p);
			result ~= bp;
			foreach(c;b.constants) {
				result ~= getAllNodes(c, new nwp(c, bp));
			}
			foreach(v;b.variables) {
				result ~= getAllNodes(v, new nwp(v, bp));
			}
			foreach(proc;b.procedures) {
				result ~= getAllNodes(proc, new nwp(proc, bp));
			}
			result ~= getAllNodes(b.statement, bp);
			return result;
		}

		nwp*[] getAllNodes(ConstDecl c, nwp* p) {
			return [new nwp(c, p)];
		}
		nwp*[] getAllNodes(VarDecl v, nwp* p) {
			return [new nwp(v, p)];
		}
		nwp*[] getAllNodes(ProDecl proc, nwp* p) {
			auto np = new nwp(proc, p); 
			return [np] ~ getAllNodes(proc.block, np);
		}
		
		
		nwp*[] getAllNodes(Statement s, nwp* p) {
			if (auto a = cast(AssignmentStatement)s) {
				auto ap = new nwp(a, p);
				auto pe = new PrimaryExpression(false, null, a.name, null);
				pe.loc = a.name.loc;

				return ([ap, new nwp(pe, ap)] ~ getAllNodes(a.expr, ap));
			} else if (auto c = cast(CallStatement)s) {
				auto cp = new nwp(c, p);
				auto pe = new PrimaryExpression(false, null, c.name, null);
				pe.loc = c.name.loc;
				return [cp, new nwp(pe, cp)];
			} else if (auto b = cast(BeginEndStatement)s) {
				auto bp = new nwp(b, p);
				auto result = [bp];
				foreach(stmt;b.statements) {
					result ~= getAllNodes(stmt, bp);
				}
				return result;
			} else if (auto i = cast(IfStatement)s) {
				auto ip = new nwp(i, p);
				return  ip ~ getAllNodes(i.cond, ip) ~ getAllNodes(i.stmt, ip);
			} else if (auto w = cast(WhileStatement)s) {
				auto wp = new nwp(w, p);
				return wp ~ getAllNodes(w.cond, wp) ~ getAllNodes(w.stmt, wp);
			} else if (auto o = cast(OutputStatement)s) {
				auto op = new nwp(o, p);
				return op ~ getAllNodes(o.expr, op);
			} assert(0, "We should never get here!");
		}
		
		nwp*[] getAllNodes(Condition c, nwp* p) {
			if (auto o = cast (OddCondition)c) {
				auto op = new nwp(o, p);
				return  op ~ getAllNodes(o.expr, op);
			} else if (auto r = cast(RelCondition)c) {
				auto rp = new nwp(r, p);
				return rp ~ getAllNodes(r.lhs, rp) ~ getAllNodes(r.rhs, rp);
			} else assert(0, "We should never get here!");
		}
		
		nwp*[] getAllNodes(Expression e, nwp* p) {
			if(auto a = cast(AddExprssion) e) {
				auto ap = new nwp(a, p);
				return ap ~ getAllNodes(a.lhs, ap) ~ getAllNodes(a.rhs, ap);
			} else if(auto m = cast(MulExpression) e) {
				auto mp = new nwp(m, p);
				return  mp ~ getAllNodes(m.lhs, mp) ~ getAllNodes(m.rhs, mp);
			} else if(auto pe = cast(ParenExpression) e) {
				auto pp = new nwp(pe, p);
				return pp ~ getAllNodes(pe.expr, pp);
			} else if(auto pr = cast(PrimaryExpression) e) {
				if (pr.identifier !is null || pr.literal !is null) {
					return [new nwp(pr,p)];
				} else if (pr.paren) {
					auto pp = new nwp(pr,p);
					return  pp ~ getAllNodes(pr.paren, pp);
				} else assert(0);
			} else assert(0, "We should never get here!");
		}
	}
	
}