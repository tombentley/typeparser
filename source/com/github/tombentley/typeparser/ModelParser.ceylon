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
    ConstructorModel=CallableConstructor,
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
    shared Model|Type<>|ConstructorModel<> parse(String input) {
        value tokenizer = Tokenizer(input);
        value result = intersectionModel(tokenizer);
        tokenizer.expect(dtEoi);
        return result;
    }
    
    """intersectionType ::= unionType ('&' intersectionType) ;"""
    Model|Type<>|ConstructorModel<> intersectionModel(Tokenizer tokenizer) {
        variable value result = unionModel(tokenizer);
        if (tokenizer.isType(dtAnd)) {
            assert(is Type<> u1=result);
            assert(is Type<> u2 = unionModel(tokenizer));
            result = u1.intersection(u2);
        }
        return result;
    }
    
    """unionType ::= simpleType ('|' intersectionType) ;"""
    Model|Type<>|ConstructorModel<> unionModel(Tokenizer tokenizer) {
        variable value result = qualifiedModel(tokenizer);
        if (tokenizer.isType(dtOr)) {
            assert(is Type<> u1=result);
            assert(is Type<> u2 = intersectionModel(tokenizer));
            result = u1.union(u2);
        }
        return result;
    }
    
    """qualifiedModel ::= qualifiedDeclaration typeArguments? ('.' declarationName  typeArguments?)* ;"""
    Model|Type<>|ConstructorModel<> qualifiedModel(Tokenizer tokenizer) {
        value d = declaration(tokenizer);
        Type<>[]? ta = typeArguments(tokenizer);
        if (is ClassOrInterfaceDeclaration d) {
            variable Model|Type<>|ConstructorModel<> result = d.apply<Anything>(*(ta else []));
            while (tokenizer.isType(dtDot)) {
                value m = declarationName(tokenizer);
                value mta = typeArguments(tokenizer);
                if (is ClassOrInterface<> container=result) {
                    if (is ClassOrInterface<> c = container.getClassOrInterface(m, *(mta else []))) {
                        result = c;
                    } else if (exists f=container.getMethod<Nothing,Anything,Nothing>(m, *(mta else []))) {
                        assert(tokenizer.isType(dtEoi));
                        result = f;
                    } else if (exists a=container.getAttribute<Nothing,Anything,Nothing>(m)) {
                        "attribute cannot have type arguments"
                        assert(! mta exists);
                        assert(tokenizer.isType(dtEoi));
                        result = a;
                    } else if (is Class<> c=container,
                        exists ct=c.getConstructor(m)) {
                        "constructor cannot have type arguments"
                        assert(! mta exists);
                        result = ct;
                    } else {
                        throw AssertionError("could not find ``m`` in ``container``");
                    }
                } else {
                    throw AssertionError("attempt to look up member ``m`` of ``result`` which is not a ClassOrInterface");
                }
            }
            return result;
        } else if (is FunctionDeclaration d){
            variable Function<> x = d.apply<Anything>(*(ta else []));
            return x;
        } else if (is ValueDeclaration d){
            "value cannot have type arguments"
            assert(! ta exists);
            return d.apply<Anything, Nothing>();
        } else if (is AliasDeclaration d) {
            // TODO
            throw AssertionError("not implemented yet");
        } else if (is Type<Nothing> d) {
            return d;
        } else {
            // SetterDeclaration should be impossible because they're accessed via the Getter
            // ConstructorDeclaration should be impossible because they don't occur at the top level
            assert(false);
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
                throw AssertionError("type does not exist: ``t`` in ``p``" );
            }
        }
    }
    
    """typeArgments := '<' intersectionType (',' intersectionType)* '>';"""
    Type<>[]? typeArguments(Tokenizer tokenizer) {
        if (tokenizer.isType(dtLt)) {
            assert(is Type<> t1 = intersectionModel(tokenizer));
            variable Type<>[] result = [t1];
            while(tokenizer.isType(dtComma)) {
                value t2 = intersectionModel(tokenizer);
                assert(is Type<> t2);
                result = result.withTrailing(t2);
            }
            tokenizer.expect(dtGt);
            return result;
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
            throw AssertionError("expected an identifier");
        }
    }
    
    """packageName ::= lident (. lident)* ;"""
    Package packageName(Tokenizer tokenizer) {
        variable Integer start = tokenizer.index;
        variable Module? mod = null;
        tokenizer.expect(dtLower);
        while (true) {
            if (!mod exists) {
                value xx = tokenizer.input.measure(start, tokenizer.index-start);
                for (m in modulesList) {
                    if (m.name == xx) {
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
        assert(exists m=mod);
        assert(exists p=m.findPackage(tokenizer.input.measure(start, tokenizer.index-start)));
        return p;
    }
}

shared Model|Type<>|ConstructorModel<> parseModel(String t) => ModelParser().parse(t);

