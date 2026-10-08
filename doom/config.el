;; -*- lexical-binding: nil -*-

(load! "prampo_config/style.el")
(load! "prampo_config/org.el")
(load! "prampo_config/keybinds.el")
(load! "prampo_config/superagenda.el")
(when IS-WINDOWS
  (load! "prampo_config/windows.el")
  (load! "prampo_config/dev/msys2"))
