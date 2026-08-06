;;; org-linksmith.el --- Format clipboard URLs as Org links -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Greg Lucas

;; Author: Greg Lucas <greg@glucas.net>
;; Keywords: convenience, org
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/glucas/org-linksmith
;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Turn clipboard URLs into legible Org links via a handler registry.
;;
;; Commands:
;;   `org-linksmith-insert-url'              — insert [[url][desc]] for a given URL
;;   `org-linksmith-insert-from-clipboard'    — insert [[url][desc]] at point
;;   `org-linksmith-store-from-clipboard'     — store as Org link (for %a in templates)
;;   `org-linksmith-capture-with-clipboard-link' — store + org-capture
;;
;; Register handlers with `org-linksmith-register-handler'.  Each handler
;; is a plist with :name, :match (url -> bool), and :format (url -> plist
;; with :url and :desc).  Handlers are checked in order; first match wins.
;;
;; This package ships with no handlers registered by default — load
;; `org-linksmith-handlers' for a set of handlers for common services
;; (GitHub, Jira, Confluence, ChatGPT), or register your own.  See the
;; README for a worked example of writing and registering a handler.
;;
;; When no handler matches, `org-linksmith-fallback-format-function' is used.

;;; Code:

(require 'cl-lib)
(require 'org)

;;; Customization

(defgroup org-linksmith nil
  "Format clipboard URLs as Org links."
  :group 'org-capture)

(defcustom org-linksmith-default-capture-template "xl"
  "Default org-capture template key used by `org-linksmith-capture-url'."
  :type 'string
  :group 'org-linksmith)

(defun org-linksmith-default-fallback (url)
  "Fallback :format function: a bare link, URL used as both link and desc."
  (list :url url :desc url))

(defcustom org-linksmith-fallback-format-function #'org-linksmith-default-fallback
  "Function used to format URL when no handler in `org-linksmith-handlers' matches.
Called with one argument, the URL string; must return a plist with :url
and :desc, the same shape a handler's :format function returns.

Set to nil to signal a `user-error' when no handler matches."
  :type '(choice (const :tag "Signal an error" nil)
                 function)
  :group 'org-linksmith)

;;; Handler Registry

(defvar org-linksmith-handlers '()
  "List of link handler plists.
Each handler must have:
  :name    String identifier used in messages
  :match   Function (url) -> non-nil if this handler applies
  :format  Function (url) -> plist with :url and :desc")

(defun org-linksmith-register-handler (handler)
  "Append HANDLER to `org-linksmith-handlers'.
Handlers are checked in order; first match wins.  Call this at
load time to register built-in or user-defined handlers."
  (add-to-list 'org-linksmith-handlers handler t))

;;; Core helpers

(defun org-linksmith--clipboard-string ()
  "Return trimmed clipboard text, or signal a user-error.
Reads via `current-kill', which merges the system clipboard into the
kill ring when `select-enable-clipboard' is non-nil (the default).  If
that option is nil, this falls back to the kill ring instead of the
system clipboard."
  (let ((text (ignore-errors (current-kill 0 t))))
    (unless (and text (not (string-empty-p (string-trim text))))
      (user-error "Clipboard is empty"))
    (string-trim text)))

(defun org-linksmith--find-handler (url)
  "Return the first handler in `org-linksmith-handlers' matching URL, or nil."
  (cl-find-if (lambda (h) (funcall (plist-get h :match) url))
              org-linksmith-handlers))

(defun org-linksmith--format (url)
  "Return a :url/:desc plist for URL using the handler registry.
Falls back to `org-linksmith-fallback-format-function' when no handler
matches; signals `user-error' if that is nil."
  (let ((handler (org-linksmith--find-handler url)))
    (cond
     (handler (funcall (plist-get handler :format) url))
     (org-linksmith-fallback-format-function
      (funcall org-linksmith-fallback-format-function url))
     (t (user-error "No linksmith handler matched: %s" url)))))

(defun org-linksmith--org-link (url desc)
  "Return an Org link string [[URL][DESC]]."
  (format "[[%s][%s]]" url desc))

;;; Commands

;;;###autoload
(defun org-linksmith-insert-url (url)
  "Insert a formatted Org link for URL at point."
  (interactive "sURL: ")
  (let* ((props (org-linksmith--format url))
         (desc  (plist-get props :desc)))
    (insert (org-linksmith--org-link (plist-get props :url) desc))))

;;;###autoload
(defun org-linksmith-insert-from-clipboard ()
  "Insert a formatted Org link for the clipboard URL at point."
  (interactive)
  (org-linksmith-insert-url (org-linksmith--clipboard-string)))

(defun org-linksmith-store (url)
  "Store URL as an Org link via the handler registry.
Sets `org-store-link-plist' so %a expands to the formatted link in the
next capture.  Signals `user-error' if no handler matches."
  (let* ((props      (org-linksmith--format url))
         (link       (plist-get props :url))
         (desc       (plist-get props :desc))
         (annotation (org-linksmith--org-link link desc)))
    (org-link-store-props :type "linksmith" :link link :description desc
                          :annotation annotation)
    (message "Stored: %s" annotation)))

;;;###autoload
(defun org-linksmith-store-from-clipboard ()
  "Store the clipboard URL as an Org link for use in capture templates (%a)."
  (interactive)
  (org-linksmith-store (org-linksmith--clipboard-string)))

(defun org-linksmith--capture-clipboard ()
  "Return a formatted Org link for the clipboard URL.
For use in capture templates via %(org-linksmith--capture-clipboard).
Returns an error placeholder string rather than signaling, so template
fill does not abort."
  (condition-case err
      (let* ((url   (org-linksmith--clipboard-string))
             (props (org-linksmith--format url)))
        (org-linksmith--org-link (plist-get props :url) (plist-get props :desc)))
    (user-error (format "[linksmith: %s]" (error-message-string err)))))

(defun org-linksmith-capture-url (url &optional template-key)
  "Store URL as a formatted Org link and invoke `org-capture'.
Uses TEMPLATE-KEY, or `org-linksmith-default-capture-template' if nil."
  (org-linksmith-store url)
  (let ((org-capture-link-is-already-stored t))
    (org-capture nil (or template-key org-linksmith-default-capture-template))))

;;;###autoload
(defun org-linksmith-format-url-at-point ()
  "Replace the raw URL at or just before point with a formatted Org link.
Signals `user-error' if no URL is found or no handler matches."
  (interactive)
  (let ((bounds (or (bounds-of-thing-at-point 'url)
                    (save-excursion
                      (skip-chars-backward " \t")
                      (bounds-of-thing-at-point 'url)))))
    (unless bounds
      (user-error "No URL at point"))
    (let* ((url   (buffer-substring-no-properties (car bounds) (cdr bounds)))
           (props (org-linksmith--format url))
           (link  (org-linksmith--org-link (plist-get props :url)
                                           (plist-get props :desc))))
      (delete-region (car bounds) (cdr bounds))
      (insert link))))

;;;###autoload
(defun org-linksmith-capture-with-clipboard-link (&optional arg)
  "Capture the clipboard URL as an inbox task.
With \\[universal-argument], prompt for a capture template key instead
of using `org-linksmith-default-capture-template'."
  (interactive "P")
  (org-linksmith-capture-url
   (org-linksmith--clipboard-string)
   (when arg (read-string "Capture template key: "))))

(provide 'org-linksmith)
;;; org-linksmith.el ends here
