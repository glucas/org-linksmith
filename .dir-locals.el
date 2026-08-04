;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((emacs-lisp-mode . ((find-sibling-rules
                       . (("/test/\\([^/]+\\)-tests\\.el\\'" "\\1.el")
                          ("/\\([^/]+\\)\\.el\\'" "test/\\1-tests.el"))))))
