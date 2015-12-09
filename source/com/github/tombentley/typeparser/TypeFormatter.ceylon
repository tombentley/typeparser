import ceylon.language.meta.model {
    Type,
    ClassOrInterface,
    nothingType,
    UnionType,
    IntersectionType
}

"A formatter for [[Type]]s which can use abbreviations, and produced 
 full-qualified and/or unqualified names according to the given 
 [[imports]].
 
 If you don't need abbreviations and do want all types to be 
 fully-qualified using [[type ceylon.language.meta::type]] 
 (i.e. `type(t).string`) will probably be quicker."
shared class TypeFormatter(imports=[],
    optionalAbbreviation=true,
    entryAbbreviation=true,
    sequenceAbbreviation=true,
    tupleAbbreviation=true,
    callableAbbreviation=true,
    iterableAbbreviation=true,
    emptyAbbreviation=true) {
    
    "The imports"
    shared Imports imports;
    
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
    
    Boolean deterministic = true;
    Scope scope = Scope(imports);
    
    "Formats the given type, returning the formatted string."
    shared String format(Type<> type) {
        value sb = StringBuilder();
        formatTo(type, sb);
        return sb.string;
    }
    
    "If the given union contains a single 1-Tuple type `[X]` then 
     return `Type<X>`, otherwise return null"
    function oneTuple(UnionType<Anything> type) {
        value tups = type.caseTypes.narrow<ClassOrInterface<Tuple<Anything,Anything,Anything[]>>>();
        if (tups.size == 1, 
            exists tup = tups.first) {
            //assert(exists firstTa = tup.typeArgumentList[1]);
            return tup;
        } else {
            return null;
        }
    }
    
    """Format the elements of the given Tuple type to the given string builder
     
       * return null if the tuple couldn't be elementized;
         in this case the given string builds hold nonsense,
       * return finished if the tuple could be elementized 
         (and thus the given string builder holds something useful)
         and is not homogenous,
       * return the `[homo, length]` pair if the tuple is homogeneous
         (the given string builder still holds something useful)
    """
    [Type<>, Integer]|Null|Finished formatTupleElements(
            variable Type<> tupleOrEmpty, 
            StringBuilder sb) {
        variable Type<>? homo = null;
        variable Integer couldBeHomo = 0;
        variable Boolean defaulted = false;
        while(true) {
            if (is UnionType<> union=tupleOrEmpty,
                union.caseTypes.size == 2,
                exists t0 = union.caseTypes[0],
                exists t1 = union.caseTypes[1],
                (t0 == `[]` || t1 == `[]`)) {
                defaulted = true;
                if (t0 == `[]`) {
                    tupleOrEmpty = t1;
                } else {
                    tupleOrEmpty = t0;
                }
                continue;
            }
            if (is ClassOrInterface<Tuple<Anything,Anything,Anything[]>> tuple=tupleOrEmpty) {
                assert(exists elementsTa = tuple.typeArgumentList[0]);
                assert(exists firstTa = tuple.typeArgumentList[1]);
                assert(exists restTa = tuple.typeArgumentList[2]);
                if (couldBeHomo==0) {
                    homo = firstTa;
                    couldBeHomo = 1;
                } else if (couldBeHomo > 0) {
                    assert (exists h=homo);
                    if (h==firstTa) {
                        couldBeHomo++;
                    } else {
                        couldBeHomo = -1;
                    }
                }
                formatTo(firstTa, sb);
                if (defaulted) {
                    sb.append("=");
                    defaulted = false;
                }
                if (restTa == `Empty`) {
                    break;
                } else if (restTa.subtypeOf(`Tuple<Anything,Anything,Anything[]>`)) {
                    sb.append(",");
                    tupleOrEmpty = restTa;
                    continue;
                } else if (!defaulted, restTa.subtypeOf(`Sequence<Anything>`)) {
                    sb.append(",");
                    assert(is ClassOrInterface<Sequence<Anything>> restTa);
                    assert(exists z=restTa.typeArgumentList[0]);
                    formatTo(z, sb);
                    sb.append("+");
                    break;
                } else if (!defaulted, restTa.subtypeOf(`Sequential<Anything>`),
                        is ClassOrInterface<Sequential<Anything>> restTa) {
                    sb.append(",");
                    assert(exists z=restTa.typeArgumentList[0]);
                    formatTo(z, sb);
                    sb.append("*");
                    break;
                } else if (is UnionType<> restTa,
                    `[]` in restTa.caseTypes,
                    exists tup=oneTuple(restTa)) {
                    assert(exists firstTax = tup.typeArgumentList[1]);
                    sb.append(",");
                    //formatTo(firstTax, sb2);
                    //sb2.append("=");
                    tupleOrEmpty=tup;
                    defaulted=true;
                    //break;
                    continue;
                } else {
                    return null;//give up
                }
            }
            else {
                return null;
            }
        }
            
        if (couldBeHomo > 1) {
            assert(exists h=homo);
            return [h, couldBeHomo];
        } else {
            return finished;
        }
    }
    
    "Appends the formatting for the given type to the given string builder."
    shared void formatTo(Type<> type, StringBuilder sb) {
        if (is ClassOrInterface<> type) {
            if (tupleAbbreviation && 
                    type.declaration == `interface Sequential`,
                    exists elementTa = type.typeArgumentList[0]) {
                value parens = elementTa is ClassOrInterface<Entry<Object,Anything>>;
                if (parens) {
                    sb.append("<");
                }
                formatTo(elementTa, sb);
                if (parens) {
                    sb.append(">");
                }
                sb.append("[]");
                return;
            } else if (emptyAbbreviation && 
                    type.declaration == `interface Empty`) {
                sb.append("[]");
                return;
            } else if (sequenceAbbreviation && 
                    type.declaration == `interface Sequence`) {
                assert(exists elementTa = type.typeArgumentList[0]);
                sb.append("[");
                formatTo(elementTa, sb);
                sb.append("+]");
                return;
            } else if (iterableAbbreviation && 
                    type.declaration == `interface Iterable`,
                    exists absentTa = type.typeArgumentList[1],
                    absentTa.exactly(`Null`) || absentTa.exactly(`Nothing`)) {
                assert(exists elementTa = type.typeArgumentList[0]);
                sb.append("{");
                formatTo(elementTa, sb);
                if (absentTa.exactly(`Null`)) {
                    sb.append("*}");
                } else {
                    sb.append("+}");
                }
                return;
            } else if (entryAbbreviation && 
                    type.declaration == `class Entry`,
                    exists keyTa = type.typeArgumentList[0],
                    exists itemTa = type.typeArgumentList[1],
                    !keyTa is Type<Entry<Object,Anything>>,
                    !itemTa is Type<Entry<Object,Anything>>) {
                formatTo(keyTa, sb);
                sb.append("->");
                formatTo(itemTa, sb);
                return;
            } else if (tupleAbbreviation, 
                    is ClassOrInterface<Tuple<Anything,Anything,Anything[]>> type) {
                // Iterate here, instead of recurse?
                StringBuilder sb2 = StringBuilder();
                switch(k = formatTupleElements(type, sb2)) 
                case (is Null) {
                    // could figure out tuple elements, fall thru 
                    // to print a verbose Tuple
                } 
                case (is Finished) {
                    // not homogeneous, but we have elements
                    sb.append("[");
                    sb.append(sb2.string);
                    sb.append("]");
                    return;
                } else {
                    // it's a homogeneous tuple!
                    value [homoType, homoLength]=k; 
                    value parens = homoType is UnionType<>|IntersectionType<>
                            || homoType is ClassOrInterface<Entry<Object, Anything>>;
                    if (parens) {
                        sb.append("<");
                    }
                    formatTo(homoType, sb);
                    if (parens) {
                        sb.append(">");
                    }
                    sb.append("[");
                    sb.append(homoLength.string);
                    sb.append("]");
                    return;
                }
            } else if (entryAbbreviation && 
                    type.declaration == `interface Callable`,
                    exists parametersTa = type.typeArgumentList[1],
                    is ClassOrInterface<Tuple<Anything,Anything,Anything[]>> parametersTa) {
                assert(exists resultTa = type.typeArgumentList[0]);
                value parens = resultTa is ClassOrInterface<Entry<Object,Anything>>
                        || resultTa is UnionType<> 
                        || resultTa is IntersectionType<>;
                if (parens) {
                    sb.append("<");
                }
                formatTo(resultTa, sb);
                if (parens) {
                    sb.append(">");
                }
                StringBuilder sb2 = StringBuilder();
                if (formatTupleElements(parametersTa, sb2) exists) {
                    // Note: we don't use the homo tuple repr for callable
                    // thus exists condition ^^ rather than is Finished
                    sb.append("(");
                    sb.append(sb2.string);
                    sb.append(")");
                    return;
                }
                // else formatTupleElements couldn't find the element types
                // shoud never happen with a Type, but fall thru to produce
                // a verbose Tuple
            }
            
            // now do stuff which depends on a having a class declaration
            variable value omitPackage = false;
            value find = scope.find(type.declaration.name);
            if (exists find, find == type.declaration) {
                omitPackage = true; 
            } else {
                sb.append(type.declaration.containingPackage.qualifiedName).append("::");
            }
            sb.append(type.declaration.name);
            value tas = type.typeArgumentList;
            if (!tas.empty) {
                sb.append("<");
                variable value doneFirst = false;
                for (ta in type.typeArgumentList) {
                    if (doneFirst) {
                        sb.append(",");
                    }
                    formatTo(ta, sb);
                    doneFirst = true;
                }
                sb.append(">");
            }
        
        } else if (is UnionType<> type) {
            if (optionalAbbreviation,
                type.caseTypes.size == 2,
                `Null` in type.caseTypes,
                exists t0 = type.caseTypes[0],
                exists t1 = type.caseTypes[1]) {
                Type<> other;
                if (`Null` == t0) {
                    other = t1;
                } else {
                    other = t0;
                }
                value parens = other is ClassOrInterface<Entry<Object,Anything>>
                        || other is IntersectionType<>;
                if (parens) {
                    sb.append("<");
                }
                formatTo(other, sb);
                if (parens) {
                    sb.append(">");
                }
                sb.append("?");
                return;
            } else if (tupleAbbreviation,
                `[]` in type.caseTypes,
                exists tup=oneTuple(type)) {
                // [X=] means []|[X] so any union containing both [] and a 1-tuple
                // can be abbreviated
                
                //formatTo(tup, sb);
                StringBuilder sb2 = StringBuilder();
                if (exists r=formatTupleElements(type, sb2)) {
                    sb.appendCharacter('[');
                    sb.append(sb2.string);
                    sb.append("]");
                    return;
                }
            } 
            variable value doneFirst = false;
            // TODO precedence (eliminate null)
            for (t in sort(type.caseTypes)) {
                if (doneFirst) {
                    sb.append("|");
                } else {
                    doneFirst = true;
                }
                value parens = t is ClassOrInterface<Entry<Object,Anything>>;
                if (parens) {
                    sb.append("<");
                }
                formatTo(t, sb);
                if (parens) {
                    sb.append(">");
                }
            }
        } else if (is IntersectionType<> type) {
            variable value doneFirst = false;
            // TODO precedence
            for (t in sort(type.satisfiedTypes)) {
                if (doneFirst) {
                    sb.append("&");
                } else {
                    doneFirst = true;
                }
                value parens = t is UnionType<>;
                if (parens) {
                    sb.append("<");
                }
                formatTo(t, sb);
                if (parens) {
                    sb.append(">");
                }
            }
        } else if (type == nothingType) {
            value find = scope.find("Nothing");
            if (exists find, find == type) {
                // TODO This is wrong there could be a different nothing before in the imports
                // we need to resolve Nothing using the imports
                sb.append("Nothing");
            } else {
                sb.append("ceylon.language::Nothing");
            }
        }
        
    }
    
    "Sort types into a deterministic order"
    List<Type<>> sort(List<Type<>> types) {
        if (!deterministic) {
            return types;
        }
        Comparison callable(Type<Anything> x, Type<Anything> y) {
            variable Comparison cmp;
            if (is ClassOrInterface<> x,
                    is ClassOrInterface<> y) {
                cmp = x.declaration.containingPackage.qualifiedName <=> y.declaration.containingPackage.qualifiedName;
                if (cmp == equal) {
                    cmp = x.declaration.name <=> y.declaration.name;
                }
                if (cmp == equal) {
                    for ([xta, yta] in zipPairs(x.typeArgumentList, y.typeArgumentList)) {
                        cmp = callable(xta, yta);
                        if (cmp != equal) {
                            return cmp;
                        }
                    }
                    return equal;
                }
                return cmp;
            } else if (is ClassOrInterface<> x ){
                return smaller;
            } else if (is ClassOrInterface<> y){
                return larger;
            } else if (is UnionType<> x, is UnionType<> y) {
                value sortedx = sort(x.caseTypes);
                value sortedy = sort(y.caseTypes);
                for ([xta, yta] in zipPairs(sortedx, sortedy)) {
                    cmp = callable(xta, yta);
                    if (cmp != equal) {
                        return cmp;
                    }
                }
                return equal;
            } else if (is UnionType<> x ){
                return smaller;
            } else if (is UnionType<> y){
                return larger;
            } else if (is IntersectionType<> x, is IntersectionType<> y) {
                value sortedx = sort(x.satisfiedTypes);
                value sortedy = sort(y.satisfiedTypes);
                for ([xta, yta] in zipPairs(sortedx, sortedy)) {
                    cmp = callable(xta, yta);
                    if (cmp != equal) {
                        return cmp;
                    }
                }
                return equal;
            } else if (is IntersectionType<> x ){
                return smaller;
            } else if (is IntersectionType<> y){
                return larger;
            } else {
                // they must both be nothing
                return equal;
            }
        }
        return types.sort(callable);
    }
}