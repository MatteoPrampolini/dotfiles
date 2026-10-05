(setq doom-theme 'doom-one)

;;; Org
(load! "prampo_config/org")

(setq display-line-numbers-type t)

; remove C-h bindings to give space for 'embark-prefix-help-command'
; I found this on reddit, not sure if that's the best practise.
; <command> Shows a list of option. pressing C-h again let's you search.
(map!
 :map doom-leader-map
 "w C-h" nil
 :map evil-motion-state-map
 "C-w C-h" nil
 :map evil-window-map
 "C-h" nil
 :map general-override-mode-map
 :nvm "SPC w C-h" nil
 :map magit-mode-map
 :nv "C-w C-h" nil
)
;EVERYTHING AFTER THIS LINE IS TRASH!!!!
;;(add-to-list 'exec-path "C:/ProgramData/mingw64/mingw64/bin")
;;(setenv "PATH" (concat "C:\\ProgramData\\mingw64\\mingw64\\bin;" (getenv "PATH")))

(let ((ucrt-bin "C:/tools/msys64/ucrt64/bin")
      (msys-bin "C:/tools/msys64/usr/bin"))
  (dolist (dir (list ucrt-bin msys-bin))
    (when (file-directory-p dir)
      (add-to-list 'exec-path dir)))

  (setenv "PATH"
          (mapconcat #'identity
                     (list ucrt-bin
                           msys-bin
                           (getenv "PATH"))
                     path-separator)))

(setq shell-file-name "C:/tools/msys64/usr/bin/bash.exe"
      explicit-shell-file-name shell-file-name
      shell-command-switch "-c")

(setenv "MSYSTEM" "UCRT64")
(setenv "MINGW_PREFIX" "/ucrt64")
(setenv "MSYSTEM_PREFIX" "/ucrt64")

(setenv "PKG_CONFIG_PATH"
        "/ucrt64/lib/pkgconfig:/ucrt64/share/pkgconfig")

(setenv "PKG_CONFIG_SYSTEM_INCLUDE_PATH"
        "/ucrt64/include")

(setenv "PKG_CONFIG_SYSTEM_LIBRARY_PATH"
        "/ucrt64/lib")

(after! eglot
  ;; Clangd con toolchain GCC UCRT64
  (add-to-list
   'eglot-server-programs
   '((c-mode c-ts-mode c++-mode c++-ts-mode)
     . ("clangd"
        "--query-driver=C:/tools/msys64/ucrt64/bin/gcc.exe")))

  ;; Disabilita gli inlay hints
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (when (fboundp 'eglot-inlay-hints-mode)
                (eglot-inlay-hints-mode -1)))))

(use-package! powershell
  :mode ("\\.ps[dm]?1\\'" . powershell-mode))

(after! corfu
  (setq corfu-auto t
        corfu-auto-prefix 2
        corfu-auto-delay 0.15
        corfu-preview-current nil)
  (global-corfu-mode +1))
;; Fix PATH Windows per tool Unix usati da Doom/Projectile/Eglot
(let ((msys-bin "C:/tools/msys64/usr/bin"))
  (when (file-directory-p msys-bin)
    (add-to-list 'exec-path msys-bin)
    (setenv "PATH"
            (concat msys-bin path-separator (getenv "PATH")))))

;; Fix PATH npm globale per pyright
(add-to-list 'exec-path "C:/Users/matteoPrampolini-Mut/AppData/Roaming/npm")

(setenv "PATH"
        (concat "C:/Users/matteoPrampolini-Mut/AppData/Roaming/npm"
                path-separator
                (getenv "PATH")))

;; Evita il find.exe marcio di Windows per indicizzare progetti
(after! projectile
  (setq projectile-indexing-method 'native))

;; Eglot + Pyright
(after! eglot
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("C:/Users/matteoPrampolini-Mut/AppData/Roaming/npm/pyright-langserver.cmd"
                    "--stdio"))))

(after! eww
  (set-popup-rule! "^\\*eww\\*" :ignore t))
(use-package! svelte-mode
  :mode "\\.svelte\\'")

(add-hook 'svelte-mode-local-vars-hook #'lsp! 'append)
(after! lsp-mode
  (setq lsp-headerline-breadcrumb-enable nil
        lsp-lens-enable nil
        lsp-inlay-hint-enable nil))

(after! lsp-dart
  (setq lsp-dart-flutter-sdk-dir "C:/Users/MatteoPrampolini-Mut/flutter"))

