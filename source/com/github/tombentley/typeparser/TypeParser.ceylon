import ceylon.language.meta {
    modules
}
import ceylon.language.meta.declaration {
    ValueDeclaration,
    Module,
    Package,
    ClassOrInterfaceDeclaration
}
import ceylon.language.meta.model {
    ClassOrInterface,
    ClassModel,
    nothingType,
    InterfaceModel,
    Type
}

"""
   input ::= intersectionType ;
   intersectionType ::= unionType ('&' intersectionType) ;
   unionType ::= simpleType ('|' intersectionType) ;
   simpleType ::= declaration typeArguments? ('.' typeName typeArguments?)* ;
   declaration ::= packageName '::' typeName ;
   packageName ::= lident (. lident)* ;
   typeName ::= uident;
   typeArgments := '<' intersectionType (',' intersectionType)* '>';
   
   """
class TypeParser(String input) {
    
    value tokenizer = Tokenizer(input);
    
    """input ::= intersectionType ;"""
    shared Type<> parse() {
        value result = intersectionType();
        tokenizer.expect(dtEoi);
        return result;
    }
    
    """intersectionType ::= unionType ('&' intersectionType) ;"""
    Type<> intersectionType() {
        variable Type<> result = unionType();
        if (tokenizer.isType(dtAnd)) {
            Type<> u2 = unionType();
            result = result.intersection(u2);
        }
        return result;
    }
    
    """unionType ::= simpleType ('|' intersectionType) ;"""
    Type<> unionType() {
        variable Type<> result = simpleType();
        if (tokenizer.isType(dtOr)) {
            Type<> u2 = intersectionType();
            result = result.union(u2);
        }
        return result;
    }
    
    """simpleType ::= declaration typeArguments? ('.' typeName typeArguments?)* ;"""
    Type<> simpleType() {
        value d = declaration();
        Type<>[] ta;
        if (tokenizer.current.type == dtLt) {
            ta = typeArguments();
        } else {
            ta = [];
        }
        if (is ClassOrInterfaceDeclaration d) {
            variable ClassOrInterface<> x = d.apply<Anything>(*ta);
            while (tokenizer.isType(dtDot)) {
                value mt = typeName();
                value mta = typeArguments();
                assert(is ClassModel<>|InterfaceModel<> k = x.getClassOrInterface(mt, *mta));
                x = k;
            }
            return x;
        } else {
            assert(ta.empty,
                !tokenizer.isType(dtDot));
            return d;
        }
    }
    
    """declaration ::= packageName '::' typeName ;"""
    Type<>|ClassOrInterfaceDeclaration declaration() {
        Package p = packageName();
        tokenizer.expect(dtDColon);
        value t = typeName();
        if (exists r = p.getClassOrInterface(t)) {
            return r;
        } else if (exists f=t.first,
            f.lowercase,
            exists r = p.getMember<ValueDeclaration>(t)) {
            return r.apply<Anything,Nothing>().type;
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
    Type<>[] typeArguments() {
        tokenizer.expect(dtLt);
        variable Type<>[] result = [];
        while(true) {
            value t = intersectionType();
            result = result.withTrailing(t);
            if (!tokenizer.isType(dtComma)) {
                break;
            }
        }
        tokenizer.expect(dtGt);
        return result;
    }
    
    """typeName ::= uident;"""
    String typeName() {
        if (tokenizer.current.type == dtUpper
            ||tokenizer.current.type == dtLower) {
            return tokenizer.consume();
        } else {
            throw AssertionError("unexpected token: expected ``dtUpper`` or ``dtLower``, found ``tokenizer.current``: ``input``");
        }
        //return tokenizer.expect(dtUpper);
    }
    
    """packageName ::= lident (. lident)* ;"""
    Package packageName() {
        variable Integer start = tokenizer.index;
        variable Module? mod = null;
        lident();
        while (true) {
            if (!mod exists) {
                value xx = tokenizer.input.measure(start, tokenizer.index-start);
                for (m in modules.list) {
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
            lident();
        }
        assert(exists m=mod);
        assert(exists p=m.findPackage(tokenizer.input.measure(start, tokenizer.index-start)));
        return p;
    }
    String? uident() {
        if (tokenizer.current.type == dtUpper) {
            value result = tokenizer.current.token;
            tokenizer.consume();
            return result;
        } else {
            return null;
        }
    }
    String? lident() {
        if (tokenizer.current.type == dtLower) {
            value result = tokenizer.current.token;
            tokenizer.consume();
            return result;
        } else {
            return null;
        }
    }
}

shared Type<> parseType(String t) => TypeParser(t).parse();
