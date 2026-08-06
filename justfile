# org-linksmith recipes

# Run all ERT tests
test:
    emacs --batch -Q \
      -L . \
      -L test \
      --eval "(mapc #'load-file (file-expand-wildcards \"test/*-tests.el\"))" \
      --eval "(ert-run-tests-batch-and-exit)"

# Run a single test file — e.g. just test-file test/org-linksmith-tests.el
test-file FILE:
    emacs --batch -Q \
      -L . \
      -L test \
      --load "{{FILE}}" \
      --eval "(ert-run-tests-batch-and-exit)"
