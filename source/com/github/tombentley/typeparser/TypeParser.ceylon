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



class TypeParser(String input) {
    /*
     
     input ::= intersectionType ;
     intersectionType ::= unionType ('&' intersectionType) ;
     unionType ::= simpleType ('|' intersectionType) ;
     simpleType ::= declaration typeArguments? ('.' typeName typeArguments?)* ;
     declaration ::= packageName '::' typeName ;
     packageName ::= lident (. lident)* ;
     typeName ::= uident;
     typeArgments := '<' intersectionType (',' intersectionType)* '>';
     
     */
    
    value tokenizer = Tokenizer(input);
    
    """input ::= intersectionType ;"""
    shared Type<>|ParseError parse() {
        try {
            value result = intersectionType();
            tokenizer.expect(dtEoi);
            return result;
        } catch (ParseError e) {
            return e;
        }
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
                if (is ClassModel<>|InterfaceModel<> k = x.getClassOrInterface(mt, *mta)) {
                    x = k;
                } else {
                    throw ParseError("member type neither class nor interface: ``mt`` member of ``x``");
                }
            }
            return x;
        } else {
            if (ta.empty,
                !tokenizer.isType(dtDot)) {
                return d;
            }
            throw ParseError("unsupported generic declaration: ``d``");
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
                throw ParseError("type does not exist: '``t``' in '``p``'" );
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
            throw ParseError("unexpected token: expected ``dtUpper`` or ``dtLower``, found ``tokenizer.current``: ``input``");
        }
        //return tokenizer.expect(dtUpper);
    }
    
    """packageName ::= lident (. lident)* ;"""
    Package packageName() {
        variable String mname = "";
        variable Integer start = tokenizer.index;
        variable Module? mod = null;
        lident();
        while (true) {
            if (!mod exists) {
                mname = tokenizer.input.measure(start, tokenizer.index-start);
                for (m in modules.list) {
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
            lident();
        }
        if (exists m=mod) {
            value pname = tokenizer.input.measure(start, tokenizer.index-start);
            if(exists p=m.findPackage(pname)) {
                return p;
            } else {
                throw ParseError("package not found: '``pname``'");
            }
        } else {
            throw ParseError("module not found: '``mname``'");
        }
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

"""
   Parses a "fully-qualified type expression" returning its [[Type]] model. 
   
   Fully-qualified type expression are not defined by the
   Ceylon language specification, because in Ceylon source code
   type expressions always use `import`ed type names, not fully-qualified ones, 
   but the syntax is pretty much as you'd expect. 
   
   For example:
   
       ceylon.language::String
       ceylon.language::true     // type Type, not the Value
       ceylon.collection::MutableSet<ceylon.json::Object>
   
   """
see(`function parseModel`)
shared Type<>|ParseError parseType(String t) => TypeParser(t).parse();
