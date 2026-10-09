;;; prampo_config/superagenda.el -*- lexical-binding: t; -*-

;; TODO: bug shift arrow-> crescita degli header infinita.
;;
;;
;;; Icone: stesso font per titoli, categorie e indicatori.
(defun my/org-superagenda-icon-font ()
  "Restituisce il font delle icone, se disponibile sul frame corrente."
  (let ((family (if (boundp 'nerd-icons-font-family)
                    nerd-icons-font-family
                  "Symbols Nerd Font Mono")))
    (when (and (display-graphic-p)
               (find-font (font-spec :family family)))
      family)))

(defun my/org-superagenda-icon (glyph fallback)
  "Mostra GLYPH con il font delle icone, oppure FALLBACK se non disponibile."
  (if-let ((family (my/org-superagenda-icon-font)))
      (propertize glyph 'face `(:family ,family))
    fallback))

;;; Stili: ereditano dal tema. Nessun colore RGB/HEX fissato qui.
(defvar-local my/org-superagenda-face-cookies nil
  "Stili applicati solo al buffer di questa agenda.")

;; org-agenda-mode conserva face-remapping-alist quando ricrea il buffer.
;; Conserva anche i riferimenti necessari a rimuovere i nostri vecchi stili:
;; altrimenti ogni refresh accumula un altro moltiplicatore :height.
(put 'my/org-superagenda-face-cookies 'permanent-local t)

(defun my/org-superagenda-style ()
  "Mantiene lo stile locale alla vista, anche quando viene aggiornata."
  (when (equal (buffer-name) "*Org Agenda: Prampo*")
    (require 'face-remap)
    (dolist (cookie my/org-superagenda-face-cookies)
      (face-remap-remove-relative cookie))
    (setq my/org-superagenda-face-cookies nil)
    (dolist (spec '((org-agenda-structure :height 1.3 :weight bold)
                   (org-super-agenda-header
                    :inherit org-level-2 :height 1.15 :weight bold)
                   (org-agenda-date :height 1.0 :weight normal)
                   (org-agenda-date-today
                    :height 1.15 :weight bold :underline t)
                   ;; Un TODO pianificato usa il testo normale del tema.
                   ;; DONE e avvisi conservano le rispettive face del tema.
                   (org-scheduled :inherit default :weight normal)
                   (org-scheduled-today :inherit default :weight normal)))
      (push (face-remap-add-relative (car spec) (cdr spec))
            my/org-superagenda-face-cookies))
    ;; Org e super-agenda riscrivono le face dei titoli: riapplica il font
    ;; solo ai glifi, lasciando colore e dimensione ereditati dal titolo.
    (when-let ((family (my/org-superagenda-icon-font)))
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "[]" nil t)
            (add-face-text-property (match-beginning 0) (match-end 0)
                                    `(:family ,family))))))
    (setq-local line-spacing 0.08
                truncate-lines nil)
    (when (bound-and-true-p display-line-numbers-mode)
      (display-line-numbers-mode -1))))

(after! org-agenda
  (require 'org-super-agenda)
  (org-super-agenda-mode 1)
  (add-hook 'org-agenda-finalize-hook #'my/org-superagenda-style)

  (setq org-agenda-custom-commands
        (cons
         '("s" "Agenda semplice"
           ((agenda ""
                    ((org-agenda-overriding-header
                      (propertize
                       (concat "  " (my/org-superagenda-icon "" "📅")
                               "  La mia settimana\n")
                       'face 'org-agenda-structure))
                     ;; 3 giorni passati + oggi + 6 futuri = 10 giorni.
                     ;; Con -2d e span 10: 2 passati + oggi + 7 futuri.
                     (org-agenda-start-day "-3d")
                     (org-agenda-start-on-weekday nil)
                     (org-agenda-span 10)
                     (org-agenda-show-all-dates t)
                     (org-agenda-show-future-repeats t)
                     ;; Come nell'originale: calendario in ordine cronologico.
                     (org-super-agenda-groups nil)))
            (alltodo ""
                     ((org-agenda-overriding-header
                       (propertize
                        (concat "\n  " (my/org-superagenda-icon "" "📋")
                                "  TODO senza data\n")
                        'face 'org-agenda-structure))
                      (org-agenda-todo-ignore-scheduled 'all)
                      (org-agenda-todo-ignore-deadlines 'all)
                      (org-agenda-todo-ignore-with-date t)
                      (org-super-agenda-groups
                       `((:name ,(concat (my/org-superagenda-icon "" "!")
                                         "  Importanti")
                          :priority "A" :order 0)
                         (:name ,(concat (my/org-superagenda-icon "" "💼")
                                         "  Lavoro")
                          :category "lavoro" :order 1)
                         (:name ,(concat (my/org-superagenda-icon "" "⌂")
                                         "  Personale")
                          :category ("personale" "vita") :order 2)
                         (:auto-category t :order 3))))))
           ;; Opzioni limitate a questa vista, valide anche al refresh.
           ((org-agenda-buffer-name "*Org Agenda: Prampo*")
            (org-agenda-window-setup 'current-window)
            ;; Usa le date italiane della configurazione org.el.
            (org-agenda-format-date "%A, %d %B %Y")
            (org-agenda-compact-blocks nil)
            (org-agenda-block-separator ?─)
            (org-agenda-start-with-log-mode nil)
            (org-agenda-skip-scheduled-if-done t)
            (org-agenda-skip-deadline-if-done t)
            (org-agenda-skip-timestamp-if-done t)
            ;; Ripristina la griglia originale, togliendo solo gli slot doppi.
            (org-agenda-use-time-grid t)
            (org-agenda-show-current-time-in-grid t)
            (org-agenda-time-grid
             (let ((grid (copy-tree org-agenda-time-grid)))
               (setcar grid (cons 'remove-match (remq 'remove-match (car grid))))
               grid))
            (org-agenda-time-leading-zero t)
            (org-agenda-category-icon-alist
             (list
              (list "^lavoro$"
                    (list (concat (my/org-superagenda-icon "" "💼") " "))
                    nil nil :ascent 'center)
              (list "^\\(?:personale\\|vita\\)$"
                    (list (concat (my/org-superagenda-icon "" "⌂") " "))
                    nil nil :ascent 'center)))
            ;; %i = icona, %t = orario, %s = Scheduled/Deadline.
            ;; Niente "?": la colonna orario resta anche sulle righe senza ora.
            (org-agenda-prefix-format
             '((agenda . "  %i %-12t %-17s ")
               (todo   . "  %i ")
               (tags   . "  %i ")
               (search . "  %i ")))
            (org-agenda-scheduled-leaders
             (list (concat (my/org-superagenda-icon "" "📅") " Scheduled: ")
                   (concat (my/org-superagenda-icon "" "📅") " Sched.%2dx: ")))
            (org-agenda-deadline-leaders
             (list (concat (my/org-superagenda-icon "" "◷") " Deadline: ")
                   (concat (my/org-superagenda-icon "" "◷") " In %d d.: ")
                   (concat (my/org-superagenda-icon "" "◷") " %d d. ago: ")))
            ;; Keyword, priorità e avvisi mantengono i colori del tema.
            (org-super-agenda-header-map (make-sparse-keymap))
            (org-super-agenda-header-prefix "  ")
            (org-super-agenda-header-separator "\n")
            (org-super-agenda-keep-order t)))
         (assoc-delete-all "s" org-agenda-custom-commands))))

(defun my/org-superagenda-open ()
  "Apri la tua agenda semplice."
  (interactive)
  (org-agenda nil "s"))

(map! :leader
      :prefix "o"
      :desc "Agenda semplice" "s" #'my/org-superagenda-open)

;;; superagenda.el ends here
