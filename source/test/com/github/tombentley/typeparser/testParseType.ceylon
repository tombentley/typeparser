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
interface Baz<T> {}

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


// TODO test with member types
// TODO test with grouped type expressions
// TODO test for precedence