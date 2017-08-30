# Tcl 8.6.6 Enhanced Grammars

This is an enhanced grammar adding an extensive amount of command-specific
highlighting for Tcl.  This is far from completed and may exhibit odd
behavior at certain points but many of the core commands are handled
properly.

This is currently a work in progress and is missing some core handling
and commands.  We are currently adding and building to it as we encounter
issues with the highlighting while moving our projects to atom editor.

![image](http://i.imgur.com/3OhhAnb.png)

## Comment Syntax

This grammar supports annotating within "multi-line-comments".  Tcl does not officially have a multi-line comment, however using `if 0 {}` is generally a way to accomplish this.  

We personally use `% {}` so it is currently expecting either of those to be multi-line.
It will highlight links.  If you also want to be able to click to open them, then you can
install the excellent [Hyperclick](https://atom.io/packages/hyperclick) package along with
the [hyperlink-hyperclick](https://atom.io/packages/hyperlink-hyperclick) provider.

```tcl
proc % args {}

% {
  @ Annotated Title
    > Category / Header
      -arg/opt {string|entier}
        | Highlighted Text / Description
        | http://www.link.com
}
```

***and/or***

```tcl
if 0 {
  @ Annotated Title
    > Category / Header
      -arg/opt {string|entier}
        | Highlighted Text / Description
        | http://www.link.com
}
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
