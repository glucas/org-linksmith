# org-linksmith

Turn a clipboard URL into a legible Org link — `[[https://github.com/foo/bar/pull/42][PR: foo/bar#42]]`
instead of the raw URL — via a small handler registry.

## Commands

- `org-linksmith-insert-from-clipboard` — insert a formatted link at point
- `org-linksmith-format-url-at-point` — reformat the raw URL at/before point in place
- `org-linksmith-store-from-clipboard` — store as an Org link, for `%a` in capture templates
- `org-linksmith-capture-with-clipboard-link` — store + `org-capture`

"Clipboard" here means whatever `current-kill` returns, which merges
the system clipboard into the kill ring when `select-enable-clipboard`
is non-nil (the Emacs default). With that option nil, these commands
read from the kill ring instead.

## Handlers

`org-linksmith.el` ships with no handlers registered — it's just the
registry and the commands above. Load `org-linksmith-handlers` for a
starter set (GitHub PR, GitHub repo, Jira issue, Confluence, ChatGPT):

``` emacs-lisp
(require 'org-linksmith)
(require 'org-linksmith-handlers)
```

## Writing your own handler

A handler is a plist with three parts:

- `:name` — string, used in messages
- `:match` — `(url) -> non-nil` if this handler applies
- `:format` — `(url) -> plist` with `:url` and `:desc`

Handlers are tried in registration order; the first match wins. Here's
the simplest possible handler, for a service that only needs a static
description:

``` emacs-lisp
(org-linksmith-register-handler
 (list :name   "Example"
       :match  (lambda (url) (string-match-p "^https://example\\.com/" url))
       :format (lambda (url) (list :url url :desc "Example"))))
```

And one that pulls an identifier out of the URL, following the shape
of the built-in Jira issue handler:

``` emacs-lisp
(defun my-example-match (url)
  (string-match-p "^https://example\\.com/issues/[0-9]+" url))

(defun my-example-format (url)
  (string-match "^https://example\\.com/issues/\\([0-9]+\\)" url)
  (list :url url :desc (format "Example issue #%s" (match-string 1 url))))

(org-linksmith-register-handler
 (list :name   "Example issue"
       :match  #'my-example-match
       :format #'my-example-format))
```

For a handler that needs a user-configurable lookup table (e.g.
mapping an account or workspace ID in the URL to a friendly name),
define a `defcustom` alist and consult it from `:format`. This one
also pulls a report name from the query string and a section anchor
from the fragment, using `url-parse` / `url-util`:

``` emacs-lisp
(defcustom my-example-workspace-names '()
  "Alist mapping Example workspace IDs to display names.
Example: ((\"ws-42\" . \"prod\") (\"ws-99\" . \"staging\"))"
  :type '(alist :key-type string :value-type string))

(defun my-example-dashboard-match (url)
  (string-match-p "^https://example\\.com/dashboards/" url))

(defun my-example-dashboard-format (url)
  (let* ((parsed    (url-generic-parse-url url))
         (path      (car (split-string (url-filename parsed) "?" t)))
         (query-str (cadr (split-string (url-filename parsed) "?" t)))
         (query     (when query-str (url-parse-query-string query-str)))
         (ws-id     (nth 1 (split-string path "/" t)))
         (ws-name   (or (cdr (assoc ws-id my-example-workspace-names)) ws-id))
         (report    (cadr (assoc "report" query)))
         (anchor    (url-target parsed)))
    (list :url url
          :desc (concat "Example: " ws-name
                        (when report (concat ": " report))
                        (when anchor (concat " @ " anchor))))))

(org-linksmith-register-handler
 (list :name   "Example dashboard"
       :match  #'my-example-dashboard-match
       :format #'my-example-dashboard-format))
```

See the built-in Confluence handler in `org-linksmith-handlers.el` for
another example of extracting path segments with `url-parse`.

Register your own handlers in your init file, after requiring
`org-linksmith-handlers` if you want the built-ins too:

``` emacs-lisp
(require 'org-linksmith)
(require 'org-linksmith-handlers)
;; then your own org-linksmith-register-handler calls
```
