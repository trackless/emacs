;;; init.el --- Full upgraded single-file Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; Single-file upgraded configuration.
;; Goal: modernize UI/completion/project/LSP while preserving the original Org appearance/workflow.

;;; Code:

;; -----------------------------------------------------------------------------
;; Startup / package management
;; -----------------------------------------------------------------------------

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (ignore-errors (package-refresh-contents)))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; -----------------------------------------------------------------------------
;; Basic UI / editing defaults
;; -----------------------------------------------------------------------------

(setq inhibit-startup-message t
      initial-scratch-message nil
      ns-pop-up-frames nil
      ring-bell-function 'ignore
      visible-bell nil
      default-fill-column 60
      scroll-margin 3
      make-backup-files t
      auto-save-default t
      backup-directory-alist '(("." . "~/emacs-backups"))
      create-lockfiles nil
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t))
      read-process-output-max (* 1024 1024)
      use-dialog-box nil
      confirm-kill-emacs 'y-or-n-p)

(tool-bar-mode -1)
(menu-bar-mode -1)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(electric-pair-mode 1)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(global-auto-revert-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(show-paren-mode 1)
(setq recentf-max-saved-items 200)

(set-face-background 'hl-line "#003153")
(set-face-attribute 'region nil :background "#666" :foreground "#ffffff")
(set-face-foreground 'highlight nil)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'visual-line-mode)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Encoding
(set-language-environment "UTF-8")
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

;; Font: preserve original preference.
(when (member "SF Mono" (font-family-list))
  (set-face-attribute 'default nil :font "SF Mono-18"))

(when (member "PingFang SC" (font-family-list))
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font t charset (font-spec :family "PingFang SC" :size 18))))

;; -----------------------------------------------------------------------------
;; Theme / modeline / icons
;; -----------------------------------------------------------------------------

(use-package doom-themes
  :config
  (load-theme 'doom-one t)
  ;; Keep Doom's official Org faces only; no org-modern/variable-pitch/title scaling.
  (doom-themes-org-config)
  (doom-themes-visual-bell-config))

(use-package nerd-icons)
(use-package all-the-icons
  :if (display-graphic-p))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 4)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-minor-modes nil))

(use-package nyan-mode
  :init (nyan-mode 1))

(use-package colorful-mode
  :hook ((prog-mode text-mode q-mode) . colorful-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; -----------------------------------------------------------------------------
;; Evil workflow: preserve original leader and jk escape
;; -----------------------------------------------------------------------------

(use-package evil
  :init
  (setq evil-want-keybinding nil
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil)
  :config
  (evil-mode 1)
  (setq evil-emacs-state-modes (delq 'ibuffer-mode evil-emacs-state-modes))
  (setq evil-emacs-state-cursor '("red" box)
        evil-normal-state-cursor '("#8F4B28" box)
        evil-visual-state-cursor '("orange" box)
        evil-insert-state-cursor '("red" bar)
        evil-replace-state-cursor '("red" bar)
        evil-operator-state-cursor '("red" hollow)))

(use-package evil-leader
  :after evil
  :config
  (setq evil-leader/in-all-states 1)
  (global-evil-leader-mode)
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    "b" #'consult-buffer
    "e" #'find-file
    "k" #'kill-buffer
    "w" #'save-buffer
    "p" #'projectile-command-map
    "g" #'magit-status))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-escape
  :init (evil-escape-mode 1)
  :custom
  (evil-escape-key-sequence "jk")
  (evil-escape-delay 0.2))

(use-package undo-tree
  :init (global-undo-tree-mode 1)
  :custom
  (undo-tree-auto-save-history nil))

;; -----------------------------------------------------------------------------
;; Modern minibuffer completion: Vertico + Orderless + Consult + Marginalia
;; Replaces Ivy/Counsel/Swiper/AMX/Ivy-rich.
;; -----------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom
  (vertico-cycle t)
  (vertico-count 15))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init
  ;; Defensive wrapper for file annotation issues on some macOS setups.
  (defun my/marginalia-annotate-file-safe (orig cand)
    (or (ignore-errors (funcall orig cand)) ""))
  :config
  (when (fboundp 'marginalia-annotate-file)
    (advice-add 'marginalia-annotate-file :around #'my/marginalia-annotate-file-safe))
  (marginalia-mode 1))

(use-package consult
  :bind
  (("C-s" . consult-line)
   ("M-y" . consult-yank-pop)
   ("C-x b" . consult-buffer)
   ("C-c h" . consult-history)
   ("C-c m" . consult-mode-command)
   ("C-c k" . consult-kmacro)
   ("M-g g" . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-g i" . consult-imenu)
   ("M-g o" . consult-outline)
   ("M-s r" . consult-ripgrep)
   ("M-s f" . consult-find)
   ("M-s l" . consult-line))
  :custom
  (consult-preview-key 'any))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package which-key
  :custom
  (which-key-show-early-on-C-h t)
  (which-key-idle-delay 0.5)
  :init
  (which-key-mode 1))

;; -----------------------------------------------------------------------------
;; In-buffer completion: Corfu + Cape. Replaces Company/Company-box.
;; -----------------------------------------------------------------------------

(use-package corfu
  :init
  (global-corfu-mode 1)
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-preview-current nil)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  :bind (:map corfu-map
              ("TAB" . corfu-next)
              ([tab] . corfu-next)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous)
              ("RET" . corfu-insert)))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

(use-package yasnippet
  :init (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;; -----------------------------------------------------------------------------
;; Project / Git / navigation
;; -----------------------------------------------------------------------------

(use-package projectile
  :init (projectile-mode 1)
  :custom
  (projectile-completion-system 'default)
  (projectile-project-search-path '("~/gitlab" "~/DM" "~/Jts" "~/q"))
  :bind-keymap
  ("C-c p" . projectile-command-map))

;;(use-package magit
;;  :bind (("C-x g" . magit-status)))

(use-package avy
  :bind (("C-'" . avy-goto-char-timer)))

(use-package mwim
  :bind
  (("C-a" . mwim-beginning-of-code-or-line)
   ("C-e" . mwim-end-of-code-or-line)))

(use-package goto-line-preview
  :bind (("M-g g" . goto-line-preview)))

(global-set-key (kbd "C-x C-b") #'ibuffer)

;; -----------------------------------------------------------------------------
;; Tabs / file tree / dashboard: preserve original visual workflow
;; -----------------------------------------------------------------------------

(use-package centaur-tabs
  :demand t
  :init
  (centaur-tabs-mode 1)
  :config
  (centaur-tabs-headline-match)
  (setq centaur-tabs-style "bar"
        centaur-tabs-set-icons t
        centaur-tabs-plain-icons t
        centaur-tabs-gray-out-icons 'buffer
        centaur-tabs-set-bar 'left
        centaur-tabs-set-modified-marker t
        centaur-tabs-modified-marker "*"
        centaur-tabs-close-button "X")
  :bind
  (("M-j" . centaur-tabs-backward)
   ("M-k" . centaur-tabs-forward))
  :hook
  (dired-mode . centaur-tabs-local-mode))

(use-package neotree
  :bind ([f8] . neotree-toggle)
  :config
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow)))

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  :custom
  (dashboard-banner-logo-title "Nothing Is Impossible")
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-set-init-info t)
  (dashboard-set-navigator t)
  (dashboard-items '((recents . 5)
                     (bookmarks . 5))))

;; -----------------------------------------------------------------------------
;; Org mode: preserve original effect/workflow. No org-modern, no variable-pitch,
;; no custom title scaling, no hiding emphasis markers.
;; -----------------------------------------------------------------------------

(add-hook 'org-mode-hook #'turn-on-font-lock)
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

(use-package org
  :ensure nil
  :config
  (setq org-latex-toc-command "\\tableofcontents \\clearpage"
        org-latex-listings 'minted
        org-latex-minted-options '(("breaklines" "true")
                                   ("breakanywhere" "true"))
        org-latex-pdf-process
        '("xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"
          "xelatex -shell-escape -interaction nonstopmode -output-directory %o %f")
        org-hide-leading-stars nil
        org-indent-mode-turns-on-hiding-stars nil
        org-refile-targets '(("program.org" :maxlevel . 1)
                             ("work_todo.org" :level . 1))
        org-outline-path-complete-in-steps nil
        org-refile-use-outline-path t)

  (add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))
  (add-hook 'org-mode-hook (lambda () (require 'org-tempo)))

  ;; Original capture templates.
  (setq org-capture-templates nil)
  (add-to-list 'org-capture-templates '("t" "Tasks"))
  (add-to-list 'org-capture-templates
               '("tw" "Work Task" entry
                 (file+headline "~/Documents/markdown/org/TODO/work_todo.org" "Work")
                 "* TODO %^{任务名} %U\n"))
  (add-to-list 'org-capture-templates
               '("tp" "Program Task" entry
                 (file+headline "~/Documents/markdown/org/TODO/work_todo.org" "Program")
                 "* TODO %^{任务名} %U\n"))
  (add-to-list 'org-capture-templates
               '("w" "Web Collection" entry
                 (file+headline "~/Documents/markdown/org/inbox.org" "Web")
                 "* %^{heading} %^g\n %?\n")))

(use-package org-superstar
  :after org
  :config
  (setq org-superstar-special-todo-items t
        org-superstar-leading-bullet ?\s
        org-superstar-cycle-headline-bullets nil
        org-superstar-headline-bullets-list '("☰" "☷" "☵" "☯"))
  :hook
  (org-mode . org-superstar-mode))

;; -----------------------------------------------------------------------------
;; Programming: Tree-sitter, Eglot, language modes
;; -----------------------------------------------------------------------------

(use-package treesit-auto
  :when (treesit-available-p)
  :custom
  (treesit-auto-install 'prompt)
  :config
  (global-treesit-auto-mode 1))

(use-package eglot
  :ensure nil
  :hook
  ((python-mode python-ts-mode c-mode c-ts-mode c++-mode c++-ts-mode
                js-mode js-ts-mode typescript-ts-mode go-mode go-ts-mode
                rust-mode rust-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil))

(use-package python-mode
  :mode "\\.py\\'")

(autoload 'q-mode "q-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-mode))

(use-package csv-mode
  :mode "\\.csv\\'"
  :config
  (defun csv-highlight (&optional separator)
    (interactive (list (when current-prefix-arg (read-char "Separator: "))))
    (font-lock-mode 1)
    (let* ((separator (or separator ?,))
           (n (count-matches (string separator) (point-at-bol) (point-at-eol)))
           (colors (when (> n 0)
                     (cl-loop for i from 0 to 1.0 by (/ 2.0 n)
                              collect (apply #'color-rgb-to-hex
                                             (color-hsl-to-rgb i 0.3 0.5))))))
      (cl-loop for i from 2 to n by 2
               for c in colors
               for r = (format "^\\([^%c\n]+%c\\)\\{%d\\}" separator separator i)
               do (font-lock-add-keywords nil `((,r (1 '(face (:foreground ,c)))))))))
  (add-hook 'csv-mode-hook #'csv-highlight)
  (add-hook 'csv-mode-hook (lambda () (toggle-truncate-lines nil))))

;; -----------------------------------------------------------------------------
;; Utility commands / keybindings
;; -----------------------------------------------------------------------------

(defun indent-buffer ()
  "Indent the whole buffer."
  (interactive)
  (indent-region (point-min) (point-max) nil))

(global-set-key [f7] #'indent-buffer)

(use-package calendar
  :ensure nil
  :config
  (setq calendar-week-start-day 1))

;; -----------------------------------------------------------------------------
;; Custom variables kept minimal. Prefer package configuration above.
;; -----------------------------------------------------------------------------

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)
;;; init.el ends here
