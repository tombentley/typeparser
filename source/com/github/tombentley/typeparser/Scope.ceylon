import ceylon.language.meta.declaration {
    Package,
    ClassOrInterfaceDeclaration,
    ValueDeclaration
}
import ceylon.language.meta.model {
    Type,
    nothingType
}

// only shared for testing
shared alias Imports=>List<Package|ClassOrInterfaceDeclaration|<String->ClassOrInterfaceDeclaration>>;


"""Represents a "set of imports", thus allowing [[TypeParser]] to support 
   unqualified types.
   
   
   """
// only shared for testing
class Scope(imports=[]/*, allowFq = imports == []*/) {
    
    "The imported types:
     * For import-alias functionality use an entry. 
     * For wildcard import functionality use a [[Package]].
    "
    Imports imports;
    
    shared ClassOrInterfaceDeclaration|Type<>? find(String name) {
        // XXX it might be worth memoizing the results form this method, 
        // to avoid a linear scan for things (e.g. Integer, String) 
        // which are searched for repeatedly.
        for (s in imports) {
            switch (s)
            case (is Package) {
                if (exists c = s.getClassOrInterface(name)) {
                    return c;
                } else if (exists first = name.first,
                    first.lowercase,
                    exists d = s.getMember<ValueDeclaration>(name)) {
                    // special case for object types
                    return d.apply<Anything,Nothing>().type;
                } else if (name == "Nothing",
                    s.name == "ceylon.language") {
                    // special case for Nothing
                    return nothingType;
                }
                
            }
            case (is String->ClassOrInterfaceDeclaration) {
                if (s.key == name) {
                    return s.item;
                }
            }
            case (is ClassOrInterfaceDeclaration) {
                if (s.name == name) {
                    return s;
                }
            }
        }
        return null;
    }
    
    shared actual String string {
        StringBuilder sb = StringBuilder();
        sb.append("imports ");
        variable Boolean first = false;
        for (item in imports) {
            if (first) {
                sb.append(",");
            } else {
                first = true;
            }
            switch (item)
            case (is Package) {
                sb.append(item.name).append(" { ... }");
            }
            case (is String->ClassOrInterfaceDeclaration) {
                sb.append(item.key).append("=").append(item.item.qualifiedName);
            }
            case (is ClassOrInterfaceDeclaration) {
                sb.append(item.qualifiedName);
            }
        }
        return sb.string;
    }
}