pragma Singleton

import QtQuick
import Quickshell

// Sums typed into Spotlight, worked out the way the calculator in the one on
// a mac does: type `12*7` and the answer is the top hit.
//
// A query is only ever read as a sum, never run. It is cut into numbers,
// operators, brackets and a handful of names, and those are put together by
// a small recursive descent parser, so nothing typed into the field can do
// anything but arithmetic. The usual precedence holds — a power binds
// tighter than a sign, which binds tighter than a product, which binds
// tighter than a sum — powers go from the right, so `2^3^2` is 512, and
// `-2^2` is -4 the way it is written on paper. A number written straight
// against a bracket or a name is multiplied by it: `2pi`, `3(1+1)`.
//
// Most of what is typed is not a sum, and a query is turned away as early
// as possible, so searching costs nothing for it: anything without an
// operator, a bracket or a number run into a word is not looked at
// further, and anything with a word that is not one of the names below
// stops the moment the word ends.
// A query that is a sum still has to do something to count as one — a
// bare `42` or `pi` is a number, not a sum, and is left to the search, which
// may well have an application called that.
Singleton {
    id: root

    // ── reading a query ───────────────────────────────────────────────────

    // The answer to `query` when it is a sum, and null when it is not one,
    // does not come out to a number, or comes out to one too large to write
    // down. Division by nothing is not an answer either.
    function evaluate(query: string): var {
        const text = (query ?? "").trim();
        if (!/[-+*\/%^()×÷−]|\d\s*[a-z]/i.test(text))
            return null;

        const tokens = root.lex(text);
        if (!tokens)
            return null;

        const parser = root.parser(tokens);
        const value = parser.sum();
        if (!parser.done() || parser.operations() === 0)
            return null;

        return isFinite(value) ? value : null;
    }

    // ...and an answer the way it is shown and copied: twelve significant
    // figures, which is what a pocket calculator holds, so `0.1+0.2` is
    // 0.3 rather than what the floating point under it makes of it.
    function format(value: real): string {
        const rounded = Number(value.toPrecision(12));
        return String(Object.is(rounded, -0) ? 0 : rounded);
    }

    // the names a sum may use, and what each one is
    readonly property var constants: ({
            pi: Math.PI,
            tau: 2 * Math.PI,
            e: Math.E
        })
    readonly property var functions: ["sqrt", "cbrt", "abs", "ln", "log", "exp", "sin", "cos", "tan", "asin", "acos", "atan", "floor", "ceil", "round"]

    function apply(name: string, x: real): real {
        switch (name) {
        case "sqrt":
            return Math.sqrt(x);
        case "cbrt":
            return Math.cbrt(x);
        case "abs":
            return Math.abs(x);
        case "ln":
            return Math.log(x);
        case "log":
            return Math.log10(x);
        case "exp":
            return Math.exp(x);
        case "sin":
            return Math.sin(x);
        case "cos":
            return Math.cos(x);
        case "tan":
            return Math.tan(x);
        case "asin":
            return Math.asin(x);
        case "acos":
            return Math.acos(x);
        case "atan":
            return Math.atan(x);
        case "floor":
            return Math.floor(x);
        case "ceil":
            return Math.ceil(x);
        case "round":
            return Math.round(x);
        default:
            return NaN;
        }
    }

    // ── cutting it up ─────────────────────────────────────────────────────

    // The query as a list of { kind, value }: a number, an operator, a
    // bracket, a constant or a function. Null as soon as something turns up
    // that is none of those, which for an ordinary search is the first word.
    // The typographer's signs are read as the plain ones, and `**` as a power.
    function lex(text: string): var {
        const tokens = [];
        let i = 0;
        while (i < text.length) {
            const rest = text.slice(i);

            const space = /^\s+/.exec(rest);
            if (space) {
                i += space[0].length;
                continue;
            }

            // ...with an exponent, the way an answer too large or too
            // small to write out is shown — `1e-8`, `1e+21` — so one pasted
            // back in is the number it was and not `e` with a sum round it
            const number = /^(\d+(\.\d*)?|\.\d+)(e[-+]?\d+)?/i.exec(rest);
            if (number) {
                tokens.push({
                    kind: "number",
                    value: Number(number[0])
                });
                i += number[0].length;
                continue;
            }

            const word = /^[a-z]+/i.exec(rest);
            if (word) {
                const name = word[0].toLowerCase();
                // its own names only: every object answers to `constructor`
                if (Object.prototype.hasOwnProperty.call(root.constants, name))
                    tokens.push({
                        kind: "constant",
                        value: root.constants[name]
                    });
                else if (root.functions.includes(name))
                    tokens.push({
                        kind: "function",
                        value: name
                    });
                else
                    return null;
                i += word[0].length;
                continue;
            }

            if (rest.startsWith("**")) {
                tokens.push({
                    kind: "operator",
                    value: "^"
                });
                i += 2;
                continue;
            }

            const sign = ({
                    "×": "*",
                    "÷": "/",
                    "−": "-"
                })[rest[0]] ?? rest[0];
            if ("+-*/%^".includes(sign))
                tokens.push({
                    kind: "operator",
                    value: sign
                });
            else if (sign === "(" || sign === ")")
                tokens.push({
                    kind: "bracket",
                    value: sign
                });
            else
                return null;
            i += 1;
        }
        return tokens;
    }

    // ── putting it together ───────────────────────────────────────────────
    //
    // One rule of the grammar per function, from the loosest binding to the
    // tightest:
    //
    //     sum      product (("+" | "-") product)*
    //     product  signed (("*" | "/" | "%") signed | power)*
    //     signed   ("+" | "-") signed | power
    //     power    atom ("^" signed)?
    //     atom     number | constant | function atom | "(" sum ")"
    //
    // The second branch of a product is something standing straight against
    // a bracket, a function or a constant; two numbers side by side are not
    // a product, so `2 3` is not 6. Anything malformed comes out as NaN,
    // which nothing turns back into a number, and `operations` counts what
    // was actually worked out, which is what tells a sum from a number.
    function parser(tokens: var): var {
        let at = 0;
        let worked = 0;

        const peek = () => tokens[at] ?? null;
        const is = (kind, value) => peek()?.kind === kind && (value === undefined || peek().value === value);
        const take = () => tokens[at++];

        function atom(): real {
            if (is("number") || is("constant"))
                return take().value;

            if (is("function")) {
                const name = take().value;
                // a function takes its argument in brackets, so `sin 2` is
                // not mistaken for something meant
                if (!is("bracket", "("))
                    return NaN;
                worked++;
                return root.apply(name, atom());
            }

            if (is("bracket", "(")) {
                take();
                const value = sum();
                if (!is("bracket", ")"))
                    return NaN;
                take();
                return value;
            }

            return NaN;
        }

        function power(): real {
            const base = atom();
            if (!is("operator", "^"))
                return base;
            take();
            worked++;
            return Math.pow(base, signed());
        }

        function signed(): real {
            if (is("operator", "-")) {
                take();
                return -signed();
            }
            if (is("operator", "+")) {
                take();
                return signed();
            }
            return power();
        }

        function product(): real {
            let value = signed();
            while (true) {
                if (is("operator", "*") || is("operator", "/") || is("operator", "%")) {
                    const op = take().value;
                    const right = signed();
                    worked++;
                    value = op === "*" ? value * right : op === "/" ? value / right : value % right;
                } else if (is("bracket", "(") || is("function") || is("constant")) {
                    worked++;
                    value *= power();
                } else {
                    return value;
                }
            }
        }

        function sum(): real {
            let value = product();
            while (is("operator", "+") || is("operator", "-")) {
                const op = take().value;
                const right = product();
                worked++;
                value = op === "+" ? value + right : value - right;
            }
            return value;
        }

        return {
            sum,
            done: () => at === tokens.length,
            operations: () => worked
        };
    }
}
