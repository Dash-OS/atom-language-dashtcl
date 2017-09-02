# Tcl 8.6.6 Enhanced Grammars

This is an enhanced grammar adding an extensive amount of command-specific
highlighting for Tcl.  This is far from completed and may exhibit odd
behavior at certain points but many of the core commands are handled
properly.

This is currently a work in progress and is missing some core handling
and commands.  We are currently adding and building to it as we encounter
issues with the highlighting while moving our projects to atom editor.

> Pull requests are more than welcome.  At the moment there are various scopes that
> need refinements as we perfect the expression handling, etc.  

![image](https://i.imgur.com/lfPbjjP.png)

## Comment Syntax

![image](https://i.imgur.com/mPixeGi.png)

This grammar supports annotating within "multi-line-comments".  Tcl does not officially have a multi-line comment, however using `if 0 {}` is generally a way to accomplish this.  

We personally use `% {}` so it is currently expecting either of those to be multi-line.
It will highlight links.  If you also want to be able to click to open them, then you can
install the excellent [Hyperclick](https://atom.io/packages/hyperclick) package along with
the [hyperlink-hyperclick](https://atom.io/packages/hyperlink-hyperclick) provider after which
you can open links with a ctrl/cmd + click.

##### $ variables

Variable within annotations are highlighted differently than normal variables
within your code using the "non-substituting-variable" patterns.

```tcl
% { $::my::variable }
$::my::variable
```

##### { curly bracket blocks }

When a line starts with an opening curly bracket, it will be given
standard syntax highlighting.  This can be useful when providing
examples of calling a proc, etc.  These can span multiple lines.

```tcl
% {
  @ ::my::proc @
  @example
    { puts "hello, world" }
}
```

##### prop types

When we want to provide a "type" that a value will be, we can brace it in curly braces.
As long as it is not the first item on a line, it will give it prop type highlighting.

Currently you may add a "?" or "\*" value to indicate a value is required or optional.

###### prop type properties

If we want to provide a type with arguments (such as giving the type of values within a list)
we can add < or > brackets after a types name and add the property within it.`

###### prop types regexp

If we want to use a regular expression syntax w/ regexp highlighting, we can do so by using the
by bracing the type within forward slashes (example: /[0-4]\*/)

```tcl
% {
  @ ::my::proc
    @arg foo {*list<string|entier>|dict<key, value>*}
    @arg bar {?list</[0-7]/>?}
    @arg baz {?string|entier?}
}
```

##### @ properties

@ properties allow you to dictate values such as properties in a dict, the return
value, and more.  You can then include descriptions, types, and whatever else
as desired.

When a "@" is placed and a space is given immediately after, the line will
become a title line which can be terminated with another @ on the same line or
a line break.

Property keys allow defining a value after them and standard highlighting
such as `{$type}` apply as normal.

| Kind | Keys |
|-----|-----|
| Title | @ Comment Title @ |
| Categories | @type |
| Property | @key, @prop, @arg, @args, @returns, @example, @if |
| Misc | @$any |

```tcl
proc % args {}

% {
  @type MyType {string|entier}
    | Either a string or entier value is accepted.

  @ Annotated Title {MyType}
    > Category / Header
    | Highlighted Overview [puts hi] http://www.link.com
    @prop myProp {string|entier}
      A Standard prop description here.
    @custom property > Woo!

  @example
    { puts "What a cool example!" }
}
```

***and/or***

```tcl
if 0 { @ Cool Title @ }
```

## Extra Command Handling

In addition to the core Tcl commands, the grammar is also being built to
cover many of our ["Tcl Modules"](https://github.com/Dash-OS/tcl-modules) utilities.  

#### Tcl State Manager

![image](http://i.imgur.com/meqfNqw.png)

## Regular Expression Handling

Handles regular expression highlighting when using curly-brackets to enclose
the expressions.  This will only work when used directly with the regexp /
regsub commands as it is otherwise impossible to know that the values are
regular expression.

![image](http://i.imgur.com/lFF8zNX.png)
