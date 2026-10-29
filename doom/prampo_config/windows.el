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

;; AutoHotkey sends F13 for a solo Caps tap in native Windows Emacs.
;; Queue the actual Escape event so Evil/Doom keep their normal state-specific
;; behavior (Insert -> Normal, cancel Visual, dismiss searches, etc.).
(defun my/caps-escape ()
  "Treat a solo Caps tap as Escape when Evil is active in this buffer."
  (interactive)
  (when (bound-and-true-p evil-local-mode)
    (setq unread-command-events (cons 'escape unread-command-events))))

(map! "<f13>" #'my/caps-escape)
