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

(unless (package-installed-p 'use-package)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'use-package))

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
      backup-directory-alist `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
      create-lockfiles nil
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t))
      read-process-output-max (* 1024 1024)
      use-dialog-box nil
      confirm-kill-emacs 'y-or-n-p)

(make-directory (expand-file-name "backups/" user-emacs-directory) t)

(tool-bar-mode -1)
(menu-bar-mode -1)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(electric-pair-mode 1)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(global-auto-revert-mode 1)
(column-number-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(show-paren-mode 1)
(setq recentf-max-saved-items 10)

(set-face-background 'hl-line "#003153")
(set-face-attribute 'region nil :background "#666" :foreground "#ffffff")
(set-face-foreground 'highlight nil)

(add-hook 'text-mode-hook #'visual-line-mode)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Encoding
(set-language-environment "UTF-8")
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(set-charset-priority 'unicode)

;; Fonts
(when (member "SF Mono" (font-family-list))
  (set-face-attribute 'default nil :font "SF Mono-18"))

(when (member "PingFang SC" (font-family-list))
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font t charset (font-spec :family "PingFang SC" :size 18))))

;; Server
(use-package server
  :ensure nil
  :config
  (unless (server-running-p)
    (server-start)))

;; -----------------------------------------------------------------------------
;; Theme / modeline / icons
;; -----------------------------------------------------------------------------

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
;; Minibuffer completion
;; -----------------------------------------------------------------------------

(use-package vertico
  :init
  (vertico-mode 1)
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  :config
  ;; Vertico ships this extension.  In file-name minibuffers, Backspace at
  ;; a directory boundary removes the whole previous path component.
  (require 'vertico-directory)
  (keymap-set vertico-map "DEL" #'vertico-directory-delete-char)
  (keymap-set vertico-map "<backspace>" #'vertico-directory-delete-char))

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
  (when (and (fboundp 'marginalia-annotate-file)
             (not (advice-member-p #'my/marginalia-annotate-file-safe
                                   'marginalia-annotate-file)))
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
   ("M-g M-g" . consult-goto-line)
   ("M-g i" . consult-imenu)
   ("M-g o" . consult-outline)
   ("M-s r" . consult-ripgrep)
   ("M-s f" . consult-find)
   ("M-s l" . consult-line))
  :custom
  (consult-preview-key nil))

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
;; In-buffer completion
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

(use-package magit
  :bind (("C-x g" . magit-status)))

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
;; Tabs / file tree / dashboard
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
;; Org mode
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

  (defun my/org-mode-setup ()
    "Apply local settings used by this Org workflow."
    (setq-local truncate-lines nil)
    (require 'org-tempo))
  (add-hook 'org-mode-hook #'my/org-mode-setup)

  ;; Original capture templates.
  (setq org-capture-templates nil)
  (add-to-list 'org-capture-templates '("t" "Tasks"))
  (add-to-list 'org-capture-templates
               '("tw" "Work Task" entry
                 (file+headline "~/Documents/markdown/org/TODO/work_todo.org" "Work")
                 "* TODO %^{Task name} %U
"))
  (add-to-list 'org-capture-templates
               '("tp" "Program Task" entry
                 (file+headline "~/Documents/markdown/org/TODO/work_todo.org" "Program")
                 "* TODO %^{Task name} %U
"))
  (add-to-list 'org-capture-templates
               '("w" "Web Collection" entry
                 (file+headline "~/Documents/markdown/org/inbox.org" "Web")
                 "* %^{heading} %^g
 %?
")))

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
;; Programming
;; -----------------------------------------------------------------------------

(use-package treesit-auto
  :when (treesit-available-p)
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
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

(autoload 'q-mode "q-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-mode))

(use-package csv-mode
  :mode "\\.csv\\'"
  :config
  (require 'cl-lib)
  (require 'color)
  (require 'subr-x)

  (defface my/csv-column-face-1
    '((t (:foreground "#ff6c6b")))
    "Face for CSV column group 1.")
  (defface my/csv-column-face-2
    '((t (:foreground "#98be65")))
    "Face for CSV column group 2.")
  (defface my/csv-column-face-3
    '((t (:foreground "#51afef")))
    "Face for CSV column group 3.")
  (defface my/csv-column-face-4
    '((t (:foreground "#c678dd")))
    "Face for CSV column group 4.")
  (defface my/csv-column-face-5
    '((t (:foreground "#ECBE7B")))
    "Face for CSV column group 5.")
  (defface my/csv-column-face-6
    '((t (:foreground "#46D9FF")))
    "Face for CSV column group 6.")

  (defconst my/csv-column-faces
    '(my/csv-column-face-1 my/csv-column-face-2 my/csv-column-face-3
      my/csv-column-face-4 my/csv-column-face-5 my/csv-column-face-6))

  (defun my/csv-font-lock-field-matcher (limit)
    "Font-lock matcher for one CSV field up to LIMIT.
The field number is saved in match data property `my/csv-field-index'."
    (when (< (point) limit)
      (let ((beg (point))
            (field (csv--field-index)))
        ;; Ensure progress and stay on the current physical CSV record.
        (condition-case nil
            (progn
              (csv-end-of-field)
              (let ((end (point)))
                (when (= beg end)
                  (when (< (point) limit) (forward-char 1))
                  (setq end (point)))
                (set-match-data (list beg end))
                (put-text-property beg end 'my/csv-field-index field)
                t))
          (error
           (goto-char (min limit (1+ beg)))
           nil)))))

  (defun my/csv-field-face ()
    "Return a face for the current font-lock field match."
    (let* ((field (or (get-text-property (match-beginning 0) 'my/csv-field-index) 1))
           (idx (mod (1- field) (length my/csv-column-faces))))
      (nth idx my/csv-column-faces)))

  (defun my/csv-install-column-colors ()
    "Install non-destructive per-column colours for this CSV buffer."
    (font-lock-add-keywords
     nil
     '((my/csv-font-lock-field-matcher
        (0 (my/csv-field-face) prepend)))
     'append)
    (font-lock-flush)
    (font-lock-ensure))

  (defvar-local my/csv-column-name-overlay nil)
  (defvar-local my/csv-header-cache nil)
  (defvar-local my/csv-last-point nil)

  (defun my/csv-parse-header ()
    "Parse the first CSV record and cache its field names."
    (save-excursion
      (goto-char (point-min))
      (while (and (not (eobp)) (csv-not-looking-at-record))
        (forward-line 1))
      (condition-case nil
          (if (fboundp 'csv-parse-current-row)
              (csv-parse-current-row)
            ;; Compatibility fallback for older csv-mode.
            (let ((fields nil))
              (beginning-of-line)
              (while (not (eolp))
                (let ((beg (point)))
                  (csv-end-of-field)
                  (push (string-trim
                         (buffer-substring-no-properties beg (point)))
                        fields))
                (unless (eolp) (forward-char 1)))
              (nreverse fields)))
        (error nil))))

  (defun my/csv-current-column-info ()
    "Return (INDEX HEADER BEG END) for the CSV field at point."
    (when (derived-mode-p 'csv-mode)
      (let ((index (csv--field-index)))
        (when (and index (> index 0))
          (unless my/csv-header-cache
            (setq my/csv-header-cache (my/csv-parse-header)))
          (save-excursion
            (beginning-of-line)
            (condition-case nil
                (progn
                  (csv-sort-skip-fields index)
                  (let ((beg (point)))
                    (csv-end-of-field)
                    (list index
                          (or (nth (1- index) my/csv-header-cache) "Unnamed")
                          beg
                          (max beg (point)))))
              (error nil)))))))

  (defun my/csv-update-column-name ()
    "Display current CSV column name at the end of the active field."
    (when (and (derived-mode-p 'csv-mode)
               (not (eq (point) my/csv-last-point)))
      (setq my/csv-last-point (point))
      (pcase (my/csv-current-column-info)
        (`(,index ,header ,beg ,end)
         (unless (overlayp my/csv-column-name-overlay)
           (setq my/csv-column-name-overlay
                 (make-overlay beg (max (1+ beg) end) nil nil t))
           (overlay-put my/csv-column-name-overlay 'priority 2000))
         ;; Ensure the overlay is non-empty whenever possible.
         (let ((real-end (if (> end beg)
                             end
                           (min (line-end-position) (1+ beg)))))
           (move-overlay my/csv-column-name-overlay beg real-end (current-buffer)))
         (overlay-put
          my/csv-column-name-overlay
          'after-string
          (propertize
           (format "  ⟪Column %d: %s⟫" index
                   (if (string-empty-p (string-trim header)) "Unnamed" header))
           'face '(:inherit font-lock-keyword-face :weight bold))))
        (_
         (when (overlayp my/csv-column-name-overlay)
           (delete-overlay my/csv-column-name-overlay)
           (setq my/csv-column-name-overlay nil))))))

  (defun my/csv-refresh-header-cache (&rest _)
    "Invalidate cached CSV headers after edits."
    (setq my/csv-header-cache nil))

  (defun my/csv-debug-current-column ()
    "Show concrete CSV diagnostics for the current buffer and point."
    (interactive)
    (if (not (derived-mode-p 'csv-mode))
        (user-error "FAIL: current major-mode is %S, not csv-mode" major-mode)
      (let ((info (my/csv-current-column-info)))
        (if info
            (pcase-let ((`(,index ,header ,beg ,end) info))
              (message "PASS csv-mode=%S field=%d header=%S range=%d..%d overlay=%S hook=%S"
                       major-mode index header beg end
                       (overlayp my/csv-column-name-overlay)
                       (memq #'my/csv-update-column-name post-command-hook)))
          (message "FAIL: csv-mode active but field/header could not be parsed")))))

  (defun my/csv-self-test ()
    "Run a deterministic self-test for CSV parsing and column lookup."
    (interactive)
    (let ((ok nil)
          (details ""))
      (with-temp-buffer
        (insert "Name,Age,Note
Alice,30,\"hello,world\"
")
        (csv-mode)
        (setq my/csv-header-cache (my/csv-parse-header))
        (goto-char (point-min))
        (forward-line 1)
        (csv-sort-skip-fields 3)
        (let* ((info (my/csv-current-column-info))
               (idx (nth 0 info))
               (header (nth 1 info)))
          (setq ok (and (= idx 3) (equal header "Note")))
          (setq details (format "field=%S header=%S headers=%S" idx header my/csv-header-cache))))
      (if ok
          (message "PASS: CSV column-name engine works (%s)" details)
        (user-error "FAIL: CSV column-name engine failed (%s)" details))))

  (defun my/csv-mode-setup ()
    "Enable reliable CSV colours and current-column-name display."
    ;; csv-mode defaults to truncated lines; keep that default because it makes
    ;; column position predictable in large CSV files.
    (my/csv-install-column-colors)
    (setq my/csv-header-cache (my/csv-parse-header))
    (add-hook 'post-command-hook #'my/csv-update-column-name nil t)
    (add-hook 'after-change-functions #'my/csv-refresh-header-cache nil t)
    (setq my/csv-last-point nil)
    (my/csv-update-column-name))

  (add-hook 'csv-mode-hook #'my/csv-mode-setup))

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
;; Custom file
;; -----------------------------------------------------------------------------

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; -----------------------------------------------------------------------------
;; Simplified Chinese / Traditional Chinese conversion
;; -----------------------------------------------------------------------------
(defun opencc-s2t-region (beg end)
  "Convert the selected Simplified Chinese text to Traditional Chinese."
  (interactive "r")
  (shell-command-on-region
   beg end
   "opencc -c s2t.json"
   (current-buffer)
   t))

(defun opencc-s2t-buffer ()
  "Convert the entire buffer to Traditional Chinese."
  (interactive)
  (opencc-s2t-region (point-min) (point-max)))

(defun opencc-t2s-region (beg end)
  "Convert the selected Traditional Chinese text to Simplified Chinese."
  (interactive "r")
  (shell-command-on-region
   beg end
   "opencc -c t2s.json"
   (current-buffer)
   t))

(defun opencc-t2s-buffer ()
  "Convert the entire buffer to Simplified Chinese."
  (interactive)
  (opencc-t2s-region (point-min) (point-max)))

;; -----------------------------------------------------------------------------
;; Diagnostics
;; -----------------------------------------------------------------------------

(defun my/find-file-backspace-self-test ()
  "Verify that Vertico handles Backspace with directory-aware deletion."
  (interactive)
  (let ((del (key-binding (kbd "DEL") t))
        (backspace (key-binding (kbd "<backspace>") t)))
    (if (and (eq (lookup-key vertico-map (kbd "DEL"))
                 #'vertico-directory-delete-char)
             (eq (lookup-key vertico-map (kbd "<backspace>"))
                 #'vertico-directory-delete-char))
        (message "PASS: Vertico Backspace is directory-aware (DEL=%S, <backspace>=%S)"
                 del backspace)
      (user-error "FAIL: vertico-map Backspace binding is not active"))))

(provide 'init)
;;; init.el ends here
