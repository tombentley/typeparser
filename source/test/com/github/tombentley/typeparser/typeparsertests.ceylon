import com.github.tombentley.typeparser {
    parseModel,
    parseType
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
    parseType("");
}

"""Tests parseType with a negative case."""
test
shared void testParseTypeIdent() {
    parseType("bdvbd");
}

"Tests [[parseModel]] with a variety of valid inputs."
test
shared void testParseModel() {
    assertEquals(`String`, parseModel("ceylon.language::String"));
    assertEquals(`Integer`, parseModel("ceylon.language::Integer"));
    assertEquals(`Anything`, parseModel("ceylon.language::Anything"));
    assertEquals(`Nothing`, parseModel("ceylon.language::Nothing"));
    assertEquals(`true`, parseModel("ceylon.language::true"));
    assertEquals(`false`, parseModel("ceylon.language::false"));
    assertEquals(`null`, parseModel("ceylon.language::null"));
    assertEquals(`nothing`, parseModel("ceylon.language::nothing"));
    assertEquals(`empty`, parseModel("ceylon.language::empty"));
    assertEquals(`print`, parseModel("ceylon.language::print"));
    assertEquals(`String.size`, parseModel("ceylon.language::String.size"));
    assertEquals(`String.endsWith`, parseModel("ceylon.language::String.endsWith"));
    assertEquals(`List<String>.size`, parseModel("ceylon.language::List<ceylon.language::String>.size"));
    assertEquals(`String|Integer`, parseModel("ceylon.language::String|ceylon.language::Integer"));
}