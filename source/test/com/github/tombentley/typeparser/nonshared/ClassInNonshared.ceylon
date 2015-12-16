import ceylon.language.meta.model {
    Type
}

shared class ClassInNonshared() {}

class NonsharedClassInNonshared() {}

shared Type<> leakNonsharedClassType => `NonsharedClassInNonshared`;