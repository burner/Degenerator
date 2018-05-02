import std.stdio : writeln;

import std.stdio : writeln;
import std.ascii : toLower;
import std.typecons;
import std.experimental.logger;
import containers.hashmap;

import model;
import duplicator;
import generator.graphviz;
import generator.mysql;
import generator.vibed;
import generator.angular;
import predefined.types.user;
import predefined.types.group;
import predefined.types.address;
import predefined.types.basictypes;
import predefined.ctrl.userctrl;

import predefined.angular.component;

import generator.seqts;

class NoTimeLogger : Logger {
	import std.stdio : writefln;
    this(LogLevel lv) @safe {
        super(lv);
    }

    override void writeLogMsg(ref LogEntry payload) {
		import std.string : lastIndexOf;
		auto i = payload.file.lastIndexOf("/");
		string f = payload.file;
		if(i != -1) {
			f = f[i+1 .. $];
		}
		writefln("%s:%s | %s", f, payload.line, payload.msg);
    }
}

void main() {
	sharedLog = new NoTimeLogger(LogLevel.all);

	bool ret;
	version(unittest) {
		ret = true;
	}
	if(!ret) fun2();
}

enum ST = "SeqTS";

alias ColumnNull = Flag!"ColumnNull";

void addColumn(MemberVariable mv, ColumnNull cn) {
	import std.format : format;
	mv.addLangSpecificAttribute(ST, format("@Column({allowNull: %s})",
			cn == ColumnNull.yes ? "true" : "false"));
}

struct ClassCom {
	Class cls;
	Component com;
}

ClassCom buildGroup(TheWorld world, Container be) {
	auto groupCom = be.newComponent("group");

	Class groupCls = world.newClass("Group", groupCom);
	auto mv = groupCls.newMemberVariable("name");
	mv.type = world.getType("String");
	addColumn(mv, ColumnNull.no);

	return ClassCom(groupCls, groupCom);
}

ClassCom buildUser(TheWorld world, Container be) {
	auto userCom = be.newComponent("user");

	Class userCls = world.newClass("User", userCom);
	auto mv = userCls.newMemberVariable("email");
	mv.type = world.getType("String");
	addColumn(mv, ColumnNull.no);

	return ClassCom(userCls, userCom);
}

Class junctionTable(TheWorld world, Container con, Class from, Class to) {
	Component com = con.newComponent(from.name ~ "_" ~ to.name);
	Class junction = world.newClass(from.name ~ to.name, com);
	world.newConnectionImpl!BelongsToMany(from.name, junction, from);
	world.newConnectionImpl!ForeignKey(from.name ~ "_id", from, junction);

	world.newConnectionImpl!BelongsToMany(to.name, junction, to);
	world.newConnectionImpl!ForeignKey(to.name ~ "_id", to, junction);

	return junction;
}

void fun2() {
	auto world = new TheWorld("TheWorld");
	addBasicTypes(world);

	auto system = world.newSoftwareSystem("Website");
	auto be = system.newContainer("backend");
	be.technology = ST;

	ClassCom user = buildUser(world, be);
	ClassCom group = buildGroup(world, be);

	Class userGroupJunction = junctionTable(world, be, user.cls,
			group.cls
		);

	auto seqtsGen = new SeqelizeTS(world, "SeqTSTest");
	seqtsGen.generate();

	auto gv = new GraphvicSeqTS(world, "GraphvizOutput2");
	gv.generate();
}

void fun() {
	auto world = new TheWorld("TheWorld");
	addBasicTypes(world);

	Actor users = world.newActor("The Users");
	users.description = "This is a way to long description for something "
		~ "that should be obvious.";

	Actor admin = world.newActor("The Admin");
	admin.description = "An admin does what an admin does.";

	auto system = world.newSoftwareSystem("AwesomeSoftware");
	system.description = "The awesome system to develop.";
	Container frontend = system.newContainer("Frontend");
	frontend.technology = "Angular";
	auto frontendUserCtrl = frontend.newComponent("frontUserCtrl");
	auto frontendStuffCtrl = frontend.newComponent("frontStuffCtrl");
	initAngularBaseClasses(world, frontendUserCtrl, frontendStuffCtrl);

	auto app = genAngularComponent("Main", world, frontendUserCtrl);

	auto hardware = world.newHardwareSystem("SomeHardware");

	auto system2 = world.newSoftwareSystem("LagacySoftwareSystem");
	system2.description = "You don't want to touch this.";

	auto usersFrontend = world.newConnection("userDepFrontend",
		world.getActor("The Users"), frontendUserCtrl
	);
	usersFrontend.description = "Uses the frontend to do stuff.";
	world.newConnection("userDepStuffCtrl",
		users, frontendStuffCtrl
	).description = "Uses the Stuff Logic of the Awesome Software";
	usersFrontend.description = "Uses the frontend to do stuff.";

	{
		const(TheWorld) cw = world;
		const(Actor) ca = world.getActor("The Users");
		assert(ca !is null);
	}

	world.newConnection("adminUser",
		admin, frontendUserCtrl
	).description = "Manager Users";

	Container server = system.newContainer("Server");
	server.technology = "D";
	world.newConnection("frontendServerDep", frontend, server)
		.description = "HTTPS";

	world.newConnection("serverSS2", server, system2).description =
		"To bad we have to use that.";

	auto serverUserCtrl = server.newComponent("serverUserCtrl");
	auto frontendHardwareLink = world.newConnection("frontendUsesHardware",
		serverUserCtrl, hardware
	);

	auto serverUserSub = serverUserCtrl.newSubComponent("utils").
		description = "Best component name ever!";

	auto database = system.newContainer("Database");
	database.technology = "MySQL";
	world.newConnection("serverDatabase",
		server, database
	).description = "CRUD";

	Type str = world.getType("String");
	Type integer = world.getType("Int");

	Class user = userClass(world, frontendUserCtrl, serverUserCtrl, database);
	Class group = groupClass(world, frontendUserCtrl, serverUserCtrl, database);

	Class address = addressClass(world,
		frontendUserCtrl, serverUserCtrl, database
	);

	userCtrl(world, server);

	MemberFunction func = address.newMemberFunction("func");
	func.returnType = integer;

	func.addParameter("a", integer);
	func.addParameter("b", str);

	Aggregation userAddress = world.newAggregation("AddressUser",
		address, user
	);

	Class postalCode = world.newClass("PostalCode", database,
			serverUserCtrl);
	postalCode.containerType["MySQL"] = "Table";
	MemberVariable pcID = postalCode.newMemberVariable("id");
	pcID.type = integer;
	pcID.addLangSpecificAttribute("MySQL", "PRIMARY KEY");
	pcID.addLangSpecificAttribute("MySQL", "AUTO INCREMENT");
	pcID.addLangSpecificAttribute("D", "const");
	MemberVariable pcCode = postalCode.newMemberVariable("code");
	pcCode.type = integer;

	auto addressPC = world.newComposition("addressPostalCode",
		address, postalCode
	);
	addressPC.fromType = world.newType("PostalCode[]");
	addressPC.fromType.typeToLanguage["D"] = "PostalCode[]";

	Class userInfo = genAngularService("UserInfo", world, frontendUserCtrl);

	Graphvic gv = new Graphvic(world, "GraphvizOutput");
	gv.generate();

	//MySQL mysql = new MySQL(world, "MySQL");
	//mysql.generate(database);

	//auto vibed = new VibeD(world, "VibeTestProject");
	//vibed.generate();

	auto angular = new Angular(world, "Frontend");
	angular.generate();
}
