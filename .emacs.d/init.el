;; Set up package.el to work with MELPA  -*- lexical-binding: t; -*-
(setq packages-file (locate-user-emacs-file "packages.el"))
(load packages-file)

;; Evil Mode
(define-key evil-insert-state-map (kbd "C-c C-c") 'evil-normal-state)
(define-key evil-normal-state-map (kbd "C-c C-c") 'evil-normal-state)
(setopt evil-undo-system 'undo-redo)

;; Init
(setq inhibit-startup-message t)
(fset 'yes-or-no-p 'y-or-n-p)
(xterm-mouse-mode 1)

(savehist-mode 1)
(save-place-mode 1)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(put 'narrow-to-region 'disabled nil)

;; Visuals
(menu-bar-mode -1)
(tab-bar-mode -1)

(setq modus-themes-common-palette-overrides
    '((fg-line-number-inactive "gray50")
    (fg-line-number-active red-cooler)
    (bg-line-number-inactive unspecified)
    (bg-line-number-active unspecified)))

(load-theme 'modus-vivendi-tritanopia t)

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Coding
(show-paren-mode 1)
(hl-line-mode nil)

;; TAB completion
(setq tab-always-indent 'complete)
(add-to-list 'completion-styles 'initials t)

;; (define-key evil-visual-state-map (kbd "C-c") 'evil-yank-to-clipboard)
(define-key evil-normal-state-map (kbd "g c c") 'comment-line)
(define-key evil-normal-state-map (kbd "C-q") 'recentf-open-files)

;; Org Mode
(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)))
  (define-key evil-normal-state-map (kbd "C-x >") 'org-shiftright)
  (define-key evil-normal-state-map (kbd "C-x <") 'org-shiftleft))

(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)
