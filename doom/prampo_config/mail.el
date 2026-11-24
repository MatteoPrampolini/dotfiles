;;; ../dotfiles/doom/prampo_config/mail.el -*- lexical-binding: t; -*-

(use-package! auth-source-xoauth2-plugin
  :config
  (auth-source-xoauth2-plugin-mode 1))

(setq auth-sources '("~/.authinfo.json")
      gnus-select-method
      '(nnimap "Gmail"
               (nnimap-address "imap.gmail.com")
               (nnimap-server-port 993)
               (nnimap-stream ssl)
               (nnimap-user "matteoprampolini@gmail.com")
               (nnimap-authenticator xoauth2))
      user-mail-address "matteoprampolini@gmail.com"
      user-full-name "Matteo Prampolini")

(after! gnus
  ;; Mostra i gruppi anche quando non ci sono email non lette
  (setq gnus-permanently-visible-groups ".*"

        ;; Ordina le email dalla più recente alla più vecchia
        gnus-thread-sort-functions '(gnus-thread-sort-by-most-recent-date)
        gnus-article-sort-functions '((not gnus-article-sort-by-date))

        ;; Mostra data, mittente e oggetto
        gnus-user-date-format-alist '((t . "%d-%#b %H:%M"))
        gnus-summary-line-format "%U%R %&user-date;  %-25,25f  %B%s\n"

        ;; Preferisci plain text rispetto a HTML
        mm-discouraged-alternatives '("text/html" "text/richtext")
        mm-text-html-renderer 'shr
        shr-use-colors nil
        shr-use-fonts nil

        ;; Gestione allegati e immagini
        gnus-mime-display-attachment-buttons-in-header t
        gnus-inhibit-images t
        gnus-blocked-images "."
        gnus-buttonized-mime-types '("multipart/alternative"))

  (custom-set-faces!
    '(gnus-header-from :foreground "white" :weight bold)
    '(gnus-header-subject :foreground "white" :weight bold)
    '(gnus-header-name :foreground "gray70")
    '(gnus-header-content :foreground "gray80")))

;; (setq gnus-select-method
;;       '(nnimap "MutinaNet"
;;                (nnimap-address "127.0.0.1")
;;                (nnimap-server-port 1143)
;;                (nnimap-stream network)
;;                (nnimap-user "matteo.prampolini@mutinanet.it"))
;;
;;       user-mail-address "matteo.prampolini@mutinanet.it"
;;       user-full-name "Matteo Prampolini")

(require 'gnus-art)
(require 'dom)
(require 'cl-lib)
(require 'thingatpt)
(require 'subr-x)
(require 'url-util)
(require 'image-mode)

(defun prampo/gnus-target (url)
  (when (consp url) (setq url (car url)))
  (when (stringp url)
    (if (and (string-match-p "\\`https?://[^/]+\\.safelinks\\.protection\\.outlook\\.com/" url)
             (string-match "[?&]url=\\([^&#]+\\)" url))
        (url-unhex-string (match-string 1 url))
      url)))

(defun prampo/gnus-selection ()
  (let* ((pos (point))
         (url (or (prampo/gnus-target (get-char-property pos 'gnus-button-url))
                  (get-char-property pos 'shr-url)
                  (thing-at-point 'url t)))
         (bounds (bounds-of-thing-at-point 'paragraph))
         label)
    (when bounds
      (save-excursion
        (goto-char (car bounds))
        (while (re-search-forward
                "^[ \t]*\\([^()\n]+?\\)[ \t]*(\\([ \t\r\n]*\\)\\(https?://[^() \t\r\n]+\\)[ \t\r\n]*)"
                (cdr bounds) t)
          (when (and (<= (match-beginning 1) pos) (< pos (match-end 0)))
            (setq label (string-trim (match-string-no-properties 1))
                  url (match-string-no-properties 3))))))
    (list (prampo/gnus-target url) label)))

(defun prampo/gnus-html-image (parts url label)
  (let (by-label by-link)
    (dolist (part parts)
      (when (equal (mm-handle-media-type part) "text/html")
        (let ((doc (with-temp-buffer
                     (set-buffer-multibyte nil)
                     (mm-insert-part part)
                     (libxml-parse-html-region (point-min) (point-max)))))
          (when url
            (dolist (a (dom-by-tag doc 'a))
              (when (equal url (prampo/gnus-target (dom-attr a 'href)))
                (dolist (img (dom-by-tag a 'img))
                  (when-let* ((src (dom-attr img 'src)))
                    (cl-pushnew src by-link :test #'equal))))))
          (dolist (img (dom-by-tag doc 'img))
            (let ((src (dom-attr img 'src))
                  (alt (string-trim (or (dom-attr img 'alt) ""))))
              (when (and src label (string-equal-ignore-case label alt))
                (cl-pushnew src by-label :test #'equal))
              (when (and src (equal src url))
                (cl-pushnew src by-link :test #'equal)))))))
    (let ((hits (or (cl-intersection by-link by-label :test #'equal)
                    by-link by-label)))
      (cond ((null hits)
             (user-error "Nell'HTML originale manca una corrispondenza per %s"
                         (or label url "il testo sotto il cursore")))
            ((cdr hits) (user-error "Questo link contiene più immagini"))
            (t (car hits))))))

(defun prampo/gnus-read-image (src parts)
  (if (string-prefix-p "cid:" src)
      (let* ((id (url-unhex-string (substring src 4)))
             (part (cl-find-if
                    (lambda (p)
                      (equal id (string-trim (or (mm-handle-id p) "") "<" ">")))
                    parts)))
        (unless part (user-error "Allegato assente: %s" id))
        (mm-get-part part))
    (when (string-prefix-p "//" src) (setq src (concat "https:" src)))
    (unless (string-match-p "\\`https?://" src)
      (user-error "Indirizzo immagine non supportato"))
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (let* ((coding-system-for-read 'binary)
             (status (call-process "curl.exe" nil (list t nil) nil
                                   "-fsSL" "--max-time" "20"
                                   "--proto" "=http,https" "--proto-redir" "=http,https"
                                   "--" src)))
        (unless (equal status 0) (user-error "Download fallito (curl %s)" status)))
      (buffer-string))))

(defun prampo/gnus-open-image-at-point ()
  (interactive)
  (unless (derived-mode-p 'gnus-article-mode)
    (user-error "Sposta il cursore nel corpo della mail"))
  (let ((selection (prampo/gnus-selection))
        (direct (get-char-property (point) 'image-url))
        (raw (get-buffer gnus-original-article-buffer))
        (end (line-end-position))
        (existing (overlays-in (line-beginning-position) (line-end-position)))
        image src)
    (unless raw (user-error "Gnus non ha il messaggio originale"))
    (with-temp-buffer
      (insert-buffer-substring raw)
      (goto-char (point-min))
      (let ((tree (mm-dissect-buffer t t)))
        (unless tree (user-error "Impossibile leggere le parti MIME"))
        (unwind-protect
            (let ((parts (mapcar #'cdr (gnus-article-mime-handles (list tree)))))
              (setq src (or direct (apply #'prampo/gnus-html-image parts selection)))
              (unless (cl-find src existing :test #'equal
                               :key (lambda (ov) (overlay-get ov 'prampo-image-src)))
                (let* ((bytes (prampo/gnus-read-image src parts))
                       (type (image-type-from-data bytes)))
                  (unless type (user-error "Formato immagine non riconosciuto"))
                  (setq image (create-image bytes type t))
                  (unless image (user-error "Immagine non visualizzabile")))))
          (mm-destroy-parts tree))))
    (when image
      (let ((ov (make-overlay (1- end) end)))
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'prampo-image-src src)
        (overlay-put ov 'after-string
                     (concat "\n" (propertize " " 'display image)))))))

(remove-hook 'gnus-article-prepare-hook #'prampo/gnus-image-markers)
(dolist (map '(gnus-article-mode-map gnus-summary-mode-map))
  (when (and (boundp map)
             (eq (lookup-key (symbol-value map) (kbd "<f8>"))
                 #'prampo/gnus-open-image-at-point))
    (define-key (symbol-value map) (kbd "<f8>") nil)))

(define-key gnus-article-mode-map (kbd "I") #'prampo/gnus-open-image-at-point)
(with-eval-after-load 'evil
  (evil-define-key* '(normal motion) gnus-article-mode-map
    (kbd "I") #'prampo/gnus-open-image-at-point))
