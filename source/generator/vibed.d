module generator.vibed;

import generator;
import model;

class VibeD : Generator {
	import std.exception : enforce;

	const(string) outputDir;

	this(in TheWorld world, in string outputDir) {
		super(world);
		this.outputDir = outputDir;
		enforce(Generator.createFolder(outputDir));
	}

	override void generate() {
	}

	void generate(in Container con) {
		import std.stdio : stdout;
		auto ltw = stdout.lockingTextWriter();
		foreach(const(string) cn, const(Component) com; con.components) {
			this.generate(ltw, com);
		}

		foreach(const(string) cn, const(Class) cls; con.classes) {
			this.generate(ltw, cls);
		}
	}

	void generate(Out)(ref Out ltw, in Component com) {
		foreach(const(string) cn, const(Component) scom; com.subComponents) {
			this.generate(ltw, scom);
		}

		foreach(const(string) cn, const(Class) cls; com.classes) {
			this.generate(ltw, cls);
		}
	}

	void generate(Out)(ref Out ltw, in Class cls) {
		import std.range : isInputRange;
		generate(ltw, cast(ProtectedEntity)cls);
		format(ltw, 0, "%s %s {\n", cls.containerType.get("D", "class"), 
			cls.name
		);

		auto mvs = MemRange!(MemberVariable)(&cls.members);
		//static assert(isInputRange!(typeof(mvs)));
		pragma(msg, typeof(mvs));
		auto f = mvs.front();
		pragma(msg, typeof(f));
		//foreach(mv; mvs) {
		//for(auto mv = mvs.front; !mvs.empty; mvs.popFront()) {
		//	format(ltw, 1, "%s\n", mv.name);
		//}

		format(ltw, 0, "}\n");
	}

	void generate(Out)(ref Out ltw, in ProtectedEntity pe, in int indent = 0) {
		if("D" in pe.protection) {
			format(ltw, indent, "%s ", pe.protection["D"]);
		}
	}
}

struct MemRange(T) {
	import std.array : empty, front;

	const(StringEntityMap!(Member))* mem;
	string[] names;

	this(const(StringEntityMap!(Member))* m) {
		this.mem = m;
		this.names = this.mem.keys();
		this.step();
	}

	void step() {
		while(!this.names.empty) {
			string n = this.names[0];
			if(cast(T)(mem.get(n,null))) {
				break;
			} else {
				this.names = this.names[1 .. $];
			}
		}
	}

	@property bool empty() const nothrow {
		return this.names.empty;
	}

	@property T front() {
		return cast(T)(this.mem.get(this.names.front,null));
	}

	void popFront() {
		this.step();
	}
}
