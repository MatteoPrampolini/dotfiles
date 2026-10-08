;;; prampo_config/org.el -*- lexical-binding: t; -*-

;;; Lingua e date
(setq system-time-locale (if (eq system-type 'windows-nt)
                            "Italian_Italy.1252"
                          "it_IT.UTF-8")
      calendar-date-style 'european
      calendar-week-start-day 1)

;; Accetta anche i nomi italiani quando Emacs interpreta una data.
;; add-to-list evita duplicati se ricarichi la configurazione.
(with-eval-after-load 'parse-time
  (dolist (entry '(("dom" . 0) ("lun" . 1) ("mar" . 2)
                   ("mer" . 3) ("gio" . 4) ("ven" . 5) ("sab" . 6)
                   ("domenica" . 0) ("lunedì" . 1) ("martedì" . 2)
                   ("mercoledì" . 3) ("giovedì" . 4)
                   ("venerdì" . 5) ("sabato" . 6)))
    (add-to-list 'parse-time-weekdays entry))
  (dolist (entry '(("gen" . 1) ("feb" . 2) ("mar" . 3)
                   ("apr" . 4) ("mag" . 5) ("giu" . 6)
                   ("lug" . 7) ("ago" . 8) ("set" . 9)
                   ("ott" . 10) ("nov" . 11) ("dic" . 12)
                   ("gennaio" . 1) ("febbraio" . 2) ("marzo" . 3)
                   ("aprile" . 4) ("maggio" . 5) ("giugno" . 6)
                   ("luglio" . 7) ("agosto" . 8) ("settembre" . 9)
                   ("ottobre" . 10) ("novembre" . 11) ("dicembre" . 12)))
    (add-to-list 'parse-time-months entry)))

;;; Ticket
(defun my/org-update-ticket-cookie ()
  "Aggiorna e salva il contatore delle checkbox dopo un capture ticket."
  (when (and (not (bound-and-true-p org-note-abort))
             (boundp 'org-capture-last-stored-marker)
             (markerp org-capture-last-stored-marker)
             (marker-buffer org-capture-last-stored-marker))
    (with-current-buffer (marker-buffer org-capture-last-stored-marker)
      (save-excursion
        (save-restriction
          (widen)
          (goto-char org-capture-last-stored-marker)
          (org-back-to-heading t)
          ;; Il primo capture può creare "Tickets" senza contatore.
          (unless (string-match-p "\\[[0-9]*/[0-9]*\\]\\|\\[[0-9]*%\\]"
                                  (org-get-heading t t t t))
            (org-edit-headline
             (concat (org-get-heading t t t t) " [/]")))
          (org-update-statistics-cookies nil)))
      ;; after-finalize viene eseguito dopo il normale salvataggio di capture.
      (save-buffer))))

;;; File, capture e impostazioni comuni a Org
(after! org
  (setq org-directory (expand-file-name "~/org/")
        org-default-notes-file (expand-file-name "personale.org" org-directory)
        ;; Elenco esplicito: eventuali copie di conflitto non entrano in agenda.
        org-agenda-files
        (list (expand-file-name "lavoro.org" org-directory)
              (expand-file-name "personale.org" org-directory)))

  (setq org-display-custom-times t
        org-timestamp-custom-formats
        '("%a %d %b %Y" . "%a %d %b %Y %H:%M")
        org-agenda-format-date "%A, %d %B %Y")

  ;; I percorsi relativi dei capture sono risolti rispetto a org-directory.
  (setq org-capture-templates
        '(("t" "Todo personale" entry
           (file+headline "personale.org" "Tasks")
           "* TODO %?\n"
           :prepend t)

          ("s" "Todo personale pianificato" entry
           (file+headline "personale.org" "Tasks")
           "* TODO %?\nSCHEDULED: %^t\n"
           :prepend t)

          ("d" "Scadenza personale" entry
           (file+headline "personale.org" "Tasks")
           "* TODO %?\nDEADLINE: %^t\n"
           :prepend t)

          ("a" "Assistenza / Ticket" item
           (file+headline "lavoro.org" "Tickets")
           "- [ ] %^{Cliente} %^{Minuti}m: %^{Motivo} (%^{Persona}) %u\n"
           :prepend t
           :after-finalize my/org-update-ticket-cookie))))

;;; Checkbox
;; SPC m X cambia [ ] in [-].
(map! :after org
      :map org-mode-map
      :localleader
      :desc "Set checkbox to [-]" "X"
      (lambda ()
        (interactive)
        (org-toggle-checkbox '(16))))

;;; Immagini
(use-package! org-download
  :after org
  :config
  (setq-default org-download-image-dir ".")
  ;; Mantiene il metodo xclip solo dove è disponibile (Linux/X11).
  ;; Su Windows/macOS resta il metodo previsto da org-download.
  (when (and (eq system-type 'gnu/linux)
             (executable-find "xclip"))
    (setq org-download-screenshot-method
          "xclip -selection clipboard -t image/png -o > %s")))
