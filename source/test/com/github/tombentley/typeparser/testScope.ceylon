/*import ceylon.test {
    test,
    assertEquals
}
import com.github.tombentley.typeparser {
    Scope
}
import ceylon.language.meta.model {
    nothingType
}

test
shared void testScopeWildcardLanguage() {
    value scope = Scope([`package ceylon.language`]); 
    assertEquals(scope.find("String"), `class String`);
    assertEquals(scope.find("Integer"), `class Integer`);
    assertEquals(scope.find("empty"), `empty`.type);
    assertEquals(scope.find("Nothing"), nothingType);
}

test
shared void testScope2() {
    class String() {}
    value scope = Scope([`class Scope`, `class String`, `package ceylon.language`]); 
    assertEquals(scope.find("Scope"), `class Scope`);
    assertEquals(scope.find("String"), `class String`);
    assertEquals(scope.find("String")?.string, "class test.com.github.tombentley.typeparser::testScope2.String");
    assertEquals(scope.find("Integer"), `class Integer`);
}*/