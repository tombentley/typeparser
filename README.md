# typeparser

Functions for parsing fully qualified type expression-like and reference expression-like Strings into Ceylon metamodels.

The module provides two functions `parseType()` for getting a `Type` from a type-like expression
and `parseModel()` for getting a `Type|Model` from a reference-like expression.

For example:

    assert(is Type<> integerType = parseType("ceylon.language::Integer");
    assert(is Function<> printFunction = parseModel("ceylon.language::print");
    
## Qualified vs. Unqualified

By default `parseType()` requires all types to be qualified with a 
package name. This means the accepted inputs aren't true Celyon type 
expressions. By passing `Imports` to `parseType()` it's 
possible to allow true type expressions, with the benefit that the 
expressions are also much shorter:

    Imports imports = [`package ceylon.language`];
    assert(is Type<> integerType = parseType("Integer". imports);
    
Including a `Package` in the imports is like a wildcard `import`,
including a `ClassOrInterfaceDeclaration` is like a normal `import` 
and including a `String->ClassOrInterfaceDeclaration` is like
an `import` alias.

`parseModel()` does not support `Imports` (yet).

