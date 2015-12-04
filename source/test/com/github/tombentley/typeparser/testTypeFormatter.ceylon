import ceylon.test {
    test,
    assertEquals
}
import com.github.tombentley.typeparser {
    TypeFormatter
}
test
shared void testTypeFormatter() {
    TypeFormatter tf = TypeFormatter{
        abbreviateSequence = false;
        abbreviateSequential = false;
        abbreviateEmpty = false;
        abbreviateIterable = false;
        abbreviateTuple = false;
        abbreviateEntry = false;
        abbreviateCallable = false;
        abbreviateOptional = false;
    };
    assertEquals(tf.format(`Integer`), "ceylon.language::Integer");
    assertEquals(tf.format(`String`), "ceylon.language::String");
    assertEquals(tf.format(`Foo`), "test.com.github.tombentley.typeparser::Foo");
    assertEquals(tf.format(`Set<String>`), "ceylon.language::Set<ceylon.language::String>");
    assertEquals(tf.format(`Sequence<String>`), "ceylon.language::Sequence<ceylon.language::String>");
    assertEquals(tf.format(`Sequential<String>`), "ceylon.language::Sequential<ceylon.language::String>");
    assertEquals(tf.format(`String->Integer`), "ceylon.language::Entry<ceylon.language::String,ceylon.language::Integer>");
    assertEquals(tf.format(`Map<String,Integer>`), "ceylon.language::Map<ceylon.language::String,ceylon.language::Integer>");
    
    assertEquals(tf.format(`String(Integer)`), "ceylon.language::Callable<"
        +"ceylon.language::String,"
            +"ceylon.language::Tuple<"
            +"ceylon.language::Integer,"
            +"ceylon.language::Integer,"
            +"ceylon.language::Empty>>");
    
    // precedence isn't a problem for the formatter wrt union and intersection
    // since a Type is already factored source
    // (we could in principle try to factor it, but there's no obvious benefit
    assertEquals(tf.format(`String|Integer`), "ceylon.language::Integer|ceylon.language::String");
    assertEquals(tf.format(`String|Null`), "ceylon.language::Null|ceylon.language::String");
    assertEquals(tf.format(`Null|String`), "ceylon.language::Null|ceylon.language::String");
    assertEquals(tf.format(`Usable&Resource`), "ceylon.language::Resource&ceylon.language::Usable");
    
    assertEquals(tf.format(`<Usable&Resource>|Identifiable`), "ceylon.language::Identifiable|ceylon.language::Resource&ceylon.language::Usable");
    assertEquals(tf.format(`Usable&<Resource|Identifiable>`), "ceylon.language::Identifiable&ceylon.language::Usable|ceylon.language::Resource&ceylon.language::Usable");
    
    assertEquals(tf.format(`Nothing`), "ceylon.language::Nothing");
}

test
shared void testTypeFormatterImportString() {
    TypeFormatter tf = TypeFormatter{
        abbreviateSequence = false;
        abbreviateSequential = false;
        abbreviateEmpty = false;
        abbreviateIterable = false;
        abbreviateTuple = false;
        abbreviateEntry = false;
        abbreviateCallable = false;
        abbreviateOptional = false;
        imports = [`class String`];
    };
    assertEquals(tf.format(`Integer`), "ceylon.language::Integer");
    assertEquals(tf.format(`String`), "String");
    assertEquals(tf.format(`Foo`), "test.com.github.tombentley.typeparser::Foo");
    assertEquals(tf.format(`Set<String>`), "ceylon.language::Set<String>");
    assertEquals(tf.format(`Sequence<String>`), "ceylon.language::Sequence<String>");
    assertEquals(tf.format(`Sequential<String>`), "ceylon.language::Sequential<String>");
    assertEquals(tf.format(`String->Integer`), "ceylon.language::Entry<String,ceylon.language::Integer>");
    assertEquals(tf.format(`Map<String,Integer>`), "ceylon.language::Map<String,ceylon.language::Integer>");
    
    assertEquals(tf.format(`String(Integer)`), "ceylon.language::Callable<"
        +"String,"
            +"ceylon.language::Tuple<"
            +"ceylon.language::Integer,"
            +"ceylon.language::Integer,"
            +"ceylon.language::Empty>>");
    
    assertEquals(tf.format(`String|Integer`), "ceylon.language::Integer|String");
    assertEquals(tf.format(`String|Null`), "ceylon.language::Null|String");
    assertEquals(tf.format(`Null|String`), "ceylon.language::Null|String");
    
    assertEquals(tf.format(`Usable&Resource`), "ceylon.language::Resource&ceylon.language::Usable");
    
    assertEquals(tf.format(`Nothing`), "ceylon.language::Nothing");
}

test
shared void testTypeFormatterImportLanguage() {
    TypeFormatter tf = TypeFormatter{
        abbreviateSequence = false;
        abbreviateSequential = false;
        abbreviateEmpty = false;
        abbreviateIterable = false;
        abbreviateTuple = false;
        abbreviateEntry = false;
        abbreviateCallable = false;
        abbreviateOptional = false;
        imports = [`package ceylon.language`];
    };
    assertEquals(tf.format(`Integer`), "Integer");
    assertEquals(tf.format(`String`), "String");
    assertEquals(tf.format(`Foo`), "test.com.github.tombentley.typeparser::Foo");
    assertEquals(tf.format(`Set<String>`), "Set<String>");
    assertEquals(tf.format(`Sequence<String>`), "Sequence<String>");
    assertEquals(tf.format(`Baz<String>`), "test.com.github.tombentley.typeparser::Baz<String>");
    assertEquals(tf.format(`Sequence<Foo>`), "Sequence<test.com.github.tombentley.typeparser::Foo>");
    assertEquals(tf.format(`Sequential<String>`), "Sequential<String>");
    assertEquals(tf.format(`String->Integer`), "Entry<String,Integer>");
    assertEquals(tf.format(`Map<String,Integer>`), "Map<String,Integer>");
    
    assertEquals(tf.format(`String(Integer)`), "Callable<"
        +"String,"
            +"Tuple<"
            +"Integer,"
            +"Integer,"
            +"Empty>>");
    
    assertEquals(tf.format(`String|Integer`), "Integer|String");
    assertEquals(tf.format(`String|Null`), "Null|String");
    assertEquals(tf.format(`Null|String`), "Null|String");
    
    assertEquals(tf.format(`Usable&Resource`), "Resource&Usable");
    
    assertEquals(tf.format(`<Usable&Resource>|Identifiable`), "Identifiable|Resource&Usable");
    assertEquals(tf.format(`Usable&<Resource|Identifiable>`), "Identifiable&Usable|Resource&Usable");
    assertEquals(tf.format(`<Usable&Resource>|<Identifiable&Foo>`), "Identifiable&test.com.github.tombentley.typeparser::Foo|Resource&Usable");
    assertEquals(tf.format(`<Usable|Resource>&<Identifiable|Foo>`), "Identifiable&Resource|Identifiable&Usable|Resource&test.com.github.tombentley.typeparser::Foo|Usable&test.com.github.tombentley.typeparser::Foo");
    
    assertEquals(tf.format(`Nothing`), "Nothing");
}

test
shared void testTypeFormatterAbbrev() {
    TypeFormatter tf = TypeFormatter{
        abbreviateSequence = true;
        abbreviateSequential = true;
        abbreviateIterable = true;
        abbreviateTuple = true;
        abbreviateEntry = true;
        abbreviateCallable = true;
        abbreviateOptional = true;
    };
    assertEquals(tf.format(`Integer`), "ceylon.language::Integer");
    assertEquals(tf.format(`String`), "ceylon.language::String");
    assertEquals(tf.format(`Foo`), "test.com.github.tombentley.typeparser::Foo");
    assertEquals(tf.format(`Empty`), "[]");
    // special case
    assertEquals(tf.format(`Nothing`), "ceylon.language::Nothing");
    
    assertEquals(tf.format(`Set<String>`), "ceylon.language::Set<ceylon.language::String>");
    assertEquals(tf.format(`Sequence<String>`), "[ceylon.language::String+]");
    assertEquals(tf.format(`Sequential<String>`), "ceylon.language::String[]");
    assertEquals(tf.format(`Sequential<String->Integer>`), "<ceylon.language::String->ceylon.language::Integer>[]");
    assertEquals(tf.format(`Sequential<Empty>`), "[][]");
    assertEquals(tf.format(`String->Integer`), "ceylon.language::String->ceylon.language::Integer");
    assertEquals(tf.format(`String-><Integer->Boolean>`), "ceylon.language::Entry<ceylon.language::String,ceylon.language::Integer->ceylon.language::Boolean>");
    assertEquals(tf.format(`<String->Integer>->Boolean`), "ceylon.language::Entry<ceylon.language::String->ceylon.language::Integer,ceylon.language::Boolean>");
    assertEquals(tf.format(`Map<String,Integer>`), "ceylon.language::Map<ceylon.language::String,ceylon.language::Integer>");
    
    // basic tuples
    assertEquals(tf.format(`[Integer]`), "[ceylon.language::Integer]");
    assertEquals(tf.format(`[Integer,String]`), "[ceylon.language::Integer,ceylon.language::String]");
    assertEquals(tf.format(`[Integer,String+]`), "[ceylon.language::Integer,ceylon.language::String+]");
    assertEquals(tf.format(`[Integer,String*]`), "[ceylon.language::Integer,ceylon.language::String*]");
    
    // TODO defaulted tuples
    
    // homo tuples
    assertEquals(tf.format(`Integer[3]`), "ceylon.language::Integer[3]");
    assertEquals(tf.format(`<Integer|String>[3]`), "<ceylon.language::Integer|ceylon.language::String>[3]");
    assertEquals(tf.format(`<Integer->String>[3]`), "<ceylon.language::Integer->ceylon.language::String>[3]");
    assertEquals(tf.format(`Integer-><String[3]>`), "ceylon.language::Integer->ceylon.language::String[3]");
    assertEquals(tf.format(`<Integer[3]>->String`), "ceylon.language::Integer[3]->ceylon.language::String");
    
    // Callable
    assertEquals(tf.format(`String(Integer)`), "ceylon.language::String(ceylon.language::Integer)");
    assertEquals(tf.format(`String(Integer,Boolean)`), "ceylon.language::String(ceylon.language::Integer,ceylon.language::Boolean)");
    assertEquals(tf.format(`String(Integer,Boolean|String)`), "ceylon.language::String(ceylon.language::Integer,ceylon.language::Boolean|ceylon.language::String)");
    assertEquals(tf.format(`<String->Boolean>(Integer)`), "<ceylon.language::String->ceylon.language::Boolean>(ceylon.language::Integer)");
    assertEquals(tf.format(`String-><Boolean(Integer)>`), "ceylon.language::String->ceylon.language::Boolean(ceylon.language::Integer)");
    
    // TODO Callable with spread
    
    // union
    assertEquals(tf.format(`String|Integer`), "ceylon.language::Integer|ceylon.language::String");
    assertEquals(tf.format(`String|Null`), "ceylon.language::String?");
    assertEquals(tf.format(`Null|String`), "ceylon.language::String?");
    
    // intersection
    assertEquals(tf.format(`Usable&Resource`), "ceylon.language::Resource&ceylon.language::Usable");
}