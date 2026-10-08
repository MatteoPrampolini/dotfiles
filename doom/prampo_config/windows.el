(defun my/open-in-windows-explorer ()
  "Open explorer.exe of current dired folder"
  (interactive)
  (let ((path (if (derived-mode-p 'dired-mode)
                  (dired-current-directory)
                default-directory)))
    (w32-shell-execute "open" (expand-file-name path))))

(after! dired
  (map! :map dired-mode-map
        :n "E" #'my/open-in-windows-explorer))
