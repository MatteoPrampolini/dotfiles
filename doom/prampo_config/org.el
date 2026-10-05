;;; prampo_config/org.el -*- lexical-binding: t; -*-

;; Nota:
;; - Windows: "Italian_Italy.1252"
;; - Linux/macOS: "it_IT.UTF-8"
(setq system-time-locale "it_IT.UTF-8"
      calendar-date-style 'european
      calendar-week-start-day 1)

(with-eval-after-load 'parse-time
  (setq parse-time-weekdays
        (append
         '(("dom" . 0)
           ("lun" . 1)
           ("mar" . 2)
           ("mer" . 3)
           ("gio" . 4)
           ("ven" . 5)
           ("sab" . 6)

           ("domenica" . 0)
           ("lunedì" . 1)
           ("martedì" . 2)
           ("mercoledì" . 3)
           ("giovedì" . 4)
           ("venerdì" . 5)
           ("sabato" . 6))
         parse-time-weekdays))

  (setq parse-time-months
        (append
         '(("gen" . 1)
           ("feb" . 2)
           ("mar" . 3)
           ("apr" . 4)
           ("mag" . 5)
           ("giu" . 6)
           ("lug" . 7)
           ("ago" . 8)
           ("set" . 9)
           ("ott" . 10)
           ("nov" . 11)
           ("dic" . 12)

           ("gennaio" . 1)
           ("febbraio" . 2)
           ("marzo" . 3)
           ("aprile" . 4)
           ("maggio" . 5)
           ("giugno" . 6)
           ("luglio" . 7)
           ("agosto" . 8)
           ("settembre" . 9)
           ("ottobre" . 10)
           ("novembre" . 11)
           ("dicembre" . 12))
         parse-time-months)))

;;; Configurazione Org Mode & Capture Templates
(setq system-time-locale "Italian_Italy.1252"
      calendar-date-style 'european
      calendar-week-start-day 1)
(after! org
  ;; Formattazione date e Agenda
  (setq org-display-custom-times t
        org-timestamp-custom-formats
        '("%a %d %b %Y" . "%a %d %b %Y %H:%M")
        org-agenda-format-date "%A, %d %B %Y")

  ;; File e percorsi
  (setq org-directory "~/org/"
        org-agenda-files '("~/org/agenda.org"))

  ;; Org Capture Templates
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "~/org/agenda.org" "Tasks")
           "* TODO %?\n"
           :prepend t)

          ("s" "Scheduled todo" entry
           (file+headline "~/org/agenda.org" "Tasks")
           "* TODO %?\nSCHEDULED: %^t\n"
           :prepend t)

          ("d" "Deadline" entry
           (file+headline "~/org/agenda.org" "Tasks")
           "* TODO %?\nDEADLINE: %^t\n"
           :prepend t)

          ("a" "Assistenza / Ticket" item
           (file+headline "~/org/agenda.org" "Tickets")
           "- [ ] %^{Cliente} %^{Minuti}m: %^{Motivo} (%^{Persona}) %u"
           :prepend t
           :after-finalize my/org-update-ticket-cookie))))

;magia che aggiorna [/] quando creo un nuovo ticket
(defun my/org-update-ticket-cookie ()
  (when (marker-buffer org-capture-last-stored-marker)
    (with-current-buffer (marker-buffer org-capture-last-stored-marker)
      (save-excursion
        (goto-char org-capture-last-stored-marker)
        (org-back-to-heading t)
        (org-update-statistics-cookies nil)))))
; SPC m X cambia [ ] -> [-]
(map! :after org
      :map org-mode-map
      :localleader
      :desc "Set checkbox to [-]" "X"
      (lambda ()
        (interactive)
        (org-toggle-checkbox '(16))))

;capire se utile o no. copia clipboard come png nei file org
(use-package! org-download
  :after org
  :config
  ;; Imposta la directory delle immagini sulla stessa cartella del file .org
  (setq-default org-download-image-dir ".")
  ;; Scegli il metodo di cattura per la clipboard
  (setq org-download-screenshot-method "xclip -selection clipboard -t image/png -o > %s"))
