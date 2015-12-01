"A token produced by a lexer"
class Token(shared Object type, shared String token, shared Integer index) {
    shared actual String string => "``token`` (``type``) at index ``index``";
}

"enumerates the different token types"
abstract class TokenType(shared actual String string)
        of dtAnd | dtOr | dtDot | dtComma | dtDColon | dtGt | dtLt 
        | dtDigit | dtUpper | dtLower | dtEoi {}

object dtAnd extends TokenType("&") {}
object dtOr extends TokenType("|") {}
object dtDot extends TokenType(".") {}
object dtComma extends TokenType(",") {}
object dtDColon extends TokenType("::") {}
object dtGt extends TokenType(">") {}
object dtLt extends TokenType("<") {}
object dtDigit extends TokenType("digit") {}
object dtUpper extends TokenType("upper") {}
object dtLower extends TokenType("lower") {}
object dtEoi extends TokenType("<eoi>") {}

