module language.classes;

import pegged.grammar;
import language.helper;

mixin(grammar(`
UML:
	Start < (Comment / ClassStart / Context / RealNote)+

	Note < :":" NoteText+
	NoteText <- Text+

	ClassStart < Class
	Class < ClassPrefix StereoTypes? ClassBody?
	ClassPrefix < ClassType ClassName
	ClassType < "class" / "struct" / "enum" / "interface"
	ClassName < identifier
	ClassBody < :'{' ClassDecls* :'}'
	ClassDecls < Method / Member / Seperator

	GenericConstraint < '<' String '>'

	ArrowSign < '<' / '>'

	Context < LeftIdentifier CardinalityLeft? Arrow CardinalityRight?  RightIdentifier ContextNote?
	ContextNote < Note? ArrowSign?
	CardinalityLeft < Cardinality
	CardinalityRight < Cardinality
	Cardinality < String
	Arrow < Left? Line Right?
	Left < ExtensionLeft / CompositionLeft / AggregationLeft
	Right < ExtensionRight / CompositionRight / AggregationRight
	LeftIdentifier < ^identifier
	RightIdentifier < ^identifier
	ExtensionLeft < "<|"
	ExtensionRight < "|>"
	CompositionLeft < "*"
	CompositionRight < "*"
	AggregationLeft < "o"
	AggregationRight < "o"
	Line < Dotted / Dashed
	Dotted < ".."
	Dashed < "--"

	Method < AbstractStatic? Protection? Type MethodName :'(' ParameterList?  :')' Note*
	Protection < '-' / '#' / '~' / '+'
	Type < Modifier ( '(' Type ')' ) / ^identifier
	MethodName < identifier
	Modifier < "const" / "in" / "out" / "ref" / "immutable" 
	ParameterList < Parameter (',' ParameterList)?
	Parameter < ^identifier :':' Type
	Member < Parameter Note*
	AbstractStatic < :"{" ("abstract" / "static") :"}"

	Seperator < ".." (NoteText :"..")? Note*
		/ "==" (NoteText :"==")? Note* 
		/ "__" (NoteText :"__")? Note*

	StereoTypes < :"<<" StereoType (:',' StereoType)* :">>"
	StereoType < "DB" / "Frontend" / "Backend"

	RealNote < :"note" (RealNoteAssign / RealNoteStandalone)
	RealNoteAssign < RealNotePos? identifier Note?
	RealNoteStandalone < String RealNoteName
	RealNotePos < "left" "of" / "right" "of" / "bottom" "of" / "top" "of"
	RealNoteName < :"as" identifier
` ~ basic));