;;; ../dotfiles/doom/prampo_config/dev/c.el -*- lexical-binding: t; -*-

(require 'treesit)
(require 'cl-lib)

(setf (alist-get 'c treesit-language-source-alist)
      '("https://github.com/tree-sitter/tree-sitter-c"
        "v0.23.4"))

(unless (treesit-language-available-p 'c)
  (treesit-install-language-grammar 'c))

(defun my/c-function-name (node)
  "Extract the identifier from a C declarator."
  (while (and node
              (not (equal (treesit-node-type node)
                          "identifier")))
    (setq node
          (treesit-node-child-by-field-name node "declarator")))
  (when node
    (treesit-node-text node t)))

(defun my/c-sync-header ()
  "Synchronize public C function prototypes with the header."
  (interactive)

  (unless (and buffer-file-name
               (string-suffix-p ".c" buffer-file-name))
    (user-error "Not a C source file"))

  (unless (treesit-language-available-p 'c)
    (user-error "C Tree-sitter grammar is missing"))

  (let* ((header (concat (file-name-sans-extension
                          buffer-file-name) ".h"))
         (parser (treesit-parser-create 'c))
         (root (treesit-parser-root-node parser))
         (functions nil))

    ;; Extract non-static function definitions.
    (dolist (node (treesit-query-capture
                   root
                   '((function_definition) @func)
                   nil nil t))
      (unless
          (cl-some
           (lambda (child)
             (and (equal (treesit-node-type child)
                         "storage_class_specifier")
                  (equal (treesit-node-text child t)
                         "static")))
           (treesit-node-children node))

        (let* ((decl (treesit-node-child-by-field-name
                      node "declarator"))
               (body (treesit-node-child-by-field-name
                      node "body"))
               (name (my/c-function-name decl))
               (signature
                (string-trim
                 (buffer-substring-no-properties
                  (treesit-node-start node)
                  (treesit-node-start body)))))

          (when name
            (push (cons name (concat signature ";"))
                  functions)))))

    ;; Open or create the header.
    (with-current-buffer (find-file-noselect header)

      (when (= (buffer-size) 0)
        (let ((guard
               (upcase
                (replace-regexp-in-string
                 "[^a-zA-Z0-9]" "_"
                 (file-name-nondirectory header)))))
          (insert "#ifndef " guard "\n"
                  "#define " guard "\n\n"
                  "#endif /* " guard " */\n")))

      ;; Update or append each prototype.
      (dolist (func (reverse functions))
        (let* ((name (car func))
               (signature (cdr func))
               (root (treesit-parser-root-node
                      (treesit-parser-create 'c)))
               (existing
                (cl-find-if
                 (lambda (node)
                   (equal
                    name
                    (my/c-function-name
                     (treesit-node-child-by-field-name
                      node "declarator"))))
                 (treesit-query-capture
                  root
                  '((declaration) @decl)
                  nil nil t))))

          (if existing
              ;; Replace existing declaration.
              (let ((start (treesit-node-start existing))
                    (end (treesit-node-end existing)))
                (goto-char start)
                (delete-region start end)
                (insert signature))

            ;; Insert before the final include guard.
            (goto-char (point-max))
            (when (re-search-backward
                   "^\\s-*#\\s-*endif\\b" nil t)
              (beginning-of-line))
            (unless (bolp)
              (insert "\n"))
            (insert signature "\n"))))

      (save-buffer))

    (message "Header synchronized: %s" header)))
