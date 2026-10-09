;;; prampo_config/dev/msys2.el -*- lexical-binding: t; -*-

;; Installazione nuova, dal terminale "MSYS2 UCRT64":
;;
;;   pacman -Syu
;;
;; Se viene richiesta la chiusura, riaprire il terminale e ripetere -Syu.
;;
;; Poi:
;;
;;   pacman -S --needed make diffutils findutils \
;;     mingw-w64-ucrt-x86_64-gcc \
;;     mingw-w64-ucrt-x86_64-gdb \
;;     mingw-w64-ucrt-x86_64-clang-tools-extra \
;;     mingw-w64-ucrt-x86_64-pkgconf \
;;     mingw-w64-ucrt-x86_64-ripgrep \
;;     mingw-w64-ucrt-x86_64-fd


;;; Configurazione MSYS2

(defvar prampo/msys2-root "C:/tools/msys64"
  "Directory di installazione di MSYS2.")

(when (eq system-type 'windows-nt)

  (let* ((root (file-name-as-directory
                (expand-file-name prampo/msys2-root)))

         (ucrt-bin (directory-file-name
                    (expand-file-name "ucrt64/bin" root)))

         (msys-bin (directory-file-name
                    (expand-file-name "usr/bin" root)))

         (bash (expand-file-name "bash.exe" msys-bin)))

    (if (not (and (file-exists-p bash)
                  (file-directory-p ucrt-bin)))

        ;; MSYS2 non trovato.
        (display-warning
         'prampo-msys2
         (format "MSYS2 UCRT64 non trovato in %s. Controlla prampo/msys2-root."
                 root)
         :warning)

      ;; MSYS2 trovato.
      (progn

        ;;; PATH

        ;; UCRT64 ha precedenza sugli strumenti MSYS.
        ;; delete-dups evita duplicati quando ricarichi il file.

        (let ((dirs (list ucrt-bin msys-bin)))

          (setq exec-path
                (delete-dups
                 (append dirs exec-path)))

          (setenv "PATH"
                  (mapconcat
                   #'identity
                   (delete-dups
                    (append dirs
                            (split-string
                             (or (getenv "PATH") "")
                             path-separator t)))
                   path-separator)))


        ;;; Ambiente MSYS2

        ;; Bash legge /etc/profile e prepara UCRT64.
        ;; CHERE_INVOKING mantiene la directory del progetto.
        ;; inherit conserva il PATH Windows (Git, Node, ecc.).

        (setenv "MSYSTEM" "UCRT64")
        (setenv "CHERE_INVOKING" "1")
        (setenv "MSYS2_PATH_TYPE" "inherit")


        ;;; Shell

        (setq shell-file-name bash
              shell-command-switch "-lc"
              explicit-shell-file-name bash
              explicit-bash-args '("--login" "-i"))


        ;;; Eglot / clangd

        ;; clangd deve utilizzare i compilatori UCRT64.
        ;; I flag di compilazione vengono dal progetto.

        (with-eval-after-load 'eglot

          (let* ((drivers
                  (mapcar
                   (lambda (name)
                     (expand-file-name name ucrt-bin))
                   '("gcc.exe"
                     "g++.exe"
                     "cc.exe"
                     "c++.exe")))

                 (command
                  (list
                   (expand-file-name "clangd.exe" ucrt-bin)
                   (concat
                    "--query-driver="
                    (mapconcat #'identity drivers ",")))))

            (setf
             (alist-get
              '(c-mode c-ts-mode c++-mode c++-ts-mode)
              eglot-server-programs
              nil nil #'equal)
             command)))))))


;;; Note
;;
;; --query-driver autorizza clangd a interrogare i compilatori elencati.
;;
;; Per progetti complessi utilizzare compile_commands.json.
;; Non sincronizzare su Linux database con percorsi assoluti Windows.
;;
;; La login shell legge anche i profili Bash personali:
;; evitare modifiche incondizionate di PATH o cd in .bashrc/.bash_profile.
;;
;; GDB installa Python UCRT come dipendenza.
;; Per Python usare un interprete/venv esplicito.


;;; msys2.el ends here
