
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