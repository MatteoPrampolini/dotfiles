;;; ../dotfiles/doom/prampo_config/dev/c.el -*- lexical-binding: t; -*-

(require 'cc-mode)
(require 'subr-x)

(defun my/c-extract-prototypes ()
  "Extract non-static function prototypes from the current buffer."
  (save-excursion
    (goto-char (point-min))
    (let (prototypes)
      (while (re-search-forward
              "^\\([a-zA-Z_][a-zA-Z0-9_ \t*\n]*\\)([^;{}]*)[ \t\n]*{"
              nil t)
        (let* ((start (match-beginning 0))
               (end (1- (match-end 0)))
               (signature
                (string-trim
                 (buffer-substring-no-properties start end)))
               (state (save-excursion
                        (syntax-ppss start))))

          ;; Ignore comments, strings, nested blocks and static functions.
          (unless (or (nth 3 state)
                      (nth 4 state)
                      (> (car state) 0)
                      (string-match-p "\\_<static\\_>" signature))
            (push (concat signature ";") prototypes))

          ;; Always advance to avoid infinite loops.
          (goto-char (1+ end))))

      (nreverse prototypes))))


(defun my/c-sync-header ()
  "Regenerate public function prototypes in the corresponding header."
  (interactive)

  (unless (and buffer-file-name
               (string-suffix-p ".c" buffer-file-name))
    (user-error "Not a C source file"))

  (let* ((header (concat
                  (file-name-sans-extension buffer-file-name)
                  ".h"))
         (prototypes (my/c-extract-prototypes))
         (begin "// BEGIN GENERATED PROTOTYPES")
         (end "// END GENERATED PROTOTYPES")
         (guard (upcase
                 (replace-regexp-in-string
                  "[^a-zA-Z0-9]" "_"
                  (file-name-nondirectory header)))))

    (with-current-buffer (find-file-noselect header)

      ;; Initialize an empty header.
      (when (= (buffer-size) 0)
        (insert "#ifndef " guard "\n"
                "#define " guard "\n\n"
                "#endif /* " guard " */\n"))

      (atomic-change-group

        ;; Remove the previous generated section.
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^" (regexp-quote begin) "$") nil t)
          (beginning-of-line)
          (let ((start (point)))
            (unless (re-search-forward
                     (concat "^" (regexp-quote end) "$") nil t)
              (user-error "Missing end marker"))
            (forward-line 1)
            (delete-region start (point))))

        ;; Find insertion point before the final include guard.
        (goto-char (point-max))
        (skip-chars-backward " \t\r\n")
        (when (save-excursion
                (beginning-of-line)
                (looking-at-p "^\\s-*#\\s-*endif\\b"))
          (beginning-of-line))

        ;; Normalize surrounding whitespace.
        (skip-chars-backward " \t\r\n")
        (delete-region
         (point)
         (progn
           (skip-chars-forward " \t\r\n")
           (point)))

        ;; Insert generated prototypes.
        (insert "\n\n" begin "\n")
        (dolist (prototype prototypes)
          (insert prototype "\n"))
        (insert end "\n\n"))

      (save-buffer))

    (message "Header synchronized: %d prototypes"
             (length prototypes))))
