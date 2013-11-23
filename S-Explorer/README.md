S-Explorer
=======

An Editor targeted at developing in Lisp-Like languages, initially Scheme.
Written in Obj-C/Cocoa for Mac OS X 10.8 and up.

Note: This is not in a usable state yet!

Please install chibi-scheme for the build-in scheme support (using homebrew):

> brew install chibi-scheme

Please install leiningen for the build-in Clojure support (using homebrew):

> brew install leiningen

Implemented Features

* Editor for scm-File Editing, featuring...
  * Syntax-Highlighting (initial version done, no runtime support yet)
  * Parenthesis Highlighting 
  * Expression Selection by double-clicking Parenthesis (done)
  * Auto-Indentation (press TAB)
  * "Evaluate" Menu Item to evaluate current selection or top-level expression at cursor


* Generic REPL with ...
  * Syntax-Highlighting
  * Persistent REPL History


Planned Features

* Project Directory Display (started)
* Infrastructure for multiple S-Expression-Based Languages with initial plans for
  * Chibi-Scheme, a lightweight Scheme implementation suitable for embedding / scripting
  * Clojure
* Project templates for convenient project creation
* Support for running Tests and multiple REPLs per project


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


