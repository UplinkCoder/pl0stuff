import pl0_ast;


struct Analyzer {

	static struct NodeWithParentBlock {
		PLNode node;
		Block parent;
		alias node this;
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
	NodeWithParentBlock[] allNodes;
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
			.map!(n => cast(Block)n)
			.filter!(b => b !is null && (!!b.variables.length || !!b.constants.length || !!b.procedures.length))) {
			foreach(v;b.variables) {
				stable.addSymbol(SymbolTable.Symbol(v, b));
			}
			foreach(c;b.constants) {
				stable.addSymbol(SymbolTable.Symbol(c, b));
			}
			foreach(p;b.procedures) {
				stable.addSymbol(SymbolTable.Symbol(p, b));
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

	shared(Error)* isInvaildAssignment(nwp n) in {
		assert(!!cast(AssignmentStatement)n.node, "only for AssignmentStaement nwps");
	} body {
		auto as = cast(AssignmentStatement) n;
		auto nearestSymbol = getNearestSymbol(n.parent, as.name);


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
		auto allNodes = getAllNodes();
		uint result;
		foreach(beginWhileNode;allNodes.map!(n => cast(BeginEndStatement)n).filter!(bes => bes !is null)) {
			++result;
		}
		return result;
	}
	
	nwp[] getAllNodes() pure {
		static if  (true) { 
		if (allNodesFilled) {
			return allNodes;
		} else {
			allNodes = getAllNodes(programm.block, null);
		}
		return allNodes;
		} else {
			return getAllNodes(programm.block);
		}
	}
	static pure {
		nwp[] getAllNodes(Block b, Block p) {
			nwp[] result;
			result ~= nwp(b, p);
			foreach(c;b.constants) {
				result ~= getAllNodes(c, b);
			}
			foreach(v;b.variables) {
				result ~= getAllNodes(v, b);
			}
			foreach(proc;b.procedures) {
				result ~= getAllNodes(proc, b);
			}
			result ~= getAllNodes(b.statement, b);
			return result;
		}
		
		nwp[] getAllNodes(ConstDecl c, Block p) {
			return [nwp(c, p)];
		}
		nwp[] getAllNodes(VarDecl v, Block p) {
			return [nwp(v, p)];
		}
		nwp[] getAllNodes(ProDecl proc, Block p) {
			return [nwp(proc, p)] ~ getAllNodes(proc.block, p);
		}
		
		
		nwp[] getAllNodes(Statement s, Block p) {
			if (auto a = cast(AssignmentStatement)s) {
				return ([nwp(a, p), nwp(new PrimaryExpression(null, a.name, null), p)] ~ getAllNodes(a.expr, p));
			} else if (auto c = cast(CallStatement)s) {
				return [nwp(c, p)];
			} else if (auto b = cast(BeginEndStatement)s) {
				auto result = [nwp(b, p)];
				foreach(stmt;b.statements) {
					result ~= getAllNodes(stmt, p);
				}
				return result;
			} else if (auto i = cast(IfStatement)s) {
				return nwp(i, p) ~ getAllNodes(i.cond, p) ~ getAllNodes(i.stmt, p);
			} else if (auto w = cast(WhileStatement)s) {
				return nwp(w, p) ~ getAllNodes(w.cond, p) ~ getAllNodes(w.stmt, p);
			} assert(0, "We should never get here!");
		}
		
		nwp[] getAllNodes(Condition c, Block p) {
			if (auto o = cast (OddCondition)c) {
				return nwp(o, p) ~ getAllNodes(o.expr, p);
			} else if (auto r = cast(RelCondition)c) {
				return nwp(r, p) ~ getAllNodes(r.lhs, p) ~ getAllNodes(r.rhs, p);
			} else assert(0, "We should never get here!");
		}
		
		nwp[] getAllNodes(Expression e, Block p) {
			if(auto a = cast(AddExprssion) e) {
				return nwp(a, p) ~ getAllNodes(a.lhs, p) ~ getAllNodes(a.rhs, p);
			} else if(auto m = cast(MulExpression) e) {
				return nwp(m, p) ~ getAllNodes(m.lhs, p) ~ getAllNodes(m.rhs, p);
			} else if(auto pe = cast(ParenExpression) e) {
				return nwp(pe, p) ~ getAllNodes(pe.expr, p);
			} else if(auto pr = cast(PrimaryExpression) e) {
				if (pr.identifier) {
					return [nwp(pr,p)];
				} else if (pr.number) {
					return [nwp(pr,p)];
				} else if (pr.paren) {
					return nwp(pr,p) ~ getAllNodes(pr.paren, p);
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
