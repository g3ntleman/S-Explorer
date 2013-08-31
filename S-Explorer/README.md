S-Explorer
=======

An Editor targeted at developing in Lisp-Like languages, initially Scheme.
Written in Obj-C/Cocoa for Mac OS X 10.8 and up.

Please install chibi-scheme for the build-in scheme support.

> brew install chibi-scheme

Implemented Features

* scm File Editing Featuring...
  * Syntax-Highlighting (initial version done, no runtime support yet)
  * Parenthesis Highlighting 
  * Expression Selection by double-clicking Parenthesis (done)
  * Auto-Indentation (press TAB)


* Generic REPL with ...
  * Syntax-Highlighting
  * Persistent REPL History


Planned Features

* Project Directory Display (started)
* REPL with ...
  * Parenthesis Highlighting
  * Expression Selection by double-clicking Parenthesis
* Support for multiple S-Expression-Based Languages
* One Scheme implementation "build-in" for the quick-start
* Project Templates
* Support for running Tests / multiple REPLs


Immediate Todo:

* Implement "Evaluate" Menu Item to evaluate current selection or top-level expression at cursor.
* Implement NSDocument architecture

