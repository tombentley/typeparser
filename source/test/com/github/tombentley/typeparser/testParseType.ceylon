import com.github.tombentley.typeparser {
    parseModel,
    parseType,
    ParseError
}
import ceylon.test {
    test,
    assertEquals
}

interface Foo {}
interface Bar {}
interface Baz<T> {}

"""Tests parseType with a variety of valid inputs"""
test
shared void testParseTypes() {
    assertEquals(`String`, parseType("ceylon.language::String"));
    assertEquals(`Integer`, parseType("ceylon.language::Integer"));
    assertEquals(`Anything`, parseType("ceylon.language::Anything"));
    assertEquals(`Nothing`, parseType("ceylon.language::Nothing"));
    assertEquals(`true`.type, parseType("ceylon.language::true"));
    assertEquals(`false`.type, parseType("ceylon.language::false"));
    assertEquals(`null`.type, parseType("ceylon.language::null"));
    assertEquals(`nothing`.type, parseType("ceylon.language::nothing"));
    assertEquals(`empty`.type, parseType("ceylon.language::empty"));
    assertEquals(`String|Integer`, parseType("ceylon.language::String|ceylon.language::Integer"));
    
    assertEquals(`Foo`, parseType("test.com.github.tombentley.typeparser::Foo"));
    assertEquals(`Bar`, parseType("test.com.github.tombentley.typeparser::Bar"));
    assertEquals(`Foo|Bar`, parseType("test.com.github.tombentley.typeparser::Foo|test.com.github.tombentley.typeparser::Bar"));
    assertEquals(`Foo&Bar`, parseType("test.com.github.tombentley.typeparser::Foo&test.com.github.tombentley.typeparser::Bar"));
    assertEquals(`Baz<Foo>`, parseType("test.com.github.tombentley.typeparser::Baz<test.com.github.tombentley.typeparser::Foo>"));
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

