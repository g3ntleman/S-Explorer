S-Explorer
=======

An Editor targeted at developing in Lisp-Like languages, initially Clojure.
Written in Obj-C/Cocoa for Mac OS X 10.8 and up.

Note: This is not in a usable state yet!

Please install leiningen for the build-in Clojure support (using homebrew):

> brew install leiningen

Implemented Features

* Editor for Source-File Editing, featuring...
  * Syntax-Highlighting (initial version done, no runtime support yet)
  * Parenthesis Highlighting 
  * Expression Selection by double-clicking Parenthesis
  * Auto-Indentation (press TAB)
  * "Evaluate" Menu Item to evaluate current selection or top-level expression at cursor


* nREPL with ...
  * Syntax-Highlighting
  * Parenthesis Highlighting
  * Persistent REPL History
  * Expression Selection by double-clicking Parenthesis


Planned Features

* Project Directory Display (started)
* Project management
* Infrastructure for more S-Expression-Based Languages with initial plans for (in addition to Clojure):
  * Chibi-Scheme, a lightweight Scheme implementation suitable for embedding / scripting
* Project templates for convenient project creation
* Support for running Tests and multiple REPLs per project
* Symbol indexing and completion (started)
* Documentation integration
* Debug-Features for REPL like "pause execution", "display stack trace", "display locals"

Immediate Todo:

* Someone needs to re-do the app icon and document icons
* Implement Multiple Source displays
* Make all operations undoable (e.g. switching REPLs)
* Add nicer rendering for OPTabView

License

Released under MIT license.

Copyright (c) 2013 Dirk Theisen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


