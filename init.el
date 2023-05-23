(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(hc-zenburn))
 '(custom-safe-themes
   '("a37d20710ab581792b7c9f8a075fcbb775d4ffa6c8bce9137c84951b1b453016" "628278136f88aa1a151bb2d6c8a86bf2b7631fbea5f0f76cba2a0079cd910f7d" default))
 '(org-export-backends '(ascii html icalendar latex odt))
 '(package-selected-packages
   '(hc-zenburn-theme neotree org-superstar orgalist cal-china-x magit python-mode color-theme-sanityinc-tomorrow evil-collection savehist evil-leader csv-mode smart-mode-line company-box company-ebdb marginalia avy amx use-package q-mode evil-escape dashboard which-key centaur-tabs cpupower rainbow-delimiters counsel swiper ivy gruvbox-theme evil)))
;;generic cofiguration
(tool-bar-mode -1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(electric-pair-mode t)
(setq inhibit-startup-message t) 
(setq initial-scratch-message nil)
(global-display-line-numbers-mode)
(global-hl-line-mode t)
(column-number-mode)
(add-hook 'prog-mode-hook 'show-paren-mode)
;; Setting English Font
(set-face-attribute
 'default nil :font "IBM Plex Mono 14")
;; Chinese Font
(dolist (charset '(kana han symbol cjk-misc bopomofo))
  (set-fontset-font (frame-parameter nil 'font)
		    charset
		    (font-spec : "WenQuanYi Micro Hei Mono" :size 14)))
;;load-path
(add-to-list 'load-path "d:/Program Files/emacs/.emacs.d/elpa/")
;;backup
;; all backups goto ~/.backups instead in the current directory
(setq backup-directory-alist (quote (("." . "e:/emacs-backups"))))
;;Setting frame size
(add-to-list 'default-frame-alist '(height . 28))
(add-to-list 'default-frame-alist '(width . 100))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
;;MELPA
(require 'package)
(setq package-archives 
      '(("melpa" . "https://melpa.org/packages/")
	("gnu" . "https://elpa.gnu.org/packages/")))
;;use-package
(eval-when-compile
  (require 'use-package))
;;evil mode
(use-package evil
  :ensure t
  :init
  (setq evil-want-keybinding nil)
  (evil-mode 1)
  :config
  (setq evil-emacs-state-modes (delq 'ibuffer-mode evil-emacs-state-modes))
  (setq evil-emacs-state-cursor '("red" box))
  (setq evil-normal-state-cursor '("green" box))
  (setq evil-visual-state-cursor '("orange" box))
  (setq evil-insert-state-cursor '("red" bar))
  (setq evil-replace-state-cursor '("red" bar))
  (setq evil-operator-state-cursor '("red" hollow)) )
;;evil-leader
(use-package evil-leader
  :ensure t
  :config
  (setq in-all-states 1)
  (global-evil-leader-mode)
  (evil-leader/set-leader ",")
  (evil-leader/set-key
    "e" 'find-file
    "k" 'kill-buffer
    "w" 'save-buffer))
;;evil-collection
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))
;;ivy
(use-package counsel
  :ensure t)
(use-package ivy
  :ensure t
  :init
  (ivy-mode 1)
  (counsel-mode 1)
  :config
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d%d)")
  (setq enable-recursive-minibuffers t)
  (setq search-default-mode 'char-fold-to-regexp)
  :bind
  (("C-s" . 'swiper)
   ("M-y" . 'counsel-yank-pop)
   ("C-x b" . 'ivy-switch-buffer)
   ("C-c v" . 'ivy-push-view)
   ("C-c s" . 'ivy-switch-view)
   ("C-c V" . 'ivy-pop-view)
   :map minibuffer-local-map
   ("C-r" . counsel-minibuffer-history)))
;;rainbow-delimiters
(use-package rainbow-delimiters
  :ensure t
  :hook
  (foo-mode . rainbow-delimiters-mode)
  (prog-mode . rainbow-delimiters-mode))
;;amx
(use-package amx
  :ensure t
  :init
  (amx-mode 1))
;;q-mode
(autoload 'q-mode "q-mode")
(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-mode))
;;centaur-tabs
(use-package centaur-tabs
  :ensure t
  :demand
  :init
  (centaur-tabs-mode t)
  :config
  (centaur-tabs-headline-match)
  (setq centaur-tabs-style "bar")
  (setq centaur-tabs-set-icons t)
  (setq centaur-tabs-plain-icons t)
  (setq centaur-tabs-gray-out-icons 'buffer)
  (setq centaur-tabs-set-bar 'left)
  (setq centaur-tabs-set-modified-marker t)
  (setq centaur-tabs-modified-marker "*")
  :bind
  (("M-j" . 'centaur-tabs-backward)
   ("M-k" . 'centaur-tabs-forward))
  :hook
  (dired-mode . centaur-tabs-local-mode))
;;which-key
(use-package which-key
  :ensure t
  :init
  (which-key-mode 1))
;;set encoding
(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
;;dashboard
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))
;;evil-escape
(use-package evil-escape
  :ensure t
  :init
  (evil-escape-mode t)
  :config
  (setq-default evil-escape-key-sequence "jk"))
;;avy
(use-package avy
  :ensure t
  :bind
  (("C-'" . avy-goto-char-timer)))
;;marginalia
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1)
  :bind
  (:map minibuffer-local-map
	("M-A" . marginalia-cycle)))
;;company
(use-package company
  :ensure t
  :init (global-company-mode)
  :config
  (setq company-minimum-prefix-length 2)
  (setq company-tooltip-align-annotations t)
  (setq company-idle-delay 0.1)
  (setq company-show-numbers t)
  (setq company-selection-wrap-around t)
  (setq company-transformers '(company-sort-by-occurrence)))
;;;
(use-package company-box
  :ensure t
  :hook (company-mode . company-box-mode))
;;ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)
;;org-mode
(add-hook 'org-mode-hook 'turn-on-font-lock)
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)
(setq org-latex-toc-command "\\tableofcontents \\clearpage")
(add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))
(setq org-latex-listings 'minted)
(setq org-latex-minted-options '(("breaklines" "true")
				 ("breakanywhere" "true")))
(setq org-latex-pdf-process
      '("xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"
	"xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
;;org-capture templates
(setq org-capture-templates nil)
(add-to-list 'org-capture-templates '("t" "Tasks"))
(add-to-list 'org-capture-templates
	     '("tw" "Work Task" entry
	       (file+headline "e:/markdown/org/TODO/work_todo.org" "Work")
	       "* TODO %^{任务名} %U\n"))
(add-to-list 'org-capture-templates
	     '("tp" "Program Task" entry
	       (file+headline "e:/markdown/org/TODO/work_todo.org" "Program")
	       "* TODO %^{任务名} %U\n"))
(add-to-list 'org-capture-templates
	     '("w" "Web Collection" entry
	       (file+headline "e:/markdown/org/inbox.org" "Web")
	       "* %^{heading} %^g\n %?\n"))
;; This is usually the default, but keep in mind it must be nil
(setq org-hide-leading-stars nil)
(setq org-indent-mode-turns-on-hiding-stars nil)
;;org-refile-targets set
(setq org-refile-targets (quote (("program.org" :maxlevel . 1)
                                 ("work_todo.org" :level . 1))))
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-use-outline-path t)
;; Nice bullets
(use-package org-superstar
  :ensure t
  :config
  (setq org-superstar-special-todo-items t)
  (setq org-superstar-leading-bullet ?\s)
  (setq org-superstar-cycle-headline-bullets nil)
  (setq org-superstar-headline-bullets-list'("☰" "☷" "☵" "☯"))
  :hook
  (org-mode . org-superstar-mode))
;;cal-china-x
(require 'cal-china-x)
(setq mark-holidays-in-calendar t)
(setq cal-china-x-important-holidays cal-china-x-chinese-holidays)
(setq cal-china-x-general-holidays '((holiday-lunar 1 15 "元宵节")))
(setq calendar-holidays
      (append cal-china-x-important-holidays
	      cal-china-x-general-holidays))
;;format whole buffer
(defun indent-buffer()
  "Indent the whole buffer."
  (interactive)
  (indent-region (point-min)(point-max) nil))
;;bind to F7
(global-set-key [f7] 'indent-buffer)
;;neotree
(require 'neotree)
(global-set-key [f8] 'neotree-toggle)
;;csv mode with color
(defun csv-highlight (&optional separator)
  (interactive (list (when current-prefix-arg (read-char "Separator: "))))
  (font-lock-mode 1)
  (let* ((separator (or separator ?\,))
         (n (count-matches (string separator) (point-at-bol) (point-at-eol)))
         (colors (cl-loop for i from 0 to 1.0 by (/ 2.0 n)
                       collect (apply 'color-rgb-to-hex 
                                      (color-hsl-to-rgb i 0.3 0.5)))))
    (cl-loop for i from 2 to n by 2 
          for c in colors
          for r = (format "^\\([^%c\n]+%c\\)\\{%d\\}" separator separator i)
          do (font-lock-add-keywords nil `((,r (1 '(face (:foreground ,c)))))))))
(add-hook 'csv-mode-hook 'csv-highlight)
(add-hook 'csv-mode-hook (lambda () (interactive) (toggle-truncate-lines nil)))
