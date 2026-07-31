;;; org-linksmith-handlers.el --- Built-in handlers for org-linksmith -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Greg Lucas

;; Author: Greg Lucas <greg@glucas.net>
;; Keywords: convenience, org
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/glucas/org-linksmith

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

;; A set of handlers for common services, registered with
;; org-linksmith's handler registry.  Require this file (or load it)
;; to register all of them.
;;
;; These also serve as worked examples for writing your own handlers:
;; see the README for the pattern to follow when adding one, e.g. for
;; an internal tool or service not covered here.

;;; Code:

(require 'org-linksmith)
(require 'url-parse)
(require 'url-util)

;;; Built-in: GitHub PR handler

(defun org-linksmith--github-pr-match (url)
  "Return non-nil if URL is a GitHub pull request URL."
  (string-match-p "^https://github\\.com/[^/]+/[^/]+/pull/[0-9]+" url))

(defun org-linksmith--github-pr-format (url)
  "Return a :url/:desc plist for a GitHub PR URL."
  (string-match "^https://github\\.com/\\([^/]+/[^/]+\\)/pull/\\([0-9]+\\)" url)
  (let ((repo (match-string 1 url))
        (num  (match-string 2 url)))
    (list :url url :desc (format "PR: %s#%s" repo num))))

(org-linksmith-register-handler
 (list :name   "PR"
       :match  #'org-linksmith--github-pr-match
       :format #'org-linksmith--github-pr-format))

;;; Built-in: GitHub repo handler

(defun org-linksmith--github-repo-match (url)
  "Return non-nil if URL is a GitHub repository URL."
  (string-match-p "^https://github\\.com/[^/]+/[^/]+" url))

(defun org-linksmith--github-repo-format (url)
  "Return a :url/:desc plist for a GitHub repo URL."
  (string-match "^https://github\\.com/\\([^/]+/[^/]+\\)" url)
  (list :url url :desc (format "GitHub: %s" (match-string 1 url))))

(org-linksmith-register-handler
 (list :name   "GitHub"
       :match  #'org-linksmith--github-repo-match
       :format #'org-linksmith--github-repo-format))

;;; Built-in: Confluence handler

(defun org-linksmith--confluence-match (url)
  "Return non-nil if URL is a Confluence page URL (full or short link)."
  (string-match-p "atlassian\\.net/wiki/" url))

(defun org-linksmith--confluence-format (url)
  "Return a :url/:desc plist for a Confluence URL.
Extracts space key and page title from the URL path.
Short links (/wiki/x/HASH) return a generic \"Confluence\" description."
  (let* ((parsed    (url-generic-parse-url url))
         (path      (car (split-string (url-filename parsed) "?" t)))
         ;; path segments: ("wiki" "spaces" SPACE "pages" ID TITLE)
         (parts     (split-string path "/" t)))
    (if (equal (nth 1 parts) "x")
        ;; Short link — no space or title available
        (list :url url :desc "Confluence")
      (let* ((space     (nth 2 parts))
             (title-raw (nth 5 parts))
             (title     (when title-raw
                          (replace-regexp-in-string
                           "+" " " (url-unhex-string title-raw))))
             (desc      (cond
                         ((and space title) (format "Confluence: %s: %s" space title))
                         (space             (format "Confluence: %s" space))
                         (t                 "Confluence"))))
        (list :url url :desc desc)))))

(org-linksmith-register-handler
 (list :name   "Confluence"
       :match  #'org-linksmith--confluence-match
       :format #'org-linksmith--confluence-format))

;;; Built-in: Jira issue handler

(defun org-linksmith--jira-issue-match (url)
  "Return non-nil if URL is a Jira issue URL."
  (string-match-p "atlassian\\.net/browse/[A-Z]+-[0-9]+" url))

(defun org-linksmith--jira-issue-format (url)
  "Return a :url/:desc plist for a Jira issue URL."
  (string-match "atlassian\\.net/browse/\\([A-Z]+-[0-9]+\\)" url)
  (list :url url :desc (format "Jira: %s" (match-string 1 url))))

(org-linksmith-register-handler
 (list :name   "Jira issue"
       :match  #'org-linksmith--jira-issue-match
       :format #'org-linksmith--jira-issue-format))

;;; Built-in: ChatGPT handler

(defun org-linksmith--chatgpt-match (url)
  "Return non-nil if URL is a ChatGPT conversation URL."
  (string-match-p "^https://chatgpt\\.com/" url))

(defun org-linksmith--chatgpt-format (url)
  "Return a :url/:desc plist for a ChatGPT URL."
  (list :url url :desc "ChatGPT"))

(org-linksmith-register-handler
 (list :name   "ChatGPT"
       :match  #'org-linksmith--chatgpt-match
       :format #'org-linksmith--chatgpt-format))

(provide 'org-linksmith-handlers)
;;; org-linksmith-handlers.el ends here
