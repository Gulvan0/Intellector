# Code style conventions

Example (illustrates all principles except for p. 3):

```
/*
    Some non-docstring comments
    about this class
*/
class SomeClass
{
    /**
        Some docstring
    **/
    public static function someMethod(someArg:SomeType, someCallback:SomeCallbackArgType->OtherCallbackArgType->SomeCallbackReturnType):OtherType
    {
        if (someArg > 0)
        {
            var result:Array<Int> = someFunc(someArg, someCallback, x -> {
                trace(x + 1);
            });
            trace(result);
        }

        // Single-line comments should use double-slash style
        if (someArg < 0)
            trace(someArg);

        var someAnonStructure:SomeTypedef = {
            fieldA: "abc",
            fieldB: "foo"
        };

        switch someVar
        {
            case 1:
                trace("Success");
        }

        return switch otherVar {
            case 2: "No";
            default: "Yes";
        }
    }
}
```

1. Indentation

Indentation is done via spaces. A single indent level equals 4 spaces.

2. Allman-style curly braces

Curly braces should generally use Allman style unless they or the control statement (e.g. `switch`) they are part of represent rvalue (being an RHS of some operator). In particular, arrow function bodies (`x -> { ... }`) always use K&R style: the brace goes on the same line as `->`, regardless of the arrow's own position (including when the arrow itself trails a preceding line, as in a function call argument list).

Single-line `if` and `for` bodies should be written without curly braces, but ALWAYS on a new line, with indent level greater by 1 than one that `if`/`for` has.

3. Descriptive identifiers

One should be able to get the general idea of the meaning and/or purpose of variables, functions, classes etc. by looking at their names. The names should be laconic, but clarity is more important. Never use contractions and abbreviations unless widely known and accepted (e.g. DTO for Data Transfer Object). Abbreviations are to be treated as normal words: the letters starting from the second one should be lowercase.

Type parameters are allowed to have 1-letter names.

Loop variable in a `for (i in x...y)` loop is allowed to be named `i` (or `j`, `k` for nested loops) if it's an index. If a loop variable is unused, it SHOULD be named `_` (unless there is another variable with the same name).

Constant (`static [inline] final`) class variables should have uppercase identifiers.

4. Explicit types

All variables should be annotated with proper types explicitly. Don't use Dynamic unless absolutely have to.

5. `switch`

Switch as a control statement uses Allman braces. Its case body expressions start with the newline and their indent level is greater by 1 than the indent level of the `case` keywords.

Switch as an expression uses K&R braces; its case body expressions are put on the same line as their `case` statements, separated from the latter by 1 space.

6. Modifiers

Modifier order for methods is: `public/private static/override/abstract inline macro function`.

Modifier order for class variables/properties is: `public/private static inline var/final`.

`public`/`private` modifier is mandatory and shouldn't be omitted.

7. Don't make trivial anonymous functions

Instead of `onClick(e -> someMethod(e))` write `onClick(someMethod)`.

8. Spaces

By default, any binary operator should have a single space between itself and each of its operands, while any unary operator should not have a space between itself and its only operand.

If an anonymous structure declaration occupies a single line, don't add spaces between its curly braces and its content. Yet maintain a single space after each comma separating the fields of this structure and after each colon separating the name of the field from its value.

In a type annotation, there should be no space between the colon and the type. Likewise, for annotations denoting function type, there should be no spaces around `->` (unlike the actual anonymous function declaration, where spaces around the arrow operator are mandatory).

Do not use vertical alignment (extra spaces to align values into columns across adjacent lines). This applies to object literals, variable declarations, assignments, and any other multi-line constructs.

9. Comments

A comment that fits on one line uses `//`. A comment spanning more than one line uses `/* */` instead of several consecutive `//` lines: `/*` opens on its own line, `*/` closes on its own line, and the text in between is indented one level deeper than the delimiters (no leading `*` on each line). For example:

```
/*
    Explanation spanning
    multiple lines.
*/
```

A doc comment documents the API contract of the class/field/method it's attached to (what a caller needs to know to use it correctly) rather than the implementation rationale behind it (which stays a regular comment, see p. 9). Doc comments use `/**` to open and `**/` to close (note the double star on both ends, unlike a regular multi-line comment's `*/`), formatted the same way otherwise: each on its own line, with the text in between indented one level deeper and no leading `*` per line. For example:

```
/**
    What this method does and how a caller should use it.
**/
```
