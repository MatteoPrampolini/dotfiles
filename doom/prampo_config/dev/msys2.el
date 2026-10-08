;;; prampo_config/dev/msys2.el -*- lexical-binding: t; -*-

;; Installazione nuova, dal terminale "MSYS2 UCRT64":
;;   pacman -Syu
;; Se viene richiesta la chiusura, riaprire il terminale e ripetere -Syu.
;; Poi:
;;   pacman -S --needed make diffutils findutils \
;;     mingw-w64-ucrt-x86_64-gcc \
;;     mingw-w64-ucrt-x86_64-gdb \
;;     mingw-w64-ucrt-x86_64-clang-tools-extra \
;;     mingw-w64-ucrt-x86_64-pkgconf \
;;     mingw-w64-ucrt-x86_64-ripgrep \
;;     mingw-w64-ucrt-x86_64-fd
;;

; TODO : SOMETHING IS WRONG WHEN WE LOAD THIS FILE.


(defvar prampo/msys2-root "C:/tools/msys64"

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
        (display-warning
         'prampo-msys2
         (format "MSYS2 UCRT64 non trovato in %s. Controlla prampo/msys2-root e installa i pacchetti; poi riavvia Emacs."
                 root)
         :warning)

      ;; Gli strumenti nativi avviati direttamente da Emacs (es. clangd)
      ;; devono vedere gli stessi binari scelti dalla shell: UCRT prima.
      ;; delete-dups evita di aggiungere ancora le stesse voci al reload.
      (let ((dirs (list ucrt-bin msys-bin)))
        (setq exec-path (delete-dups (append dirs exec-path)))
        (setenv "PATH"
                (mapconcat
                 #'identity
                 (delete-dups
                  (append dirs
                          (split-string (or (getenv "PATH") "")
                                        path-separator t)))
                 path-separator)))

      ;; Bash legge /etc/profile e prepara UCRT64, inclusi i PKG_CONFIG_*.
      ;; CHERE_INVOKING mantiene la directory del progetto.
      ;; inherit conserva anche il PATH dei tool Windows, es. Git e Node.
      ;; Non impostare queste variabili nell'ambiente globale di Windows.
      (setenv "MSYSTEM" "UCRT64")
      (setenv "CHERE_INVOKING" "1")
      (setenv "MSYS2_PATH_TYPE" "inherit")
      (setq shell-file-name bash
            shell-command-switch "-lc"
            explicit-shell-file-name bash
            explicit-bash-args '("--login" "-i"))

      ;; Eccezione della piattaforma: clangd deve usare questa toolchain.
      ;; La configurazione comune C/C++ non ha bisogno di path Windows.
      (with-eval-after-load 'eglot
        (let* ((drivers
                (mapcar (lambda (name) (expand-file-name name ucrt-bin))
                        '("gcc.exe" "g++.exe" "cc.exe" "c++.exe")))
               (command
                (list (expand-file-name "clangd.exe" ucrt-bin)
                      (concat "--query-driver="
                              (mapconcat #'identity drivers ",")))))
          (setf (alist-get '(c-mode c-ts-mode c++-mode c++-ts-mode)
                          eglot-server-programs nil nil #'equal)
                command))))))

;; --query-driver autorizza l'interrogazione dei compilatori elencati.
;; Il compilatore effettivo e i flag vengono dal progetto: per progetti
;; articolati fornire un compile_commands.json generato su questa macchina.
;; Non copiare su Linux un database con percorsi assoluti Windows.
;; La login shell legge anche i profili Bash personali: evitare cd o
;; sostituzioni di PATH incondizionate in .bash_profile/.bashrc.
;; GDB installa Python UCRT come dipendenza: per i progetti Python usare
;; un interprete/venv esplicito nel modulo Python, non il primo python nel PATH.

;;; msys2.el ends here
