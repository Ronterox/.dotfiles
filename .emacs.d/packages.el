;; -*- lexical-binding: t; -*-

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(setq package-check-signature nil)
(package-initialize)

(unless (assoc 'melpa package-archives)
  (package-refresh-contents))

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package vterm
    :ensure t)

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
