;;; jenv.el --- Emacs integration for jenv

;; Copyright (C) 2013 Yves Senn

;; URL: https://github.com/senny/jenv.el
;; Author: Bryan Shell <bryan.shell@gmail.com>
;; Author: Yves Senn <yves.senn@gmail.com>
;; Version: 0.0.1
;; Created: 14 March 2016
;; Keywords: java jenv

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; M-x global-jenv-mode toggle the configuration done by jenv.el

;; M-x jenv-use-global prepares the current Emacs session to use
;; the global java configured with jenv.

;; M-x jenv-use allows you to switch the current session to the java
;; implementation of your choice.

;;; Compiler support:

;; helper function used in variable definitions
(defcustom jenv-installation-dir (or (getenv "JENV_ROOT")
                                      (concat (getenv "HOME") "/.jenv/"))
  "The path to the directory where jenv was installed."
  :group 'jenv
  :type 'directory)

(defun jenv--expand-path (&rest segments)
  (let ((path (mapconcat 'identity segments "/"))
        (installation-dir (replace-regexp-in-string "/$" "" jenv-installation-dir)))
    (expand-file-name (concat installation-dir "/" path))))

(defcustom jenv-interactive-completion-function
  (if ido-mode 'ido-completing-read 'completing-read)
  "The function which is used by jenv.el to interactivly complete user input"
  :group 'jenv
  :type 'function)

(defcustom jenv-show-active-java-in-modeline t
  "Toggles wether jenv-mode shows the active java in the modeline."
  :group 'jenv
  :type 'boolean)

(defcustom jenv-modeline-function 'jenv--modeline-with-face
  "Function to specify the jenv representation in the modeline."
  :group 'jenv
  :type 'function)

(defvar jenv-executable (jenv--expand-path "bin" "jenv")
  "path to the jenv executable")
  
(defvar jenv-java-shim (jenv--expand-path "shims" "java")
  "path to the java shim executable")

(defvar jenv-global-version-file (jenv--expand-path "version")
  "path to the global version configuration file of jenv")

(defvar jenv-version-environment-variable "JENV_VERSION"
  "name of the environment variable to configure the jenv version")

(defvar jenv-binary-paths (list (cons 'shims-path (jenv--expand-path "shims"))
                                 (cons 'bin-path (jenv--expand-path "bin")))
  "these are added to PATH and exec-path when jenv is setup")

(defface jenv-active-java-face
  '((t (:weight bold :foreground "Red")))
  "The face used to highlight the current java on the modeline.")

(defvar jenv--initialized nil
  "indicates if the current Emacs session has been configured to use jenv")

(defvar jenv--modestring nil
  "text jenv-mode will display in the modeline.")
(put 'jenv--modestring 'risky-local-variable t)

;;;###autoload
(defun jenv-use-global ()
  "activate jenv global java"
  (interactive)
  (jenv-use (jenv--global-java-version)))

;;;###autoload
(defun jenv-use-corresponding ()
  "search for .java-version and activate the corresponding java"
  (interactive)
  (let ((version-file-path (or (jenv--locate-file ".java-version")
                               (jenv--locate-file ".jenv-version"))))
    (if version-file-path (jenv-use (jenv--read-version-from-file version-file-path))
      (message "[jenv] could not locate .java-version or .jenv-version"))))

;;;###autoload
(defun jenv-use (java-version)
  "choose what java you want to activate"
  (interactive
   (let ((picked-java (jenv--completing-read "Java version: " (jenv/list))))
     (list picked-java)))
  (jenv--activate java-version)
  (message (concat "[jenv] using " java-version)))

(defun jenv/list ()
  (append '("system")
          (split-string (jenv--call-process "versions" "--bare") "\n")))

(defun jenv--setup ()
  (when (not jenv--initialized)
    (dolist (path-config jenv-binary-paths)
      (let ((bin-path (cdr path-config)))
        (setenv "PATH" (concat bin-path ":" (getenv "PATH")))
        (add-to-list 'exec-path bin-path)))
    (setq eshell-path-env (getenv "PATH"))
    (setq jenv--initialized t)
    (jenv--update-mode-line)))

(defun jenv--teardown ()
  (when jenv--initialized
    (dolist (path-config jenv-binary-paths)
      (let ((bin-path (cdr path-config)))
        (setenv "PATH" (replace-regexp-in-string (regexp-quote (concat bin-path ":")) "" (getenv "PATH")))
        (setq exec-path (remove bin-path exec-path))))
    (setq eshell-path-env (getenv "PATH"))
    (setq jenv--initialized nil)))

(defun jenv--activate (java-version)
  (setenv jenv-version-environment-variable java-version)
  (jenv--update-mode-line))

(defun jenv--completing-read (prompt options)
  (funcall jenv-interactive-completion-function prompt options))

(defun jenv--global-java-version ()
  (if (file-exists-p jenv-global-version-file)
      (jenv--read-version-from-file jenv-global-version-file)
    "system"))

(defun jenv--read-version-from-file (path)
  (with-temp-buffer
    (insert-file-contents path)
    (jenv--replace-trailing-whitespace (buffer-substring-no-properties (point-min) (point-max)))))

(defun jenv--locate-file (file-name)
  "searches the directory tree for an given file. Returns nil if the file was not found."
  (let ((directory (locate-dominating-file default-directory file-name)))
    (when directory (concat directory file-name))))

(defun jenv--call-process (&rest args)
  (with-temp-buffer
    (let* ((success (apply 'call-process jenv-executable nil t nil
                           (delete nil args)))
           (raw-output (buffer-substring-no-properties
                        (point-min) (point-max)))
           (output (jenv--replace-trailing-whitespace raw-output)))
      (if (= 0 success)
          output
        (message output)))))

(defun jenv--replace-trailing-whitespace (text)
  (replace-regexp-in-string "[[:space:]\n]+\\'" "" text))

(defun jenv--update-mode-line ()
  (setq jenv--modestring (funcall jenv-modeline-function
                                   (jenv--active-java-version))))

(defun jenv--modeline-with-face (current-java)
  (append '(" [")
          (list (propertize current-java 'face 'jenv-active-java-face))
          '("]")))

(defun jenv--modeline-plain (current-java)
  (list " [" current-java "]"))

(defun jenv--active-java-version ()
  (or (getenv jenv-version-environment-variable) (jenv--global-java-version)))

;;;###autoload
(define-minor-mode global-jenv-mode
  "use jenv to configure the java version used by your Emacs."
  :global t
  (if global-jenv-mode
      (progn
        (when jenv-show-active-java-in-modeline
          (unless (memq 'jenv--modestring global-mode-string)
            (setq global-mode-string (append (or global-mode-string '(""))
                                             '(jenv--modestring)))))
        (jenv--setup))
    (setq global-mode-string (delq 'jenv--modestring global-mode-string))
    (jenv--teardown)))

(provide 'jenv)

;;; jenv.el ends here
