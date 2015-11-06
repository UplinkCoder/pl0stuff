import pl0_extended_ast;
import pl0_extended_ast;


struct Analyzer {

	struct NodeWithParentBlock {
		PLNode node;
		NodeWithParentBlock *parent;
		alias node this;

		this(PLNode node, NodeWithParentBlock *parent) pure {
			this.node = node;
			this.parent = parent;
		}

		static NodeWithParentBlock opCall(PLNode node, NodeWithParentBlock *parent) pure {
			return NodeWithParentBlock(node, parent);
		}
	}

	static struct Error {
		string reason;
		Location loc;

		string toString(string source)  shared {
			import std.format;
			return format("!Error! in line %d: %s\n %s", loc.line, reason, source[loc.absPos .. loc.absPos + loc.length]); 
		}
	}


	alias nwp = NodeWithParentBlock; 
	import std.algorithm;
	bool symbolTableFilled = false;
	bool allNodesFilled = false;
	
	Programm programm;
	NodeWithParentBlock*[] allNodes;
	Block[Block] parentMap;
	shared Error[] errors;



	struct SymbolTable {
		static running_id = 1;
		static struct Symbol {
			uint id;
			union {
				Declaration d;
				VarDecl v;
				ConstDecl c;
				ProDecl p;
			}
			Block definedIn;
			enum SymbolType {
				_VarDecl,
				_ConstDecl,
				_ProDecl
			}
			
			SymbolType type;
			
			this(VarDecl v, Block definedIn) {
				this.v = v;
				this.definedIn = definedIn;
				this.type = SymbolType._VarDecl;
			}
			
			this(ConstDecl c, Block definedIn) {
				this.c = c;
				this.definedIn = definedIn;
				this.type = SymbolType._ConstDecl;
			}
			
			this(ProDecl p, Block definedIn) {
				this.p = p;
				this.definedIn = definedIn;
				this.type = SymbolType._ProDecl;
			}
			
			const (char)[] getSymbolName() {
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

		void addSymbol(Symbol s) {
			s.id = running_id++;
			
			symbolsByName[s.getSymbolName()] ~= s;
			symbolsByBlock[s.definedIn] ~= s;
			
			return;
		}

		Symbol[] getSymbolsWithSameName (Symbol s) {
			return symbolsByName[s.getSymbolName];
		}

		Symbol[][string] symbolsByName;
		Symbol[][Block] symbolsByBlock;
	}
	
	SymbolTable stable; 
	alias Symbol = SymbolTable.Symbol;

	void fillSymbolTable() {
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

	void fillParentMap() {
		void fillParentMap(Block child, Block parent) {
			
			parentMap[child] = parent;
			foreach(p; child.procedures) {
				fillParentMap(p.block, child);
			}
		}
		
		fillParentMap(programm.block, null);
	}
	
	this(Programm programm, bool skip_analysis = false) {
		this.programm = programm;
		if (!skip_analysis) {
			fillSymbolTable();
			fillParentMap();
			allNodes = getAllNodes();
			symbolTableFilled = true;
			allNodesFilled = true;
		}
	}

	Symbol* getNearestSymbol(Block b, Identifier i) {
		auto syms = stable.symbolsByBlock.get(b, null);
		if (syms !is null) {
			import std.algorithm;
			auto s = find!(s => s.getSymbolName == i.identifier)(syms);
			if (s.length) {
				return &s[0];
			}
		}

		if (auto p = parentMap.get(b, null)) {
			return getNearestSymbol(p, i); 
		} else {
			return null;
		}
	}

	shared(Error)* isInvaildAssignment(nwp* n) in {
		assert(!!cast(AssignmentStatement)n.node, "only for AssignmentStaement nwps");
	} body {
		auto as = cast(AssignmentStatement) n.node;
		nwp *parent = (n);
	findParent :
		while(!cast(Block)(*parent).node) {
			parent = (*parent).parent;
		}

		auto nearestSymbol = getNearestSymbol(cast(Block)(*parent).node, as.name);

		if (nearestSymbol is null) {
			errors ~= Error("Assignment to undefined Symbol", as.loc);
			return &errors[$-1];
		} else if (nearestSymbol.type == Symbol.SymbolType._ConstDecl) {
			errors ~= Error("Assignment to Constant", as.loc);
			return &errors[$-1];
		} else if (nearestSymbol.type == Symbol.SymbolType._ProDecl) {
			errors ~= Error("Assignment to procedure", as.loc);
			return &errors[$-1];
		}

		return null;
	}

	
	//	Block getNearestBlock(Block bl, Block[] blocks) {
	//		Block nearestBlock;
	//		uint nearestLevel = uint.max;
	//		foreach(b;blocks) {
	//			if (b is bl) {
	//				return b;
	//			} else {
	//				uint nearnessLevel = getNearnessLevel(bl, b);
	//				if (nearnessLevel < nearestLevel) {
	//					nearestBlock = b;
	//					nearestLevel = nearnessLevel;
	//				}
	//			}
	//		}
	//
	//		assert(nearestBlock, "if this happens you screwed up my friend");
	//		return nearestBlock;
	//	}
	//
	//	uint getNearnessLevel(Block b1, Block b2) {
	//
	//	}
	
	string genDot() {
		import std.conv:to;
		uint runningBlockNumber;
		string result = "digraph {\n\tProgramm -> ";
		Block[] parents;
		Block currentBlock = programm.block;
		
	procedure_search : foreach(pd;currentBlock.procedures) {
			parents ~= currentBlock;
			currentBlock = pd.block;
			runningBlockNumber++;
			
			result ~= "procedure_" ~ pd.name.identifier ~ "\n\t";
			
			if (pd.block.procedures) {
				parents ~= currentBlock;
				currentBlock = pd.block;
				result ~= "procedure_" ~ pd.name.identifier ~ " -> ";
			} else if (parents[$-1] is programm.block) {
				result ~= "Programm -> ";
			}
		}
		
		result ~= "}";
		
		return result;
		
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
		foreach(beginWhileNode;allNodes.map!(n => cast(BeginEndStatement)n.node).filter!(bes => bes !is null)) {
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
			return getAllNodes(programm.block);
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
				return ([new nwp(a, p), new nwp(new PrimaryExpression(false, null, a.name, null), p)] ~ getAllNodes(a.expr, p));
			} else if (auto c = cast(CallStatement)s) {
				return [new nwp(c, p)];
			} else if (auto b = cast(BeginEndStatement)s) {
				auto result = [new nwp(b, p)];
				foreach(stmt;b.statements) {
					result ~= getAllNodes(stmt, new nwp(b, p));
				}
				return result;
			} else if (auto i = cast(IfStatement)s) {
				return new nwp(i, p) ~ getAllNodes(i.cond, new nwp(i, p)) ~ getAllNodes(i.stmt, new nwp(i, p));
			} else if (auto w = cast(WhileStatement)s) {
				return new nwp(w, p) ~ getAllNodes(w.cond, new nwp(w, p)) ~ getAllNodes(w.stmt, new nwp(w, p));
			} else if (auto o = cast(OutputStatement)s) {
				return new nwp(o, p) ~ getAllNodes(o.expr, new nwp(o, p));
			} assert(0, "We should never get here!");
		}
		
		nwp*[] getAllNodes(Condition c, nwp* p) {
			if (auto o = cast (OddCondition)c) {
				return new nwp(o, p) ~ getAllNodes(o.expr, new nwp(o, p));
			} else if (auto r = cast(RelCondition)c) {
				return new nwp(r, p) ~ getAllNodes(r.lhs, new nwp(r, p)) ~ getAllNodes(r.rhs, new nwp(r, p));
			} else assert(0, "We should never get here!");
		}
		
		nwp*[] getAllNodes(Expression e, nwp* p) {
			if(auto a = cast(AddExprssion) e) {
				return new nwp(a, p) ~ getAllNodes(a.lhs, new nwp(a, p)) ~ getAllNodes(a.rhs, new nwp(a, p));
			} else if(auto m = cast(MulExpression) e) {
				return new nwp(m, p) ~ getAllNodes(m.lhs, new nwp(m, p)) ~ getAllNodes(m.rhs, new nwp(m, p));
			} else if(auto pe = cast(ParenExpression) e) {
				return new nwp(pe, p) ~ getAllNodes(pe.expr, new nwp(pe, p));
			} else if(auto pr = cast(PrimaryExpression) e) {
				if (pr.identifier) {
					return [new nwp(pr,p)];
				} else if (pr.literal) {
					return [new nwp(pr,p)];
				} else if (pr.paren) {
					return new nwp(pr,p) ~ getAllNodes(pr.paren, new nwp(pr, p));
				} else assert(0);
			} else assert(0, "We should never get here!");
		}
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
