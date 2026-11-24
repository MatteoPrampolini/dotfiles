;; -*- lexical-binding: nil -*-

(load! "prampo_config/style.el")
(load! "prampo_config/org.el")
(load! "prampo_config/keybinds.el")
(load! "prampo_config/superagenda.el")
(load! "prampo_config/website.el")
(when IS-WINDOWS
  (load! "prampo_config/windows.el")
  (load! "prampo_config/dev/msys2"))

;this should be loaded AFTER mysys2
(load! "prampo_config/mail.el")
;;if PC at work
(when (string-equal (system-name) "HP-Matteo")
  (load! "prampo_config/work.el"))
