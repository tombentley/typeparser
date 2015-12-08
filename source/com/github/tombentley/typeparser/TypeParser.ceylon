import ceylon.collection {
    ArrayList
}
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
    nothingType,
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
    fqResolvableModules = modules.list,
    optionalAbbreviation=true,
    entryAbbreviation=true,
    sequenceAbbreviation=true,
    tupleAbbreviation=true,
    callableAbbreviation=true,
    iterableAbbreviation=true,
    emptyAbbreviation=true) {
    
    "Whether to support optional abbreivation syntax `X?`."
    Boolean optionalAbbreviation;
    "Whether to support entry abbreivation syntax `X->Y`."
    Boolean entryAbbreviation;
    "Whether to support sequential abbreivation syntax `X[]`, `[Y*]` and `[Z+]`."
    Boolean sequenceAbbreviation;
    "Whether to support tuple abbreivation syntax `[X,Y]` and `X[3]`."
    Boolean tupleAbbreviation;
    "Whether to support callable abbreivation syntax `X(Y)`."
    Boolean callableAbbreviation;
    "Whether to support iterable abbreivation syntax `{X+}` and `{Y*}`."
    Boolean iterableAbbreviation;
    "Whether to support empty abbreivation syntax `[]`."
    Boolean emptyAbbreviation;
    
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
            value result=parseType(tokenizer);
            tokenizer.expect(dtEoi);
            return result;
        } catch (ParseError e) {
            return e;
        }
    }
    
    
    Type<> parseType(Tokenizer tokenizer) {
        variable value result = parseUnionType(tokenizer);
        if (entryAbbreviation && tokenizer.isType(dtRightArrow)) {
            result = parseEntryType(tokenizer, result);
        }
        return result;
    }
    
    Type<> parseEntryType(Tokenizer tokenizer, variable Type<Anything> keyType) {
        value itemType = parseUnionType(tokenizer);
        return `class Entry`.classApply<Anything,Nothing>(keyType, itemType);
    }
    
    """unionType ::= simpleType ('|' intersectionType) ;"""
    Type<> parseUnionType(Tokenizer tokenizer) {
        variable Type<> result = parseIntersectionType(tokenizer);
        if (tokenizer.isType(dtOr)) {
            Type<> u2 = parseIntersectionType(tokenizer);
            result = result.union(u2);
        }
        return result;
    }
    
    """intersectionType ::= unionType ('&' intersectionType) ;"""
    Type<> parseIntersectionType(Tokenizer tokenizer) {
        variable Type<> result = primaryType(tokenizer);
        if (tokenizer.isType(dtAnd)) {
            Type<> u2 = primaryType(tokenizer);
            result = result.intersection(u2);
        }
        return result;
    }
    
    // PrimaryType: AtomicType | OptionalType | SequenceType | CallableType
    //
    // OptionalType: PrimaryType '?'
    // SequenceType: PrimaryType "[" "]"
    // CallableType: PrimaryType "(" TypeList? | SpreadType ")"
    Type<> primaryType(Tokenizer tokenizer) {
        variable Type<> t = atomicType(tokenizer);
        while (tokenizer.current.type == dtQn
            || tokenizer.current.type == dtLsq
            || tokenizer.current.type == dtLparen) {
            if (optionalAbbreviation && tokenizer.current.type == dtQn) {
                t = optionalType(tokenizer, t);
            } else if (sequenceAbbreviation 
                    && tokenizer.current.type == dtLsq) {
                if (tokenizer.lookAhead(1).type == dtRsq) {
                    t = sequenceType(tokenizer, t);
                } else if (tokenizer.lookAhead(1).type == dtDigit) {
                    t = tupleLength(tokenizer, t);
                }
            } else if (callableAbbreviation 
                    && tokenizer.current.type == dtLparen) {
                t = callableType(tokenizer, t);
            }
        }
        return t;
    }
    
    // OptionalType: PrimaryType '?'
    Type<> optionalType(Tokenizer tokenizer, Type<> baseType) {
        tokenizer.expect(dtQn);
        return baseType.union(`Null`);
    }
    
    // SequenceType: PrimaryType "["
    Type<> sequenceType(Tokenizer tokenizer, Type<> elementType) {
        tokenizer.expect(dtLsq);
        tokenizer.expect(dtRsq);
        return `interface Sequential`.interfaceApply<Anything>(elementType);
    }
    
    // CallableType: PrimaryType "(" TypeList? | SpreadType ")"
    Type<> callableType(Tokenizer tokenizer, Type<> returnType) {
        tokenizer.expect(dtLparen);
        if (tokenizer.current.type == dtStar) {
            // SpreadType would imply 
            tokenizer.consume();// *
            value spread = parseUnionType(tokenizer);
            tokenizer.expect(dtRparen);
            //assert(is Type<Anything[]> spread);
            return `interface Callable`.interfaceApply<Anything>(*[returnType, spread]);
        } else {
            // TypeList?
            Type<> argumentTuple;
            if (tokenizer.current.type == dtRparen) {
                tokenizer.consume();
                argumentTuple = `Empty`;
            } else {
                value typeList = this.typeList(tokenizer);
                tokenizer.expect(dtRparen);
                // TODO make a tuple from the listed type
                argumentTuple = typeList; 
            }
            return `interface Callable`.interfaceApply<Anything>(*[returnType, argumentTuple]);
        }
    }
    
    
    // AtomicType: QualifiedType | EmptyType | TupleType | IterableType
    // EmptyType: "[" "]"
    // TupleType: "[" TypeList "]" | PrimaryType "[" DecimalLiteral "]"
    // IterableType: "{" UnionType ("*"|"+") "}"
    Type<> atomicType(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtLsq) {
            if (tokenizer.lookAhead(1).type == dtRsq) {
                if (emptyAbbreviation) {
                    tokenizer.consume();// [
                    tokenizer.consume();// ]
                    return `Empty`;
                } else {
                    throw ParseError("empty abbreviation not supported");
                }
            } else {
                if (tupleAbbreviation) {
                    return tupleType(tokenizer);
                } else {
                    throw ParseError("tuple abbreviation not supported");
                }
            }
        } else if (iterableAbbreviation && tokenizer.current.type == dtLbr) {
            return iterableType(tokenizer);
        } else {
            // TODO Could be either QualifiedType or TupleType with a 
            // DecimalLiteral
            return qualifiedType(tokenizer);
        }
    }
    // IterableType: "{" UnionType ("*"|"+") "}"
    Type<> iterableType(Tokenizer tokenizer) {
        tokenizer.expect(dtLbr);
        value iteratedType = parseUnionType(tokenizer);
        Type<> absentType;
        if (tokenizer.current.type == dtStar) {
            tokenizer.consume();
            absentType = `Null`;
        } else if (tokenizer.current.type == dtPlus) {
            tokenizer.consume();
            absentType = `Nothing`;
        } else {
            throw ParseError("badly formed iterable type");
        }
        tokenizer.expect(dtRbr);
        return `interface Iterable`.interfaceApply<Anything>(*[iteratedType, absentType]);
    }
    
    
    Type<> tupleLength(Tokenizer tokenizer, Type<Anything> elementType) {
        tokenizer.expect(dtLsq);
        variable value d = tokenizer.expect(dtDigit);
        assert(exists c1 = d.first);
        variable value int = c1.offset('0');
        while (tokenizer.current.type == dtDigit) {
                d = tokenizer.expect(dtDigit);
                assert(exists c2 = d.first); 
                int = 10 * int + c2.offset('0');
            }
        tokenizer.expect(dtRsq);
        variable Type<> t = `Empty`;
        while (int > 0) {
                t = `class Tuple`.apply<Anything>(*[elementType, elementType, t]);
                int--;
            }
        return t;
    }
    
    // TupleType: "[" TypeList "]" | PrimaryType "[" DecimalLiteral "]"
    Type<> tupleType(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtLsq) {
            // TODO TypeList
            tokenizer.consume();
            value typeList = this.typeList(tokenizer);
            tokenizer.expect(dtRsq);
            return typeList;
        } else {
            value elementType = primaryType(tokenizer);
            return tupleLength(tokenizer, elementType);
        }
        
    }
    
    // TypeList: (DefaultedType ",")* (DefaultedType | VariadicType)
    // DefaultedType: Type "="?
    // VariadicType: UnionType ("*" | "+")
    Type<Anything> typeList(Tokenizer tokenizer) {
        // TODO Diff between a type and a UnionType is a Type could be an entry type
        // So we can parse DefaultedType using UnionType, and handle Entry's by hand
        // Thus avoiding backtracking 
        variable value index = tokenizer.index;
        value types = ArrayList<Type<>->Boolean>();
        variable value t = defaultedType(tokenizer);
        variable value hasDefaults = t.item;
        types.add(t);
        while (tokenizer.current.type == dtComma) {
            tokenizer.consume();
            index = tokenizer.index;
            value t2 = defaultedType(tokenizer);
            hasDefaults = t2.item || hasDefaults;
            types.add(t2);
        }
        // TODO backtrack because the last matched type was a DefaultedType, 
        // but maybe a VariadicType would've matched more
        Integer defaultedIndex = tokenizer.index;
        tokenizer.setIndex(index);
        variable Type<> rest;
        variable Type<> element;
        if (exists v = variadicType(tokenizer)) {
            types.deleteLast();
            if (v.item) {
                if (hasDefaults) {
                    throw ParseError("nonempty variadic element must occur after defaulted elements in a tuple type");
                }
                rest = `interface Sequence`.interfaceApply<Anything>(v.key);
            } else {
                rest = `interface Sequential`.interfaceApply<Anything>(v.key);
            }
            element = v.key;
        } else {
            // variadicType didn't match, so it *was* a defaulted type
            tokenizer.setIndex(defaultedIndex);
            rest = `Empty`;
            element = `Nothing`;
        }
        variable Type<> result = rest;
        //variable value unions = ArrayList{rest->element};
        variable Boolean seenNonDefault = false;
        for (first->defaulted in types.reversed) {
            element = first.union(element);
            result = `class Tuple`.classApply<Anything,Nothing>(element, first, result);
            if (defaulted) {
                if (seenNonDefault) {
                    throw ParseError("required element must occur after defaulted elements in a tuple type");
                }
                result = defaulted then result.union(`Empty`) else result;
            } else {
                seenNonDefault = true;
            }
        }
        /*
        variable Type<> result = `Nothing`;
        for (r->_ in unions) {
            result = r.union(result);
        }
        */
        return result;
    }
    
    // DefaultedType: Type "="?
    Type<>->Boolean defaultedType(Tokenizer tokenizer) {
        variable Type<> t = parseType(tokenizer);
        if (tokenizer.current.type == dtEquals) {
            tokenizer.consume();
            return t->true;
        }
        return t->false;
    }
    
    <Type<>->Boolean>? variadicType(Tokenizer tokenizer) {
        variable Type<> t = parseUnionType(tokenizer);
        if (tokenizer.current.type == dtStar) {
            tokenizer.consume();
            return t->false;
        } else if (tokenizer.current.type == dtPlus) {
            tokenizer.consume();
            return t->true;
        }
        return null;
    }
    
    """simpleType ::= declaration typeArguments? ('.' typeName typeArguments?)* ;"""
    // QualifiedType: BaseType ( '.' TypeNameWithArguments) *
    Type<> qualifiedType(Tokenizer tokenizer) {
        variable Type<>|ClassOrInterface<> t = parseBaseType(tokenizer);
        
        while (tokenizer.current.type == dtDot) {
            tokenizer.isType(dtDot);
            if (is ClassOrInterface<> x=t) {
                t = parseTypeNameWithArguments_qualifiedType(tokenizer, x);
            }
        }
        return t;
        
    }
    
    // TypeNameWithArguments: TypeName TypeArguments?
    ClassOrInterface<> parseTypeNameWithArguments_qualifiedType(Tokenizer tokenizer, ClassOrInterface<Anything> qualifyingType) {
        value mt = parseTypeName(tokenizer);
        value mta = if (tokenizer.current.type == dtLt) then parseTypeArguments(tokenizer) else [];
        Member<Nothing,ClassOrInterface<Anything>>? k;
        try {
            k = qualifyingType.getClassOrInterface<Nothing, ClassOrInterface<>>(mt, *mta);
        } catch (TypeApplicationException e) {
            value tas = if (mta.empty) then "" else mta.string.replaceFirst("[", "<").replaceLast("]", ">");
            throw ParseError("erronerous type instantiation ``mt+tas.string``: ``e.message``");
        }
        
        if (is ClassOrInterface<Anything> k) {
            return k;
        } else if (exists k){
            throw ParseError("member type neither class nor interface: ``mt`` member of ``qualifyingType.declaration.qualifiedName`` is a ``k``");
        } else {
            throw ParseError("member type does not exist: ``mt`` member of ``qualifyingType.declaration.qualifiedName``");
        }
    }
    
    // TypeNameWithArguments: TypeName TypeArguments?
    Type<> parseTypeNamedWithArguments_BaseType(Tokenizer tokenizer, Package? p) {
        value t = parseTypeName(tokenizer);
        if (exists d = lookup(p, t)) {
            /**/
            Type<>[] ta = if (tokenizer.current.type == dtLt) then parseTypeArguments(tokenizer) else [];
            
            if (is ClassOrInterfaceDeclaration d) {
                variable ClassOrInterface<> x;
                try {
                    x = d.apply<Anything>(*ta);
                } catch (TypeApplicationException e) {
                    value tas = if (ta.empty) then "" else ta.string.replaceFirst("[", "<").replaceLast("]", ">");
                    throw ParseError("erronerous type instantiation ``d.qualifiedName+tas``: ``e.message``");
                }
                return x;
            } else {
                if (ta.empty,
                    !tokenizer.isType(dtDot)) {
                    return d;
                }
                throw ParseError("unsupported generic declaration: ``d``");
            }
        } else {
            throw ParseError("type does not exist: '``t``' in '``p else scope``'" );
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
    
    Package? parsePackageQualifier(Tokenizer tokenizer) {
        Package? p = if (allowFq) then packageName(tokenizer) else null;
        return p;
    }
    
    """declaration ::= packageName '::' typeName ;"""
    //  BaseType: PackageQualifier? TypeNameWithArguments | GroupedType
    Type<> parseBaseType(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtLt) {
            //GroupedType
            return parseGroupedType(tokenizer);
        } else {
            // PackageQualifier?
            Package? p = parsePackageQualifier(tokenizer);
            return parseTypeNamedWithArguments_BaseType(tokenizer, p);
        }
    }
    
    // GroupedType: '<' Type '>
    Type<> parseGroupedType(Tokenizer tokenizer) {
        tokenizer.expect(dtLt);
        value result = parseType(tokenizer);
        tokenizer.expect(dtGt);
        return result;
    }
    
    // TypeArgument: Variance Type
    function parseTypeArgument(Tokenizer tokenizer) {
        if (tokenizer.current.type == dtIn
            || tokenizer.current.type == dtOut) {
            throw ParseError("use-site variance not supported in the metamodel");
        }
        value t = parseType(tokenizer);
        return t;
    }
    
    """typeArgments := '<' intersectionType (',' intersectionType)* '>';"""
    // TypeArguments: "<" ((TypeArgument ",")* TypeArgument)? ">" 
    Type<>[] parseTypeArguments(Tokenizer tokenizer) {
        tokenizer.expect(dtLt);
        variable Type<>[] result = [];
        while(true) {
            value t=parseTypeArgument(tokenizer);
            result = result.withTrailing(t);
            if (!tokenizer.isType(dtComma)) {
                break;
            }
        }
        tokenizer.expect(dtGt);
        return result;
    }
    
    """typeName ::= uident;"""
    // TypeName : UIdentifier
    String parseTypeName(Tokenizer tokenizer) {
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
shared Type<>|ParseError parseType(String t, 
    Imports imports=[],
    Boolean optionalAbbreviation=true,
    Boolean entryAbbreviation=true) => TypeParser { 
        imports = imports; 
        optionalAbbreviation = optionalAbbreviation; 
        entryAbbreviation = entryAbbreviation;
    }.parse(t);
