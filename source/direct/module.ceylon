"this module exists purely so that test.com.github.tombentley.typeparser
 can depend on indirect indirectly via a non-shared import."
module direct "1.0.0" {
    import indirect "1.0.0";
}
