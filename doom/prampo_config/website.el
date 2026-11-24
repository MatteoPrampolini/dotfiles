;;; ../dotfiles/doom/prampo_config/website.el -*- lexical-binding: t; -*-

(after! org
  (setq org-publish-project-alist
        '(("just-content"
           :base-directory "~/org/me/content/"
           :publishing-directory "~/org/me/public/"
           :recursive t
           :publishing-function org-html-publish-to-html
           :html-head "<link rel=\"stylesheet\" href=\"pico.classless.red.min.css\">
                        <link rel=\"stylesheet\" href=\"style.css\">"
           :with-toc nil
           :html-postamble nil
           :section-numbers nil)

          ("just-static"
           :base-directory "~/org/me/static/"
           :publishing-directory "~/org/me/public/"
           :base-extension "css\\|js\\|png\\|jpg\\|jpeg\\|svg\\|webp\\|ttf\\|txt"
           :recursive t
           :publishing-function org-publish-attachment)

          ("all"
           :components ("just-content" "just-static")))))
