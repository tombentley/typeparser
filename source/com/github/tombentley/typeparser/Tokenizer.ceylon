
"The tokenizer used by [[TypeParser]]."
class Tokenizer(input) {
    "The input stream that we're tokenizing."
    shared String input;
    
    "Our index into the input."
    variable value ii = 0;
    
    
    function ident(TokenType firstType, String firstChar, Integer start) {
        variable value pos = start;
        while (exists c = input[pos]) {
            if (c.letter || c.digit || c == '_') {
                pos++;
            } else {
                break;
            }
        }
        return Token(firstType, input[start:pos-start], start);
    }
    
    Token at(Integer index) {
        if (exists char = input[ii]) {
            switch (char)
            case ('&') {
                return Token(dtAnd, char.string, ii);
            }
            case ('|') {
                return Token(dtOr, char.string, ii);
            }
            case ('.') {
                return Token(dtDot, char.string, ii);
            }
            case (',') {
                return Token(dtComma, char.string, ii);
            }
            case ('<') {
                return Token(dtLt, char.string, ii);
            }
            case ('>') {
                return Token(dtGt, char.string, ii);
            }
            case (':') {
                // check next is also :
                if (exists char2 = input[ii + 1]) {
                    if (char2 == ':') {
                        return Token(dtDColon, input[ii:2], ii);
                    } else {
                        throw Exception("tokenization error, expected ::, not :``char2`` at index ``ii``: ``input``");
                    }
                }
                throw Exception("unexpected end of input");
            }
            else {
                if ('0' <= char <= '9') {
                    return Token(dtDigit, char.string, ii);
                } else if (char.lowercase) {
                    return ident(dtLower, char.string, ii);
                } else if (char.uppercase) {
                    return ident(dtUpper, char.string, ii);
                } else if (char =="\\") {
                    if (exists char2 = input[ii + 1]) {
                        if (char2 == "I") {
                            return ident(dtUpper, char2.string, ii);
                        } else if (char2 == "i") {
                            return ident(dtLower, char2.string, ii);
                        } else {
                            throw Exception("tokenization error, expected \\i or \\I, not :\\``char2`` at index ``ii``: ``input``");
                        }
                    }
                    throw Exception("unexpected end of input");
                }else {
                    throw Exception("unexpected character ``char`` at index ``ii``: ``input``");
                }
            }
        } else {
            return Token(dtEoi, "", ii);
        }
    }
    
    variable Token current_ = at(0);
    
    "The current token."
    shared Token current {
        return current_;
    }
    
    "Return the current token, moving on to the next token."
    shared String consume() {
        value result = current.token;
        ii += current_.token.size;
        current_ = at(index);
        return result;
    }
    
    "The index of the current token in the input."
    shared Integer index => ii;
    
    "If the current token's type is the given type then consume the 
     token and return it. 
     Otherwise throw an [[AssertionError]]."
    shared String expect(TokenType type) {
        if (current.type == type) {
            return consume();
        } else {
            throw ParseError("unexpected token: expected ``type``, found ``current``: ``input``");
        }
    }
    
    "If the current token's type is the given type then consume and 
     discard the token and return true. 
     Otherwise return false."
    shared Boolean isType(TokenType type) {
        if (current.type == type) {
            consume();
            return true;
        } else {
            return false;
        }
    }
}
