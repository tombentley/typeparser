import ceylon.test {
    assertEquals,
    test
}
import com.github.tombentley.typeparser {
    parseModel
}

object foo satisfies Foo {
    shared Integer attr = 3;
    shared Integer meth() => 3;
}
object bar satisfies Bar {}
object baz satisfies Baz<String> {}

shared Integer val = 3;
shared Integer fun() => 3;

interface Diamond {
    shared formal Anything m();
}

interface Left<T> satisfies Diamond {
    shared actual formal T m();
}

interface Right satisfies Diamond {
    shared actual formal Identifiable m();
}

interface Join<T> satisfies Left<Object>&Right {
    shared actual formal Set<T>&Identifiable m();
}

class Gee {
    shared new () {}
    shared new other() {}
    
    shared class MemberClass() {
        
    }
    shared interface MemberInterface {
        
    }
}


"Tests [[parseModel]] with a variety of valid inputs."
test
shared void testParseModelType() {
    assertEquals(parseModel("ceylon.language::String"), `String`);
    assertEquals(parseModel("ceylon.language::Integer"), `Integer`);
    assertEquals(parseModel("ceylon.language::Anything"), `Anything`);
    assertEquals(parseModel("ceylon.language::Nothing"), `Nothing`);
    assertEquals(parseModel("ceylon.language::String|ceylon.language::Integer"), `String|Integer`);
    assertEquals(parseModel("ceylon.language::true"), `true`.type);
    assertEquals(parseModel("ceylon.language::false"), `false`.type);
    assertEquals(parseModel("ceylon.language::null"), `null`.type);
    assertEquals(parseModel("ceylon.language::empty"), `empty`.type);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Gee"), `Gee`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Gee.MemberClass"), `Gee.MemberClass`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Gee.MemberInterface"), `Gee.MemberInterface`);
    
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Foo&test.com.github.tombentley.typeparser::Bar"), `Foo&Bar`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Foo&test.com.github.tombentley.typeparser::Bar|ceylon.language::String"), `Foo&Bar|String`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Foo|test.com.github.tombentley.typeparser::Bar"), `Foo|Bar`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Foo|test.com.github.tombentley.typeparser::Bar|ceylon.language::String"), `Foo|Bar|String`);
    
    // TODO test precedence of union and intersection
    // TODO test triple unions and intersections
    
}
test
shared void testParseModelValue() {
    assertEquals(parseModel("test.com.github.tombentley.typeparser::val"), `val`);
    assertEquals(parseModel("ceylon.language::nothing"), `nothing`);
}
test
shared void testParseModelAttribute() {
    assertEquals(parseModel("test.com.github.tombentley.typeparser::foo.attr"), `\Ifoo.attr`);
    assertEquals(parseModel("ceylon.language::String.size"), `String.size`);
    assertEquals(parseModel("ceylon.language::List<ceylon.language::String>.size"), `List<String>.size`);
}
test
shared void testParseModelFunction() {
    assertEquals(parseModel("ceylon.language::print"), `print`);
    assertEquals(parseModel("test.com.github.tombentley.typeparser::fun"), `fun`);
}

test
shared void testParseModelMethod() {
    assertEquals(parseModel("test.com.github.tombentley.typeparser::foo.meth"), `\Ifoo.meth`);
    assertEquals(parseModel("ceylon.language::String.endsWith"), `String.endsWith`);
    assertEquals(parseModel("ceylon.language::Array<ceylon.language::String>.copyTo"), `Array<String>.copyTo`);
}

test
shared void testParseModelConstructor() {
    assertEquals(parseModel("test.com.github.tombentley.typeparser::Gee.other"), `Gee.other`);
    assertEquals(parseModel("ceylon.language::Array<ceylon.language::String>.ofSize"), `Array<String>.ofSize`);
}

test
shared void testParseModelIntersection() {
    assertEquals(parseModel("<test.com.github.tombentley.typeparser::Left<ceylon.language::Identifiable>&test.com.github.tombentley.typeparser::Right>.m"), 
        `<Left<Identifiable>&Right>.m`);
}

// TODO negative tests