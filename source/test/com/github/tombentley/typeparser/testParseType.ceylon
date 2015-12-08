import ceylon.test {
    test,
    assertEquals
}

import com.github.tombentley.typeparser {
    parseType,
    ParseError,
    Imports
}

interface Foo {
}
interface Bar {}

suppressWarnings("unusedDeclaration")
interface Baz<T> {}

suppressWarnings("unusedDeclaration")
interface Outer<X> {
    shared interface Member<Y> {}
}


"""Tests parseType with a variety of valid inputs"""
test
shared void testParseTypes() {
    assertEquals(parseType("ceylon.language::String"), `String`);
    assertEquals(parseType("ceylon.language::Integer"), `Integer`);
    assertEquals(parseType("ceylon.language::Anything"), `Anything`);
    assertEquals(parseType("ceylon.language::Nothing"), `Nothing`);
    assertEquals(parseType("ceylon.language::true"), `true`.type);
    assertEquals(parseType("ceylon.language::false"), `false`.type);
    assertEquals(parseType("ceylon.language::null"), `null`.type);
    assertEquals(parseType("ceylon.language::nothing"), `nothing`.type);
    assertEquals(parseType("ceylon.language::empty"), `empty`.type);
    assertEquals(parseType("ceylon.language::String|ceylon.language::Integer"), `String|Integer`);
    
    assertEquals(parseType("test.com.github.tombentley.typeparser::Foo"), `Foo`);
    assertEquals(parseType("test.com.github.tombentley.typeparser::Bar"), `Bar`);
    assertEquals(parseType("test.com.github.tombentley.typeparser::Foo|test.com.github.tombentley.typeparser::Bar"), `Foo|Bar`);
    assertEquals(parseType("test.com.github.tombentley.typeparser::Foo&test.com.github.tombentley.typeparser::Bar"), `Foo&Bar`);
    assertEquals(parseType("test.com.github.tombentley.typeparser::Baz<test.com.github.tombentley.typeparser::Foo>"), `Baz<Foo>`);
    
    
    assertEquals(parseType(
        "test.com.github.tombentley.typeparser::Outer<ceylon.language::String>"+
                ".Member<ceylon.language::Integer>"), 
        `Outer<String>.Member<Integer>`);
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeEmptyInput() {
    assert(is ParseError e = parseType(""));
    assertEquals(e.message, "module not found: ''");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnfoundModule() {
    assert(is ParseError e = parseType("bdvbd"));
    assertEquals(e.message, "module not found: 'bdvbd'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnfoundPackage() {
    assert(is ParseError e = parseType("ceylon.language.bdvbd"));
    assertEquals(e.message, "package not found: 'ceylon.language.bdvbd'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnfoundType() {
    assert(is ParseError e = parseType("ceylon.language::bdvbd"));
    assertEquals(e.message, "type does not exist: 'bdvbd' in 'package ceylon.language'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnterminatedPackage() {
    assert(is ParseError e = parseType("ceylon.language."));
    assertEquals(e.message, "package not found: 'ceylon.language.'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnterminatedModule() {
    assert(is ParseError e = parseType("ceylon."));
    assertEquals(e.message, "module not found: 'ceylon.'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeModuleSyntax() {
    assert(is ParseError e = parseType("ceylon.."));
    assertEquals(e.message, "module not found: 'ceylon..'");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeUnfoundMemberType() {
    assert(is ParseError e = parseType("test.com.github.tombentley.typeparser::Outer<ceylon.language::String>.Fred"));
    assertEquals(e.message, "member type does not exist: Fred member of test.com.github.tombentley.typeparser::Outer");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeNotInstantiated() {
    assert(is ParseError e = parseType("test.com.github.tombentley.typeparser::Baz"));
    assertEquals(e.message, "erronerous type instantiation test.com.github.tombentley.typeparser::Baz: Not enough type arguments provided: 0, but requires exactly 1");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeMemberNotInstantiated() {
    assert(is ParseError e = parseType("test.com.github.tombentley.typeparser::Outer<ceylon.language::String>.Member"));
    assertEquals(e.message, "erronerous type instantiation Member: Not enough type arguments provided: 0, but requires exactly 1");
}

"""Tests parseType with a variety of valid inputs"""
test
shared void testParseTypesWithImports() {
    variable Imports imports = [`package ceylon.language`];
    assertEquals(parseType("String", imports), `String`);
    assertEquals(parseType("Integer", imports), `Integer`);
    assertEquals(parseType("Anything", imports), `Anything`);
    assertEquals(parseType("Nothing", imports), `Nothing`);
    assertEquals(parseType("true", imports), `true`.type);
    assertEquals(parseType("false", imports), `false`.type);
    assertEquals(parseType("null", imports), `null`.type);
    assertEquals(parseType("nothing", imports), `nothing`.type);
    assertEquals(parseType("empty", imports), `empty`.type);
    assertEquals(parseType("String|Integer", imports), `String|Integer`);
    assert(is ParseError e = parseType("kdnbkfbn", imports));
    assertEquals(e.message, "type does not exist: 'kdnbkfbn' in 'imports ceylon.language { ... }'");
    
    imports = [`package`, `package ceylon.language`];
    assertEquals(parseType("Foo", imports), `Foo`);
    assertEquals(parseType("Bar", imports), `Bar`);
    assertEquals(parseType("Foo|Bar", imports), `Foo|Bar`);
    assertEquals(parseType("Foo&Bar", imports), `Foo&Bar`);
    assertEquals(parseType("Baz<Foo>", imports), `Baz<Foo>`);
    assertEquals(parseType("Sequence<Foo>", imports), `Sequence<Foo>`);
    
    assertEquals(parseType(
        "Outer<String>"+
                ".Member<Integer>", imports), 
    `Outer<String>.Member<Integer>`);
}

test
shared void testParseEntryAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
        entryAbbreviation = true; 
    };
    
    assertEquals(pt("String->Integer"), `String->Integer`);
    assertEquals(pt("ceylon.language::String->ceylon.language::Integer"), `String->Integer`);
    
    // TODO precedence
}


test
shared void testParseOptionalAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports; 
    };
    assertEquals(pt("String?"), `String?`);
    assertEquals(pt("ceylon.language::String?"), `String?`);
    
    assertEquals(pt("Integer|String?"), `Integer|String?`);
    assertEquals(pt("Integer|<String?>"), `Integer|<String?>`);
    assertEquals(pt("<Integer|String?>"), `<Integer|String?>`);
    assertEquals(pt("ceylon.language::Integer|ceylon.language::String?"), `Integer|String?`);
    assertEquals(pt("ceylon.language::Integer|<ceylon.language::String?>"), `Integer|<String?>`);
    assertEquals(pt("<ceylon.language::Integer|ceylon.language::String?>"), `<Integer|String?>`);
    
    assertEquals(pt("Foo&Bar?"), `Foo&Bar?`);
    assertEquals(pt("Foo&<Bar?>"), `Foo&<Bar?>`);
    assertEquals(pt("<Foo&Bar>?"), `<Foo&Bar>?`);
    
    assertEquals(pt("Foo->Bar?"), `Foo->Bar?`);
    assertEquals(pt("Foo-><Bar?>"), `Foo-><Bar?>`);
    assertEquals(pt("<Foo->Bar>?"), `<Foo->Bar>?`);
    
    assertEquals(pt("String??"), `String??`);
    assertEquals(pt("String[]?"), `String[]?`);
    assertEquals(pt("String?[]"), `String?[]`);
    assertEquals(pt("String?[]?"), `String?[]?`);
    assertEquals(pt("String[]?[]"), `String[]?[]`);
    
    assertEquals(pt("ceylon.language::String??"), `String??`);
    assertEquals(pt("ceylon.language::String[]?"), `String[]?`);
    assertEquals(pt("ceylon.language::String?[]"), `String?[]`);
    assertEquals(pt("ceylon.language::String?[]?"), `String?[]?`);
    assertEquals(pt("ceylon.language::String[]?[]"), `String[]?[]`);
    
    // TODO Callable
}

test
shared void testParseEmptyAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports; 
    };
    assertEquals(pt("[]"), `[]`);
    assertEquals(pt("[]?"), `[]?`);
    assertEquals(pt("[](*[])"), `[](*[])`);
    
    assertEquals(pt("ceylon.language::Empty"), `[]`);
    assertEquals(pt("ceylon.language::Empty?"), `[]?`);
    assertEquals(pt("ceylon.language::Empty(*ceylon.language::Empty)"), `[](*[])`);
    
}

test
shared void testParseSequenceAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("String[]"), `String[]`);
    assertEquals(pt("ceylon.language::String[]"), `String[]`);
    
    assertEquals(pt("Integer|String[]"), `Integer|String[]`);
    assertEquals(pt("Integer|<String[]>"), `Integer|<String[]>`);
    assertEquals(pt("<Integer|String[]>"), `<Integer|String[]>`);
    
    assertEquals(pt("ceylon.language::Integer|ceylon.language::String[]"), `Integer|String[]`);
    assertEquals(pt("ceylon.language::Integer|<ceylon.language::String[]>"), `Integer|<String[]>`);
    assertEquals(pt("<ceylon.language::Integer|ceylon.language::String[]>"), `<Integer|String[]>`);
    
    assertEquals(pt("Foo&Bar[]"), `Foo&Bar[]`);
    assertEquals(pt("Foo&<Bar[]>"), `Foo&<Bar[]>`);
    assertEquals(pt("<Foo&Bar>[]"), `<Foo&Bar>[]`);
    
    assertEquals(pt("Foo->Bar[]"), `Foo->Bar[]`);
    assertEquals(pt("Foo-><Bar[]>"), `Foo-><Bar[]>`);
    assertEquals(pt("<Foo->Bar>[]"), `<Foo->Bar>[]`);
    
    assertEquals(pt("test.com.github.tombentley.typeparser::Foo->test.com.github.tombentley.typeparser::Bar[]"), `Foo->Bar[]`);
    assertEquals(pt("test.com.github.tombentley.typeparser::Foo-><test.com.github.tombentley.typeparser::Bar[]>"), `Foo-><Bar[]>`);
    assertEquals(pt("<test.com.github.tombentley.typeparser::Foo->test.com.github.tombentley.typeparser::Bar>[]"), `<Foo->Bar>[]`);
    
    // TODO Callable
}

test
shared void testParseSequenceAbbrevPlus() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("[String+]"), `[String+]`);
    assertEquals(pt("[ceylon.language::String+]"), `[String+]`);
    
    assertEquals(pt("[Integer|String+]"), `[Integer|String+]`);
    assertEquals(pt("Integer|<[String+]>"), `Integer|<[String+]>`);
    assertEquals(pt("[<Integer|String>+]"), `[<Integer|String>+]`);
    
    assertEquals(pt("[ceylon.language::Integer|ceylon.language::String+]"), `[Integer|String+]`);
    assertEquals(pt("ceylon.language::Integer|<[ceylon.language::String+]>"), `Integer|<[String+]>`);
    assertEquals(pt("[<ceylon.language::Integer|ceylon.language::String>+]"), `[<Integer|String>+]`);
    
    assertEquals(pt("[Foo&Bar+]"), `[Foo&Bar+]`);
    assertEquals(pt("Foo&<[Bar+]>"), `Foo&<[Bar+]>`);
    assertEquals(pt("[<Foo&Bar>+]"), `[<Foo&Bar>+]`);
    
    assert(is ParseError e = pt("[Foo->Bar+]"));
    assertEquals(e.message, "unexpected token: expected ], found + (+) at index 9: [Foo->Bar+]");//Incorrect syntax: extraneous token + expecting closing bracket ]
    assertEquals(pt("Foo-><[Bar+]>"), `Foo-><[Bar+]>`);
    assertEquals(pt("[<Foo->Bar>+]"), `[<Foo->Bar>+]`);
    
    // TODO Callable
}

test
shared void testParseSequenceAbbrevStar() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("[String*]"), `[String*]`);
    
    assertEquals(pt("[Integer|String*]"), `[Integer|String*]`);
    assertEquals(pt("Integer|<[String*]>"), `Integer|<[String*]>`);
    assertEquals(pt("[<Integer|String>*]"), `[<Integer|String>*]`);
    
    assertEquals(pt("[Foo&Bar*]"), `[Foo&Bar*]`);
    assertEquals(pt("Foo&<[Bar*]>"), `Foo&<[Bar*]>`);
    assertEquals(pt("[<Foo&Bar>*]"), `[<Foo&Bar>*]`);
    
    assert(is ParseError e = pt("[Foo->Bar*]"));
    assertEquals(e.message, "unexpected token: expected ], found * (*) at index 9: [Foo->Bar*]");//Incorrect syntax: extraneous token * expecting closing bracket ]
    assertEquals(pt("Foo-><[Bar*]>"), `Foo-><[Bar*]>`);
    assertEquals(pt("[<Foo->Bar>*]"), `[<Foo->Bar>*]`);
    
    // TODO Callable
}

test
shared void testParseIterableAbbrevPlus() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("{String+}"), `{String+}`);
    
    assertEquals(pt("{Integer|String+}"), `{Integer|String+}`);
    assertEquals(pt("Integer|<{String+}>"), `Integer|<{String+}>`);
    assertEquals(pt("{<Integer|String>+}"), `{<Integer|String>+}`);
    
    assertEquals(pt("{Foo&Bar+}"), `{Foo&Bar+}`);
    assertEquals(pt("Foo&<{Bar+}>"), `Foo&<{Bar+}>`);
    assertEquals(pt("{<Foo&Bar>+}"), `{<Foo&Bar>+}`);
    
    assert(is ParseError e = pt("{Foo->Bar+}"));
    //Incorrect syntax: extraneous token + expecting closing brace }
    assertEquals(e.message, "badly formed iterable type");
    
    assertEquals(pt("Foo-><{Bar+}>"), `Foo-><{Bar+}>`);
    assertEquals(pt("{<Foo->Bar>+}"), `{<Foo->Bar>+}`);
    
    // TODO Callable
}

test
shared void testParseIterableAbbrevStar() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("{String*}"), `{String*}`);
    
    assertEquals(pt("{Integer|String*}"), `{Integer|String*}`);
    assertEquals(pt("Integer|<{String*}>"), `Integer|<{String*}>`);
    assertEquals(pt("{<Integer|String>*}"), `{<Integer|String>*}`);
    
    assertEquals(pt("{Foo&Bar*}"), `{Foo&Bar*}`);
    assertEquals(pt("Foo&<{Bar*}>"), `Foo&<{Bar*}>`);
    assertEquals(pt("{<Foo&Bar>*}"), `{<Foo&Bar>*}`);
    
    assert(is ParseError e = pt("{Foo->Bar*}"));
    //Incorrect syntax: extraneous token * expecting closing brace }
    assertEquals(e.message, "badly formed iterable type");
    assertEquals(pt("Foo-><{Bar*}>"), `Foo-><{Bar*}>`);
    assertEquals(pt("{<Foo->Bar>*}"), `{<Foo->Bar>*}`);
    
    // TODO Callable
}

test
shared void testParseTupleAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("[String]"), `[String]`);
    assertEquals(pt("[String,Integer]"), `[String,Integer]`);
    assertEquals(pt("[String,Integer+]"), `[String,Integer+]`);
    assertEquals(pt("[String,Integer*]"), `[String,Integer*]`);
    
    // TODO Tuple with defaults
    
}

test
shared void testParseTupleWithDefaults() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    assertEquals(pt("[String=]"), `[String=]`);
    assertEquals(pt("[String,Integer=]"), `[String,Integer=]`);
    assertEquals(pt("[String=,Integer=]"), `[String=,Integer=]`);
    assert(is ParseError e=pt("[String=,Integer]"));
    assertEquals(e.message, "required element must occur after defaulted elements in a tuple type");
    
    assertEquals(pt("[String=,Integer*]"), `[String=,Integer*]`);
    assert(is ParseError e2=pt("[String=,Integer+]"));
    assertEquals(e2.message, "nonempty variadic element must occur after defaulted elements in a tuple type");
    
    assertEquals(pt("[String,Integer,Boolean]"), `[String,Integer,Boolean]`);
    assertEquals(pt("[String,Integer,Boolean=]"), `[String,Integer,Boolean=]`);
    assertEquals(pt("[String,Integer=,Boolean=]"), `[String,Integer=,Boolean=]`);
    assertEquals(pt("[String=,Integer=,Boolean=]"), `[String=,Integer=,Boolean=]`);
    
    assert(is ParseError e3=pt("[String=,Integer=,Boolean]"));
    assertEquals(e3.message, "required element must occur after defaulted elements in a tuple type");
    assert(is ParseError e4=pt("[String=,Integer,Boolean]"));
    assertEquals(e4.message, "required element must occur after defaulted elements in a tuple type");
    assert(is ParseError e5=pt("[String,Integer=,Boolean]"));
    assertEquals(e5.message, "required element must occur after defaulted elements in a tuple type");
    
    
    assertEquals(pt("[Outer<String>.Member<Integer>=]"), `[Outer<String>.Member<Integer>=]`);
}

test
shared void testParseTupleLengthAbbrev() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    
    assertEquals(pt("String[2]"), `String[2]`);
    
    assertEquals(pt("String|Integer[2]"), `String|Integer[2]`);
    assertEquals(pt("<String|Integer>[2]"), `<String|Integer>[2]`);
    assertEquals(pt("String|<Integer[2]>"), `String|<Integer[2]>`);
    
    assertEquals(pt("String[2][2]"), `String[2][2]`);
    assertEquals(pt("String|Integer[2][2]"), `String|Integer[2][2]`);
    assertEquals(pt("<String|Integer>[2][2]"), `<String|Integer>[2][2]`);
    assertEquals(pt("<String|Integer[2]>[2]"), `<String|Integer[2]>[2]`);
    assertEquals(pt("String|<Integer[2]>[2]"), `String|<Integer[2]>[2]`);
    assertEquals(pt("Foo&Bar[2][2]"), `Foo&Bar[2][2]`);
}

test
shared void testParseCallable() {
    Imports imports = [`package`, `package ceylon.language`];
    function pt(String t) => parseType { 
        t = t; 
        imports = imports;
    };
    
    assertEquals(pt("String()"), `String()`);
    assertEquals(pt("String(Boolean)"), `String(Boolean)`);
    assertEquals(pt("String(Boolean=)"), `String(Boolean=)`);
    assertEquals(pt("String(Boolean,Integer)"), `String(Boolean,Integer)`);
    assertEquals(pt("String(Boolean,Integer=)"), `String(Boolean,Integer=)`);
    assertEquals(pt("String(Boolean=,Integer=)"), `String(Boolean=,Integer=)`);
    
    assertEquals(pt("String(*[])"), `String(*[])`);
    assertEquals(pt("String(*[Boolean,Integer])"), `String(*[Boolean,Integer])`);
    assertEquals(pt("String(*Boolean[])"), `String(*Boolean[])`);
    assertEquals(pt("String(*Boolean[2])"), `String(*Boolean[2])`);
}



// TODO test for precedence
// TODO negative tests
// TODO tests with abbreviations turned off