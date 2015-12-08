import ceylon.language.meta {
    modules
}
import ceylon.language.meta.declaration {
    Module,
    FunctionDeclaration,
    NestableDeclaration,
    ValueDeclaration,
    TypedDeclaration,
    AliasDeclaration,
    Package,
    ClassOrInterfaceDeclaration
}
import ceylon.language.meta.model {
    ClassOrInterface,
    Type,
    Class,
    Function,
    nothingType,
    Model
}


"""
   input ::= intersectionModel ;
   intersectionModel ::= unionModel ('&' intersectionModel) ;
   unionModel ::= qualifiedModel ('|' intersectionType) ;
   qualifiedModel ::= qualifiedDeclaration typeArguments? ('.' declarationName  typeArguments?)* ;
   qualifiedDeclaration ::= packageName '::' declarationName ;
   packageName ::= lident (. lident)* ;
   declarationName ::= typeName | memberName
   typeName ::= uident;
   memberName ::= lident;
   typeArgments := '<' intersectionType (',' intersectionType)* '>';
   
   """
class ModelParser() {
    value modulesList = modules.list;
    
    """input ::= intersectionType ;"""
    shared Model|Type<>|ParseError parse(String input) {
        try {
            value tokenizer = Tokenizer(input);
            value result = unionModel(tokenizer);
            tokenizer.expect(dtEoi);
            return result;
        } catch (ParseError e) {
            return e;
        }
    }
    
    """unionType ::= intersectionModel ('|' intersectionModel) ;"""
    Model|Type<> unionModel(Tokenizer tokenizer) {
        variable value result = intersectionModel(tokenizer);
        while (tokenizer.isType(dtOr)) {
            if (is Type<> u1=result) {
                value u2 = intersectionModel(tokenizer);
                if (is Type<> u2) {
                    result = u1.union(u2);
                } else {
                    throw ParseError("expected type in intersection: ``u2``");
                }
            } else {
                throw ParseError("expected type in intersection: ``result``");
            }
        }
        return result;
    }
    
    """intersectionType ::= simpleType ('&' simpleType) ;"""
    Model|Type<> intersectionModel(Tokenizer tokenizer) {
        variable value result = qualifiedModel(tokenizer);
        while (tokenizer.isType(dtAnd)) {
            if (is Type<> u1=result) {
                value u2 = qualifiedModel(tokenizer);
                if (is Type<> u2) {
                    result = u1.intersection(u2);
                } else {
                    throw ParseError("expected type in union: ``u2``");
                }
            } else {
                throw ParseError("expected type in union: ``result``");
            }
        }
        return result;
    }
    
    
    
    """qualifiedModel ::= qualifiedDeclaration typeArguments? ('.' declarationName  typeArguments?)* ;"""
    Model|Type<> qualifiedModel(Tokenizer tokenizer) {
        value d = declaration(tokenizer);
        Type<>[]? ta = typeArguments(tokenizer);
        if (is ClassOrInterfaceDeclaration d) {
            variable Model|Type<> result = d.apply<Anything>(*(ta else []));
            while (tokenizer.isType(dtDot)) {
                value m = declarationName(tokenizer);
                value mta = typeArguments(tokenizer);
                if (is ClassOrInterface<> container=result) {
                    if (is ClassOrInterface<> c = container.getClassOrInterface<Nothing, ClassOrInterface<>>(m, *(mta else []))) {
                        result = c;
                    } else if (exists f=container.getMethod<Nothing,Anything,Nothing>(m, *(mta else []))) {
                        if (tokenizer.isType(dtEoi)) {
                            result = f;
                        } else {
                            throw ParseError("unexpected extra input: ``tokenizer.current``");
                        }
                    } else if (exists a=container.getAttribute<Nothing,Anything,Nothing>(m)) {
                        
                        if (! mta exists) {
                            if (tokenizer.isType(dtEoi)) {
                                result = a;
                            } else {
                                throw ParseError("unexpected extra input: ``tokenizer.current``");
                            }
                        } else {
                            throw ParseError("attribute cannot have type arguments: '``a``'");
                        }
                    } else if (is Class<> c=container,
                        exists ct=c.getConstructor<Nothing>(m)) {
                        if (! mta exists) {
                            result = ct;
                        } else {
                            throw ParseError("constructor cannot have type arguments");
                        }
                    } else {
                        throw ParseError("could not find ``m`` in ``container``");
                    }
                } else {
                    throw ParseError("attempt to look up member ``m`` of ``result`` which is not a ClassOrInterface");
                }
            }
            return result;
        } else if (is FunctionDeclaration d){
            variable Function<> x = d.apply<Anything>(*(ta else []));
            return x;
        } else if (is ValueDeclaration d){
            if (! ta exists) {
                return d.apply<Anything, Nothing>();
            } else {
                throw ParseError("value cannot have type arguments: ``d``");
            }
        } else if (is AliasDeclaration d) {
            // TODO
            throw ParseError("not implemented yet");
        } else if (is Type<Nothing> d) {
            return d;
        } else {
            // SetterDeclaration should be impossible because they're accessed via the Getter
            // ConstructorDeclaration should be impossible because they don't occur at the top level
            throw ParseError("unsupported declaration: ``d``");
        }
    }
    
    """qualifiedDeclaration ::= packageName '::' declarationName ;"""
    Type<>|TypedDeclaration declaration(Tokenizer tokenizer) {
        Package p = packageName(tokenizer);
        tokenizer.expect(dtDColon);
        value t = declarationName(tokenizer);
        if (exists r = p.getMember<NestableDeclaration>(t)) {
            /*if (is ClassDeclaration r,
                exists o=r.objectValue) {
                // find the value of an object declaration in preference to its class
                return o;
             }*/
            return r;
        } else {
            if (t == "Nothing"
                && p.name == "ceylon.language") {
                return nothingType;
            } else {
                throw ParseError("type does not exist: ``t`` in ``p``" );
            }
        }
    }
    
    """typeArgments := '<' intersectionType (',' intersectionType)* '>';"""
    Type<>[]? typeArguments(Tokenizer tokenizer) {
        if (tokenizer.isType(dtLt)) {
            value t1 = intersectionModel(tokenizer);
            if (is Type<> t1) {
                variable Type<>[] result = [t1];
                while(tokenizer.isType(dtComma)) {
                    value t2 = intersectionModel(tokenizer);
                    if (is Type<> t2) {
                        result = result.withTrailing(t2);
                    } else {
                        throw ParseError("non-type appearing as type argument: ``t2``");
                    }
                }
                tokenizer.expect(dtGt);
                return result;
            } else {
                throw ParseError("non-type appearing as type argument: ``t1``");
            }
        } else {
            return null;
        }
    }
    
    """declarationName ::= typeName | memberName ;"""
    String declarationName(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtUpper
            || tokenizer.current.type == dtLower) {
            return tokenizer.consume();
        } else {
            throw ParseError("expected an identifier");
        }
    }
    
    """packageName ::= lident (. lident)* ;"""
    Package packageName(Tokenizer tokenizer) {
        variable String mname = "";
        variable Integer start = tokenizer.index;
        variable Module? mod = null;
        tokenizer.expect(dtLower);
        while (true) {
            if (!mod exists) {
                mname = tokenizer.input.measure(start, tokenizer.index-start);
                for (m in modulesList) {
                    if (m.name == mname) {
                        mod = m;
                        //start = tokenizer.index;
                        break;
                    }
                }
            }
            if (!tokenizer.isType(dtDot)) {
                break;
            }
            tokenizer.expect(dtLower);
        }
        if (exists m=mod) {
            value pname = tokenizer.input.measure(start, tokenizer.index-start);
            if (exists p=m.findPackage(pname)) {
                return p;
            } else {
                throw ParseError("package not found '``pname``'");
            }
        } else {
            throw ParseError("module not found: '``mname``'");
        }
    }
}
"""
   Parses a "fully-qualified reference expression" returning its 
   [[Type]] or [[Model]]. 
   
   Fully-qualified reference expressions are not defined by the
   Ceylon language specification, because in Ceylon source code
   reference expressions always use `import`ed type names, not 
   fully-qualified ones, 
   but the syntax is pretty much as you'd expect. 
   
   When given an expression referencing an `object`, such as
   `ceylon.language::true` this function will return the 
   `Type` in preference to the `Value` model.
   
   Some examples:
   
       ceylon.language::String
       ceylon.language::true     // the Type, not the Value
       ceylon.collection::MutableSet<ceylon.json::Object>
       ceylon.language::String|ceylon.language::Integer
   """
see(`function parseType`)
shared Model|Type<>|ParseError parseModel(String t) => ModelParser().parse(t);

