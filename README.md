jenv.el
=======
Emacs integration for jenv (http://www.jenv.be); based on rbenv.el

Use jenv to manage your Java versions within Emacs.

The mode is derived from senny/rbenv.el.

Installation
------------

```lisp
(add-to-list 'load-path (expand-file-name "/path/to/jenv.el/"))
(require 'jenv)
(global-jenv-mode)
```

Usage
-----

* `global-jenv-mode` activate / deactivate jenv.el (The current Java version is shown in the modeline)
* `jenv-use-global` will activate your global java
* `jenv-use` allows you to choose what java version you want to use
* `jenv-use-corresponding` searches for .java-version and activates
  the corresponding java

Configuration
-------------

**jenv installation directory**
By default jenv.el assumes that you installed jenv into
`~/.jenv`. If you use a different installation location you can
customize jenv.el to search in the right place:

```lisp
(setq jenv-installation-dir "/usr/local/jenv")
```
*IMPORTANT:*: Currently you need to set this variable before you load jenv.el

Or you can set the environment variable `JENV_ROOT` to the location.

**the modeline**
jenv.el will show you the active java in the modeline. If you don't
like this feature you can disable it:

```lisp
(setq jenv-show-active-java-in-modeline nil)
```

The default modeline representation is the java version (colored red) in square
brackets. You can change the format by customizing the variable:

```lisp
;; this will remove the colors
(setq jenv-modeline-function 'jenv--modeline-plain)
```

You can also define your own function to format the java version as you like.

Press
-----

Nothing about jenv.el yet!

But here are some articles about rbenv.el, which this derived from.

* [Use the right Ruby with emacs and rbenv](http://blog.senny.ch/blog/2013/02/11/use-the-right-ruby-with-emacs-and-rbenv/) by Yves Senn

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/f4c783738c250ce724df3c5b9753a786 "githalytics.com")](http://githalytics.com/senny/rbenv.el)
