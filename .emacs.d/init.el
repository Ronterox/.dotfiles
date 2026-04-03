;; Set up package.el to work with MELPA

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(setq package-check-signature nil)
(package-initialize)

(unless package--archive-contents
  (package-refresh-contents))

;; Magit
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; Download Evil and evil-collection
(unless (package-installed-p 'evil)
  (package-install 'evil))
(unless (package-installed-p 'evil-collection)
  (package-install 'evil-collection))

;; Evil configuration (must be before loading evil)
(setq evil-want-keybinding nil)
(setq evil-want-integration t)

;; Enable Evil
(require 'evil)
(evil-mode 1)

;; Enable evil-collection
(require 'evil-collection)
(evil-collection-init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(cmake-mode evil evil-collection magit)))
(custom-set-face
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Evil Mode
(define-key evil-insert-state-map (kbd "C-c C-c") 'evil-normal-state)
(define-key evil-normal-state-map (kbd "C-c C-c") 'evil-normal-state)
(setopt evil-undo-system 'undo-redo)

;; Init
(setq inhibit-startup-message t)
(xterm-mouse-mode 1)

;; Visuals
(menu-bar-mode -1)
(tab-bar-mode -1)
(load-theme 'modus-vivendi-tritanopia t)

(setq display-line-numbers-type 'relative)
(display-line-numbers-mode 1)

;; Coding
(show-paren-mode 1)
(hl-line-mode nil)

;; TAB completion
(setq tab-always-indent 'complete)
(add-to-list 'completion-styles 'initials t)

(define-key evil-normal-state-map (kbd "g c c") 'comment-line)
