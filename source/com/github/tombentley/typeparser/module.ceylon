"""Facilities for parsing and formatting type expression-like Strings into 
   Ceylon metamodels.
   
   ## Type expressions
   
   The `TypeParser` can be used to parse an expression into a `Type`. 
   It can be configured to allow unqualified names using 
   `Imports` (which function rather like the `import` statement), but 
   by default uses full-qualified names. The `parseType()` function is 
   provided as a shortcut.
   
       assert(is Type<> stringType = parseType("ceylon.language::String"));
       
       // Adding a Package to the imports is like a wildcard import
       assert(is Type<> stringType2 = parseType("String", [`package ceylon.language`]));
       
       // By default the usual abbreviations are supported
       assert(is Type<> optionalStringType = parseType("String?", [`package ceylon.language`]);
       
       assert(is ParseError error = parseType("Foo?", [`package ceylon.language`]);
   
   The `TypeFormatter` does the reverse and formats a `Type<>` to a `String`
   (but not that the `string` attribute of `Type` is good if all you need a 
   fully-qualified and unabbreviated expressions).
   
       print(TypeFormatter().format(`String[]`, [`package ceylon.language`]));
       // prints "String[]"
   
   
   ## Model expressions
   
   The `ModelParser` supports parsing more general model reference expressions:
   
       assert(is Function<> printFunction = parseModel("ceylon.language::print"));
       
   But currently this doesn't support `Imports`, nor type abbreviations.
   """
by("Tom Bentley")
license("http://www.apache.org/licenses/LICENSE-2.0")
module com.github.tombentley.typeparser "1.0.5" {
    import ceylon.collection "1.3.2";
}
