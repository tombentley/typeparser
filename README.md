# typeparser

Functions for parsing fully qualified type expression-like and reference expression-like Strings into Ceylon metamodels.

The module provides two functions `parseType()` for getting a `Type` from a type-like expression
and `parseModel()` for getting a `Type|Model` from a reference-like expression.
The expressions aren't true Celyon expressions because of the need to fully qualify things.

For example:

    assert(is Type<> integerType = parseType("ceylon.language::Integer");
    assert(is Function<> printFunction = parseModel("ceylon.language::print");
    
