;;; prampo_config/superagenda.el -*- lexical-binding: t; -*-

;; TODO: roba ricorrente è segnata come verde DONE anche se nella giornata odierna è TODO.
;; TODO: icona iniziale rotta
;; TODO: rivedere UI
;;
(after! org-agenda
  (require 'org-super-agenda)
  (org-super-agenda-mode 1)

  (setq org-super-agenda-header-map nil
        org-super-agenda-groups nil)

  ;; 1. Gerarchia Visiva (Stili dei Font e Dimensioni)
  (custom-set-faces!
    '(org-agenda-date-today
      :height 1.25
      :weight bold
      :foreground "#ECBE7B"
      :underline t)
    '(org-agenda-date
      :height 1.0
      :weight normal)
    '(org-super-agenda-header
      :height 1.2
      :weight bold
      :foreground "#c678dd"))

  ;; 2. Icone di categoria (aggiunto uno spazio dopo l'icona per non farle "attaccare" al bordo o al testo)
  (setq org-agenda-category-icon-alist
        `(("lavoro"    ,(list " ") nil nil :ascent center)
          ("personale" ,(list " ") nil nil :ascent center)
          ("vita"      ,(list " ") nil nil :ascent center)))

  ;; 3. Prefisso corretto per un allineamento pulito
  ;; - %i mostra l'icona.
  ;; - %-2s crea 2 spazi vuoti di separazione fissa (sostituisce il vecchio %-12:c).
  ;; - %?-12t allinea gli orari (se presenti) a 12 caratteri.
  (setq org-agenda-prefix-format
        '((agenda . "  %i %-2s %?-12t ")
          (todo   . "  %i %-2s ")
          (tags   . "  %i %-2s ")
          (search . "  %i %-2s ")))

  ;; 4. Icone per Scheduled e Deadline
  (setq org-agenda-scheduled-leaders
        '("📅 Scheduled: " "📅 Sched.%2dx: "))
  (setq org-agenda-deadline-leaders
        '("⏰ Deadline: " "⏰ In %d d.: " "⏰ %d d. ago: "))

  (unless (boundp 'org-agenda-custom-commands)
    (setq org-agenda-custom-commands nil))

  ;; 5. Vista custom "s" con Titoli Sezione Ingranditi
  (setq org-agenda-custom-commands
        (cons
         '("s" "Agenda semplice"
           ((agenda ""
                    ((org-agenda-overriding-header
                      (propertize "\n  🗓  La mia settimana\n"
                                  'face '(:height 1.4 :weight bold :foreground "#51afef")))
                     (org-agenda-start-day "-3d")
                     (org-agenda-start-on-weekday nil)
                     (org-agenda-span 10)
                     (org-agenda-skip-scheduled-if-done t)
                     (org-agenda-skip-deadline-if-done t)
                     (org-agenda-skip-timestamp-if-done t)
                     (org-super-agenda-groups nil)))
            (alltodo ""
                     ((org-agenda-overriding-header
                       (propertize "\n  📋  TODO senza data\n"
                                   'face '(:height 1.4 :weight bold :foreground "#51afef")))
                      (org-agenda-todo-ignore-scheduled 'all)
                      (org-agenda-todo-ignore-deadlines 'all)
                      (org-agenda-todo-ignore-with-date t)
                      (org-super-agenda-groups
                       '((:name "   Importanti"
                          :priority "A")
                         (:name "   Lavoro"
                          :category "lavoro")
                         (:name "   Personale"
                          :category ("personale" "vita"))
                         (:auto-category t))))))
           ((org-agenda-window-setup 'current-window)))
         (assoc-delete-all "s" org-agenda-custom-commands))))

;; 6. Scorciatoia diretta SPC o s
(map! :leader
      :prefix "o"
      :desc "Agenda semplice" "s" (lambda () (interactive) (org-agenda nil "s")))
