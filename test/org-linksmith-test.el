;;; org-linksmith-test.el --- ERT tests for org-linksmith core -*- lexical-binding: t; -*-

(require 'ert)
(require 'org-linksmith)

;;; Registry: find-handler

(ert-deftest org-linksmith-find-handler/first-match-wins ()
  (let ((org-linksmith-handlers
         (list (list :name "A" :match (lambda (_) t)
                     :format (lambda (url) (list :url url :desc "A")))
               (list :name "B" :match (lambda (_) t)
                     :format (lambda (url) (list :url url :desc "B"))))))
    (let ((handler (org-linksmith--find-handler "https://example.com")))
      (should (equal (plist-get handler :name) "A")))))

(ert-deftest org-linksmith-find-handler/no-match-returns-nil ()
  (let ((org-linksmith-handlers
         (list (list :name "A" :match (lambda (_) nil)
                     :format (lambda (url) (list :url url :desc "A"))))))
    (should (null (org-linksmith--find-handler "https://example.com")))))

;;; Registry: format

(ert-deftest org-linksmith-format/uses-matching-handler ()
  (let ((org-linksmith-handlers
         (list (list :name "Test"
                     :match (lambda (url) (string-prefix-p "https://example.com" url))
                     :format (lambda (url) (list :url url :desc "Example"))))))
    (let ((props (org-linksmith--format "https://example.com/foo")))
      (should (equal (plist-get props :desc) "Example")))))

(ert-deftest org-linksmith-format/errors-on-no-match ()
  (let ((org-linksmith-handlers
         (list (list :name "A" :match (lambda (_) nil)
                     :format (lambda (url) (list :url url :desc "A"))))))
    (should-error (org-linksmith--format "https://example.com")
                  :type 'user-error)))

;;; format-url-at-point command

(ert-deftest org-linksmith-format-url-at-point/replaces-url-at-point ()
  (let ((org-linksmith-handlers
         (list (list :name "Test" :match (lambda (_) t)
                     :format (lambda (url) (list :url url :desc "Example"))))))
    (with-temp-buffer
      (insert "https://example.com/foo")
      (goto-char (point-min))
      (forward-char 10)                 ; point in middle of URL
      (org-linksmith-format-url-at-point)
      (should (equal (buffer-string)
                     "[[https://example.com/foo][Example]]")))))

(ert-deftest org-linksmith-format-url-at-point/replaces-url-before-point ()
  "Point at end of URL — typical post-yank position."
  (let ((org-linksmith-handlers
         (list (list :name "Test" :match (lambda (_) t)
                     :format (lambda (url) (list :url url :desc "Example"))))))
    (with-temp-buffer
      (insert "https://example.com/foo")
      (goto-char (point-max))
      (org-linksmith-format-url-at-point)
      (should (equal (buffer-string)
                     "[[https://example.com/foo][Example]]")))))

(ert-deftest org-linksmith-format-url-at-point/errors-with-no-url ()
  (with-temp-buffer
    (insert "not a url")
    (goto-char (point-min))
    (should-error (org-linksmith-format-url-at-point)
                  :type 'user-error)))

;;; org-link helper

(ert-deftest org-linksmith-org-link/format ()
  (should (equal (org-linksmith--org-link "https://example.com" "Example")
                 "[[https://example.com][Example]]")))

(provide 'org-linksmith-test)
;;; org-linksmith-test.el ends here
