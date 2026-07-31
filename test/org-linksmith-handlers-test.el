;;; org-linksmith-handlers-test.el --- ERT tests for org-linksmith built-in handlers -*- lexical-binding: t; -*-

(require 'ert)
(require 'org-linksmith-handlers)

;;; GitHub PR handler

(ert-deftest org-linksmith-github-pr-match/matches-pr-url ()
  (should (org-linksmith--github-pr-match
           "https://github.com/owner/repo/pull/42"))
  (should (org-linksmith--github-pr-match
           "https://github.com/owner/repo/pull/42/files")))

(ert-deftest org-linksmith-github-pr-match/rejects-non-pr ()
  (should-not (org-linksmith--github-pr-match "https://github.com/owner/repo"))
  (should-not (org-linksmith--github-pr-match "https://github.com/owner/repo/issues/7")))

(ert-deftest org-linksmith-github-pr-format/desc ()
  (let* ((url "https://github.com/owner/repo/pull/42")
         (props (org-linksmith--github-pr-format url)))
    (should (equal (plist-get props :url) url))
    (should (equal (plist-get props :desc) "PR: owner/repo#42"))))

;;; GitHub repo handler

(ert-deftest org-linksmith-github-repo-match/matches-repo-url ()
  (should (org-linksmith--github-repo-match "https://github.com/owner/repo"))
  (should (org-linksmith--github-repo-match "https://github.com/owner/repo/tree/main")))

(ert-deftest org-linksmith-github-repo-match/rejects-non-github ()
  (should-not (org-linksmith--github-repo-match "https://gitlab.com/owner/repo")))

(ert-deftest org-linksmith-github-repo-format/desc ()
  (let* ((url "https://github.com/owner/repo")
         (props (org-linksmith--github-repo-format url)))
    (should (equal (plist-get props :url) url))
    (should (equal (plist-get props :desc) "GitHub: owner/repo"))))

(ert-deftest org-linksmith-github-pr-wins-over-repo ()
  "PR handler should match before the repo handler for PR URLs."
  (let* ((url "https://github.com/owner/repo/pull/42")
         (handler (org-linksmith--find-handler url)))
    (should (equal (plist-get handler :name) "PR"))))

;;; Confluence handler

(ert-deftest org-linksmith-confluence-match/matches-confluence-url ()
  (should (org-linksmith--confluence-match
           "https://example.atlassian.net/wiki/spaces/ENG/pages/546308102/Release+Management"))
  (should (org-linksmith--confluence-match
           "https://example.atlassian.net/wiki/x/ziY_/")))

(ert-deftest org-linksmith-confluence-match/rejects-jira-url ()
  (should-not (org-linksmith--confluence-match
               "https://example.atlassian.net/browse/PROJ-123")))

(ert-deftest org-linksmith-confluence-format/space-and-title ()
  (let* ((url "https://example.atlassian.net/wiki/spaces/DM/pages/1004863523/Team+Onboarding+Guide")
         (props (org-linksmith--confluence-format url)))
    (should (equal (plist-get props :url) url))
    (should (equal (plist-get props :desc)
                   "Confluence: DM: Team Onboarding Guide"))))

(ert-deftest org-linksmith-confluence-format/space-only ()
  (let* ((url "https://example.atlassian.net/wiki/spaces/ENG/pages/546308102")
         (props (org-linksmith--confluence-format url)))
    (should (equal (plist-get props :desc) "Confluence: ENG"))))

(ert-deftest org-linksmith-confluence-format/short-link ()
  (let* ((url "https://example.atlassian.net/wiki/x/ziY_/")
         (props (org-linksmith--confluence-format url)))
    (should (equal (plist-get props :desc) "Confluence"))))

(ert-deftest org-linksmith-confluence-format/title-with-percent-encoding ()
  (let* ((url "https://example.atlassian.net/wiki/spaces/PT/pages/322502749/Versioning+Tagging+and+Releasing")
         (props (org-linksmith--confluence-format url)))
    (should (equal (plist-get props :desc)
                   "Confluence: PT: Versioning Tagging and Releasing"))))

;;; Jira issue handler

(ert-deftest org-linksmith-jira-issue-match/matches-issue-url ()
  (should (org-linksmith--jira-issue-match
           "https://example.atlassian.net/browse/FUN-1002"))
  (should (org-linksmith--jira-issue-match
           "https://example.atlassian.net/browse/PFE-11453")))

(ert-deftest org-linksmith-jira-issue-match/rejects-board-url ()
  (should-not (org-linksmith--jira-issue-match
               "https://example.atlassian.net/jira/software/c/projects/PFE/boards/296")))

(ert-deftest org-linksmith-jira-issue-format/desc ()
  (let* ((url "https://example.atlassian.net/browse/FUN-1002")
         (props (org-linksmith--jira-issue-format url)))
    (should (equal (plist-get props :url) url))
    (should (equal (plist-get props :desc) "Jira: FUN-1002"))))

;;; ChatGPT handler

(ert-deftest org-linksmith-chatgpt-match/matches-chatgpt-url ()
  (should (org-linksmith--chatgpt-match
           "https://chatgpt.com/c/00000000-0000-0000-0000-000000000000"))
  (should (org-linksmith--chatgpt-match
           "https://chatgpt.com/g/g-p-11111111111111111111111111111111/c/00000000-0000-0000-0000-000000000000")))

(ert-deftest org-linksmith-chatgpt-match/rejects-other-url ()
  (should-not (org-linksmith--chatgpt-match "https://teams.microsoft.com/foo")))

(ert-deftest org-linksmith-chatgpt-format/desc ()
  (let* ((url "https://chatgpt.com/c/00000000-0000-0000-0000-000000000000")
         (props (org-linksmith--chatgpt-format url)))
    (should (equal (plist-get props :url) url))
    (should (equal (plist-get props :desc) "ChatGPT"))))

(provide 'org-linksmith-handlers-test)
;;; org-linksmith-handlers-test.el ends here
