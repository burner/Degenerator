module model.world;

struct SearchResult {
	const(Entity) entity;
	string[] path;
}

class TheWorld : Entity {
	StringEntityMap!(Actor) actors;
	StringEntityMap!(SoftwareSystem) softwareSystems;
	StringEntityMap!(HardwareSystem) hardwareSystems;
	StringEntityMap!(Type) typeContainerMapping;
	StringEntityMap!(Entity) connections;

	this(in string name) {
		super(name, null);
	}

	this(in TheWorld old) {
		super(old, null);
		foreach(const(string) name, const(Actor) act; old.actors) {
			this.actors[name] = new Actor(act, this);
		}

		foreach(const(string) name, const(SoftwareSystem) ss; old.softwareSystems) {
			this.softwareSystems[name] = new SoftwareSystem(ss, this);
		}

		foreach(const(string) name, const(HardwareSystem) hw; old.hardwareSystems) {
			this.hardwareSystems[name] = new HardwareSystem(hw, this);
		}

		foreach(const(string) name, const(Type) t; old.typeContainerMapping) {
			this.typeContainerMapping[name] = new Type(t, this);
		}
	}

	override Entity get(string[] path) {
		if(path.empty) {
			return this;
		} else {
			immutable fr = path.front;
			path = path[1 .. $];

			foreach(const(string) name, Actor act; this.actors) {
				if(name == fr) {
					return act.get(path);
				}
			}

			foreach(const(string) name, SoftwareSystem ss; this.softwareSystems) {
				if(name == fr) {
					return ss.get(path);
				}
			}

			foreach(const(string) name, HardwareSystem hw; this.hardwareSystems) {
				if(name == fr) {
					return hw.get(path);
				}
			}

			return this;
		}
	}

	auto search(const(Entity) needle) inout {
		assert(needle !is null);

		const(Entity) mnp = holdsEntityImpl(needle, this.actors,
					this.softwareSystems, this.hardwareSystems,
					this.typeContainerMapping, this.connections);

		if(mnp !is null) {
			return SearchResult(mnp, [super.name]);
		}

		const(SearchResult) dummy;
		return dummy;
	}

	Actor getOrNewActor(in string name) {
		return enforce(getOrNewEntityImpl!Actor(name, this.actors, this));
	}

	SoftwareSystem getOrNewSoftwareSystem(in string name) {
		return enforce(getOrNewEntityImpl!SoftwareSystem(name,
			this.softwareSystems, this)
		);
	}

	HardwareSystem getOrNewHardwareSystem(in string name) {
		return enforce(getOrNewEntityImpl!HardwareSystem(name,
			this.hardwareSystems, this)
		);
	}

	T getOrNew(T,F,O)(in string name, F from, O to) {
		T con =  enforce(getOrNewEntityImpl!(Entity,T)(
			name, this.connections, this
		));
		con.from = from;
		con.to = to;
		return con;
	}

	T getOrNew(T,F,O)(T toCopy, F from, O to) {
		T con =  enforce(getOrNewEntityImpl!(Entity,T)(
			toCopy.name, this.connections, this
		));
		con.from = from;
		con.to = to;
		con.description = toCopy.description;
		con.longDescription = toCopy.longDescription;

		static if(is(T == Aggregation)) {
			con.fromCnt = toCopy.fromCnt;
			con.toCnt = toCopy.toCnt;
			con.fromStore = toCopy.fromStore;
			con.toStore = toCopy.toStore;
		} else static if(is(T == Composition)) {
			con.fromCnt = toCopy.fromCnt;
			con.fromStore = toCopy.fromStore;
		}
		return con;
	}

	Type getOrNewType(in string name) {
		return enforce(getOrNewEntityImpl!(Type)(name,
			this.typeContainerMapping, null
		));
	}

	override string areYouIn(ref in StringHashSet store) const {
		return super.name in store ? super.name : "";
	}

	override const(Entity) areYouIn(ref in EntityHashSet!(Entity) store) 
			const 
	{
		if(cast(Entity)(this) in store) {
			return this;
		} else {
			return null;
		}
	}

	Entity get(string path) {
		import std.algorithm.iteration : splitter;
		string[] spath = splitter(path, ".").array;
		return this.get(spath);
	}

	void drop(in ref StringHashSet toKeep) {
		auto keys = this.softwareSystems.keys();
		foreach(key; keys) {
			if(key !in toKeep) {
				this.softwareSystems.remove(key);
			}
		}
		keys = this.actors.keys();
		foreach(key; keys) {
			if(key !in toKeep) {
				this.actors.remove(key);
			}
		}
		keys = this.hardwareSystems.keys();
		foreach(key; keys) {
			if(key !in toKeep) {
				this.hardwareSystems.remove(key);
			}
		}
	}
}
