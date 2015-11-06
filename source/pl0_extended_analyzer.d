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

		static NodeWithParentBlock opCall(ref PLNode node, NodeWithParentBlock *parent) pure {
			return NodeWithParentBlock(node, parent);
		}
	}

	static struct _Error {
		string reason;
		MyLocation loc;

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
	shared _Error[] errors;



	struct SymbolTable {
		static running_id = 0;
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

	void fillSymbolTable() {
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

	void fillParentMap() {
		void fillParentMap(Block child, Block parent) {
			parentMap[child] = parent;
			foreach(p; child.procedures) {
				fillParentMap(p.block, child);
			}
		}
		parentMap = parentMap.init;
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

	void removeSymbol(Symbol s) {
		Block b = s.definedIn;
		import std.array;
			final switch(s.type) with (Symbol.SymbolType) {
				case _VarDecl :
				auto findSplitResult = findSplit(b.variables, [s.v]);
				b.variables = findSplitResult[0] ~ findSplitResult[2];
				break;
				case _ConstDecl :
				auto findSplitResult = findSplit(b.constants, [s.c]);
				b.constants = findSplitResult[0] ~ findSplitResult[2];
				break;
				case _ProDecl :
					auto findSplitResult = findSplit(b.procedures, [s.p]);
				debug {import std.stdio;writeln(findSplitResult);}
				b.procedures = findSplitResult[0] ~ findSplitResult[2];
				break;
		}
	}

	Block getParentBlock(nwp* n) {
		nwp *parentBlock = (n);
	findParent :
		while(!cast(Block) parentBlock.node) {
			parentBlock = parentBlock.parent;
		}
		return cast (Block) parentBlock.node;
	}

	Symbol* getNearestSymbol(Block b, Identifier i) {
		auto syms = stable.symbolsByBlock.get(b, null);
		if (syms !is null) {
			import std.algorithm;
			auto s = find!(s => s.getSymbolName == i.identifier)(syms);
			if (s.length >= 1) {
				s[0].isReferenced = true;
				return &s[0];
			} else {
				//assert(0, "Symbol '" ~ i.identifier ~ "' could not be resolved unamigouisly");
				import std.stdio;
				writeln(s);
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
			return  getAllNodes(programm.block, new nwp(programm, null));
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
				return ([ap, new nwp(new PrimaryExpression(false, null, a.name, null), ap)] ~ getAllNodes(a.expr, ap));
			} else if (auto c = cast(CallStatement)s) {
				return [new nwp(c, p)];
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
				if (pr.identifier) {
					return [new nwp(pr,p)];
				} else if (pr.literal) {
					return [new nwp(pr,p)];
				} else if (pr.paren) {
					auto pp = new nwp(pr,p);
					return  pp ~ getAllNodes(pr.paren, pp);
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
