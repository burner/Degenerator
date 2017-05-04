module generator.angular2;

import std.experimental.logger;

import generator.cstyle;

class Angular2 : CStyle {
	import predefined.angular.component;
	import std.uni : toLower;
	import util;

	this(in TheWorld world, in string outputDir) {
		super(world, outputDir);
	}

	override void generate() {
		super.generate("Angular2");
	}

	override string genFileName(const(Class) cls) {
		if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularService(super.world)).empty) 
		{
			return toLower(cls.name) ~ ".service.base.ts";
		} else if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularComponent(super.world)).empty) 
		{
			return toLower(cls.name) ~ ".component.base.ts";
		} else if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularDirective(super.world)).empty) 
		{
			return toLower(cls.name) ~ ".directive.base.ts";
		} else if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularPipe(super.world)).empty) 
		{
			return toLower(cls.name) ~ ".pipe.base.ts";
		} else {
			return toLower(cls.name) ~ ".base.ts";
		}
		assert(false);
	}

	override void generateClass(LTW ltw, const(Class) cls) {
		if(cls.doNotGenerate == DoNotGenerate.yes) {
			return;
		}

		this.generateImports(ltw, cls);
		if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularService(super.world)).empty) 
		{
			this.generateNgService(ltw, cls);
		} else if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularComponent(super.world)).empty) 
		{
			this.generateNgComponent(ltw, cls);
		} else if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularEnum(super.world)).empty) 
		{
			this.generateNgEnum(ltw, cls);
		} else {
			generateNgClass(ltw, cls);
		}

		this.generateMembers(ltw, cls);
		this.generateMemberFunctions(ltw, cls);
		format(ltw, 0, "\n");
		this.generateCtor(ltw, cls, FilterConst.no);
		format(ltw, 0, "\n");
		this.generateCtor(ltw, cls, FilterConst.yes);
		format(ltw, 0, "}\n");
	}

	void generateImports(LTW ltw, const(Class) cls) {
		import model.connections : Dependency;
		if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularService(super.world)).empty) 
		{
			format(ltw, 0, "import { Injectable } from '@angular/core';\n");
		}
		if(!entityRangeFromTo!(Dependency)(
					&this.world.connections, cls,
					getAngularComponent(super.world)).empty) 
		{
			format(ltw, 0, "import { Component, OnInit } from '@angular/core';" ~
				"\n"
			);
		}
	}

	override void generateAggregation(LTW ltw, in Aggregation agg) {
	}

	void generateMemberFunctions(LTW ltw, const(Class) cls) {
	}

	void generateMembers(LTW ltw, const(Class) cls) {
		auto mvs = MemRange!(const(MemberVariable))(cls.members);
		foreach(mv; mvs) {
			chain(
				this.generateProtectedEntity(ltw, 
					cast(const(ProtectedEntity))(mv), 1),
				"In Member with name", mv.name, "."
			);
			format(ltw, 0, "%s : ", mv.name);
			chain(
				this.generateType(ltw, cast(const(Type))(mv.type)),
				"In Member with name", mv.name, "."
			);
			format(ltw, 0, ";\n");
		}
	}

	void generateCtor(LTW ltw, in Class cls, const FilterConst fc) {
		import std.array : appender;
		import std.algorithm.iteration : filter;
		import std.range.primitives : walkLength;

		size_t wl = 0;
		if(fc == FilterConst.yes) {
			wl = MemRange!(const MemberVariable)(cls.members)
					.filter!(a => !isConst(a))
					.walkLength;
		} else if(fc == FilterConst.no) {
			wl = MemRange!(const MemberVariable)(cls.members)
					.walkLength;
		}

		if(wl == 0) {
			return;
		}

		bool first = true;

		format(ltw, 1, "constructor(");
		foreach(mv; MemRange!(const MemberVariable)(cls.members)) {
			if(fc == FilterConst.yes && isConst(mv)) {
				continue;
			}
			if(!first) {
				format(ltw, 0, ", ");
			}
			first = false;
			//chain(
				this.generateProtectedEntity(ltw, mv, 0)
					;
				//, "In Member with name", mv.name, "."
			//);
			format(ltw, 0, "%s : ", mv.name);
			generateType(ltw, mv.type);
		}

		format(ltw, 0, ") {\n");

		foreach(mv; MemRange!(const MemberVariable)(cls.members)) {
			if(fc == FilterConst.yes && isConst(mv)) {
				continue;
			}
			format(ltw, 2, "this.%s = %s;\n", mv.name, mv.name);
		}
		foreach(con; entityRangeFrom!(const(Composition))(&this.world.connections, cls)) {
			assert(con.from is cls);
			format(ltw, 2, "this.%s = %1$s;\n", con.name);
		}
		format(ltw, 1, "}\n");
	}

	void generateProtectedEntity(LTW ltw, in ProtectedEntity pe, 
			in int indent = 0) 
	{
		super.generateProtectedEntity(ltw, pe, "Angular", indent);
	}

	void generateType(Out)(ref Out ltw, in Type type, in int indent = 0) {
		super.generateType(ltw, type, "Angular", indent);
	}	

	bool isConst(in Member mem) {
		return super.isConst(mem, "Angular");
	}

	void generateNgEnum(LTW ltw, const(Class) cls) {
		format(ltw, 0, "export Enum %s {\n", cls.name);
	}

	void generateNgClass(LTW ltw, const(Class) cls) {
		format(ltw, 0, "export class %s {\n", cls.name);
	}

	void generateNgService(LTW ltw, const(Class) cls) {
		format(ltw, 0, 
		    "\nabstract export class %sServiceBase {\n" ~
		    "\tconstructor() { }\n"
			, cls.name
		);
	}

	void generateNgComponent(LTW ltw, const(Class) cls) {
		format(ltw, 0,
			"\nabstract class %1$sComponentBase implements OnInit {\n" ~
		    "\tconstructor() { }\n"
			, cls.name
		);

		format(ltw, 1, "abstract ngOnInit();\n");
	}
}
