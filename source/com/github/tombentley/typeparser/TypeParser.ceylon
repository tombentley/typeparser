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
    Type,
    Member,
    TypeApplicationException
}

"""
   Parses a "type expression" returning its [[Type]] model. 
   
   Types may be  package-qualified or unqualified. 
   To use unqualified types you need to supply a non-empty
   [[imports]] argument, which determines which type names
   can be used without package-qualification.
   
   To use qualified types the modules containing allow package 
   qualifiers should be passed as the [[fqResolvableModules]] argument. 
   This defaults to modules.list which means any type in the runtime can 
   be expressed.
   
   Fully-qualified type expression are not defined by the
   Ceylon language specification, because in Ceylon source code
   type expressions always use `import`ed type names, not fully-qualified ones, 
   but the syntax is pretty much as you'd expect. 
   
   For example:
   
       ceylon.language::String
       ceylon.language::true     // type Type, not the Value
       ceylon.collection::MutableSet<ceylon.json::Object>
   """
shared class TypeParser(
    imports=[], 
    fqResolvableModules = modules.list) {
    
    // TODO fix precedence
    // TODO support abbreviated types!
    
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
    "The imports"
    shared Imports imports;
    
    "The modules used for resolving packages when parsing fully-qualified 
     type names. First-wins policy of modules 
     with duplicate names. Defaults to `modules.list`."
    shared Module[] fqResolvableModules;
    
    "Whether to allow unqualified type names"
    Boolean allowUq = !imports.empty;
    "Whether to allow fully-qualified type names"
    Boolean allowFq = !fqResolvableModules.empty;
    Scope scope = Scope(imports);
    value modMap = map({for (m in fqResolvableModules) m.name->m});
    
    """input ::= intersectionType ;"""
    shared Type<>|ParseError parse(String input) {
        try {
            value tokenizer = Tokenizer(input);
            value result = intersectionType(tokenizer);
            tokenizer.expect(dtEoi);
            return result;
        } catch (ParseError e) {
            return e;
        }
    }
    
    """intersectionType ::= unionType ('&' intersectionType) ;"""
    Type<> intersectionType(Tokenizer tokenizer) {
        variable Type<> result = unionType(tokenizer);
        if (tokenizer.isType(dtAnd)) {
            Type<> u2 = unionType(tokenizer);
            result = result.intersection(u2);
        }
        return result;
    }
    
    """unionType ::= simpleType ('|' intersectionType) ;"""
    Type<> unionType(Tokenizer tokenizer) {
        variable Type<> result = simpleType(tokenizer);
        if (tokenizer.isType(dtOr)) {
            Type<> u2 = intersectionType(tokenizer);
            result = result.union(u2);
        }
        return result;
    }
    
    """simpleType ::= declaration typeArguments? ('.' typeName typeArguments?)* ;"""
    Type<> simpleType(Tokenizer tokenizer) {
        value d = declaration(tokenizer);
        Type<>[] ta = if (tokenizer.current.type == dtLt) then typeArguments(tokenizer) else [];
        
        if (is ClassOrInterfaceDeclaration d) {
            variable ClassOrInterface<> x;
            try {
                x = d.apply<Anything>(*ta);
            } catch (TypeApplicationException e) {
                value tas = if (ta.empty) then "" else ta.string.replaceFirst("[", "<").replaceLast("]", ">");
                throw ParseError("erronerous type instantiation ``d.qualifiedName+tas``: ``e.message``");
            }
            while (tokenizer.isType(dtDot)) {
                value mt = typeName(tokenizer);
                value mta = if (tokenizer.current.type == dtLt) then typeArguments(tokenizer) else [];
                Member<Nothing,ClassOrInterface<Anything>>? k;
                try {
                    k = x.getClassOrInterface<Nothing, ClassOrInterface<>>(mt, *mta);
                } catch (TypeApplicationException e) {
                    value tas = if (mta.empty) then "" else mta.string.replaceFirst("[", "<").replaceLast("]", ">");
                    throw ParseError("erronerous type instantiation ``mt+tas.string``: ``e.message``");
                    
                }
                if (is ClassOrInterface<Anything> k) {
                    x = k;
                } else if (exists k){
                    throw ParseError("member type neither class nor interface: ``mt`` member of ``x.declaration.qualifiedName`` is a ``k``");
                } else {
                    throw ParseError("member type does not exist: ``mt`` member of ``x.declaration.qualifiedName``");
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
    
    "Look up the type `t` in the givin package, or in the imports if the given 
     package is null"
    ClassOrInterfaceDeclaration|Type<>? lookup(Package? p, String t) {
        if (exists p) {
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
                }
                return null;
            }
        } else {
            return scope.find(t);
        }
    }
    
    """declaration ::= packageName '::' typeName ;"""
    Type<>|ClassOrInterfaceDeclaration declaration(Tokenizer tokenizer) {
        
        Package? p = if (allowFq) then packageName(tokenizer) else null;
        value t = typeName(tokenizer);
        if (exists r = lookup(p, t)) {
            return r;
        } else {
            throw ParseError("type does not exist: '``t``' in '``p else scope``'" );
        }
    }
    
    """typeArgments := '<' intersectionType (',' intersectionType)* '>';"""
    Type<>[] typeArguments(Tokenizer tokenizer) {
        tokenizer.expect(dtLt);
        variable Type<>[] result = [];
        while(true) {
            value t = intersectionType(tokenizer);
            result = result.withTrailing(t);
            if (!tokenizer.isType(dtComma)) {
                break;
            }
        }
        tokenizer.expect(dtGt);
        return result;
    }
    
    """typeName ::= uident;"""
    String typeName(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtUpper
            ||tokenizer.current.type == dtLower) {
            return tokenizer.consume();
        } else {
            throw ParseError("unexpected token: expected ``dtUpper`` or ``dtLower``, found ``tokenizer.current``: ``tokenizer.input``");
        }
        //return tokenizer.expect(dtUpper);
    }
    
    """packageName ::= lident (. lident)* `::` ;"""
    Package? packageName(Tokenizer tokenizer) {
        variable String mname = "";
        variable Integer start = tokenizer.index;
        variable Module? mod = null;
        lident(tokenizer);
        while (true) {
            if (!mod exists) {
                mname = tokenizer.input.measure(start, tokenizer.index-start);
                mod = modMap[mname];
            }
            if (tokenizer.isType(dtDColon)) {
                break;
            } else if (tokenizer.isType(dtDot)) {
                lident(tokenizer);
            } else {
                if (!allowUq) {
                    if (mod exists) {
                        throw ParseError("package not found: '``tokenizer.input.measure(start, tokenizer.index-start)``'");
                    } else {
                        throw ParseError("module not found: '``mname``'");
                    }
                }
                tokenizer.setIndex(start);
                return null;
            }
        }
        if (exists m=mod) {
            value pname = tokenizer.input.measure(start, tokenizer.index-start-2);
            if(exists p=m.findPackage(pname)) {
                return p;
            } else {
                throw ParseError("package not found: '``pname``'");
            }
        } else {
            throw ParseError("module not found: '``mname``'");
        }
    }
    
    String? lident(Tokenizer tokenizer) {
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
shared Type<>|ParseError parseType(String t, Imports imports=[]) => TypeParser(imports).parse(t);
