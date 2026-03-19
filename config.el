(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19)
      doom-unicode-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19))
;; Blink cursor
(blink-cursor-mode 1)

;;(setq doom-theme 'doom-outrun-electric)
;;(setq doom-theme 'doom-lantern)
;;(setq doom-theme 'doom-ephemeral)
;;(setq doom-theme 'doom-ir-black)
(add-to-list 'custom-theme-load-path "~/.config/doom/theme/")
(setq doom-theme 'doom-custom)

(setq display-line-numbers-type 'relative)

(setq fancy-splash-image "~/.config/doom/kyrii.png")
(add-hook '+doom-dashboard-mode-hook
          (lambda ()
            (run-with-idle-timer
             0 nil #'hide-mode-line-mode)))

(defun my/ascii-banner ()
  (insert "\n"
"                       ▓█████▄  ▒█████   ▒█████   ███▄ ▄███▓
                       ▒██▀ ██▌▒██▒  ██▒▒██▒  ██▒▓██▒▀█▀ ██▒
                       ░██   █▌▒██░  ██▒▒██░  ██▒▓██    ▓██░
                       ░▓█▄   ▌▒██   ██░▒██   ██░▒██    ▒██
                       ░▒████▓ ░ ████▓▒░░ ████▓▒░▒██▒   ░██▒
                       ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░   ░  ░
                       ░ ▒  ▒   ░ ▒ ▒░   ░ ▒ ▒░ ░  ░      ░
                       ░ ░  ░ ░ ░ ░ ▒  ░ ░ ░ ▒  ░      ░
                       ░        ░ ░      ░ ░         ░
                       ░


\n"))

(setq +doom-dashboard-functions
      '(doom-dashboard-widget-banner
        my/ascii-banner))

(map! :leader
      "." #'dirvish)
(after! dirvish
  (define-key dirvish-mode-map (kbd "'") #'dirvish-toggle-hidden)
(add-to-list 'dirvish-preview-disabled-exts "task"))
(after! dired
  (map! :map dired-mode-map
        :n "a" #'dired-create-empty-file))

(add-hook 'dirvish-mode-hook (lambda () (text-scale-set 0)))

(after! neotree
  (map! :map neotree-mode-map
        :n "h" #'neotree-select-up-node
        :n "H" #'neotree-hidden-file-toggle
        :n "a" #'neotree-create-node))

(setq delete-by-moving-to-trash t)

(defun my/vterm-right ()
  "Open a small vterm on the right side in the current directory and focus it."
  (interactive)
  (let ((default-directory (if (derived-mode-p 'dired-mode)
                               default-directory
                             (file-name-directory (or buffer-file-name default-directory)))))
    (let ((buf (generate-new-buffer "vterm-right")))
      (with-current-buffer buf
        (vterm-mode))
      (let ((win (display-buffer-in-side-window
                  buf
                  '((side . right)
                    (slot . 1)
                    (window-width . 0.35)))))
        (select-window win))
      buf)))



(map! :leader
      "v" (cmd! (mpv-play (read-file-name "Play video: "))))

(defun my/open-qwen ()
  (interactive)
  (let* ((buffer (get-buffer-create "*my-side-term*"))
         (window (display-buffer-in-side-window
                  buffer
                  '((side . right)
                    (slot . 0)
                    (window-width . 0.4)))))
    (select-window window)  ;; <-- This gives it focus
    (with-current-buffer buffer
      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode))
      (vterm-send-string "ollama run qwen2.5-coder:1.5b")
      (vterm-send-return))))

;;opening files
(map! :leader
      (:prefix ("o" . "open")
       :desc "Open home.nix" "h" (lambda () (interactive) (find-file "~/.dotfiles/home.nix"))
       :desc "Open qwen" "q" #'my/open-qwen
       :desc "Open hyprland.conf" "H" (lambda () (interactive) (find-file "~/.dotfiles/modules/hyprland/hyprland.conf"))
       :desc "Open config.nix" "c" (lambda () (interactive) (find-file "~/.dotfiles/configuration.nix"))))

;;performing acitons

(defun my/run-file-in-vterm ()
  "Open vterm popup in current file's directory and run command based on file type.
After sending command, go to normal mode in vterm."
  (interactive)
  (let* ((file (buffer-file-name))
         (ext  (when file (file-name-extension file)))
         (default-directory (or (file-name-directory file) default-directory))
         (cmd
          (cond
           ((string= ext "rs") "cargo run")
           ((string= ext "c")
            (format "gcc %s -o a.out && ./a.out"
                    (shell-quote-argument file)))
           ((string= ext "cpp")
            (format "g++ %s -o a.out && ./a.out"
                    (shell-quote-argument file)))
           ((string= ext "py")
            (format "python %s"
                    (shell-quote-argument file)))
           (t (read-shell-command "Run command: ")))))
    ;; Open vterm popup
    (vterm)
    ;; Send command
    (vterm-send-string cmd)
    (vterm-send-return)
    ;; Switch to normal mode in vterm
    (when (fboundp 'evil-normal-state)
      (evil-normal-state))))

;; Bind it to a key, e.g. SPC o r
(map! :leader
      :desc "Run current file in vterm"
      "o e" #'my/run-file-in-vterm)

;; use web-mode for tsx files
(use-package! web-mode
  :mode ("\\.tsx\\'" . web-mode)
  :config
  (setq web-mode-content-types-alist '(("jsx" . "\\.tsx\\'")))
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-markup-indent-offset 2))

(map!
 :leader
 :prefix "f"
 :desc "New file in current directory"
 "n" (lambda ()
       (interactive)
       (let ((default-directory (expand-file-name default-directory)))
         (call-interactively 'find-file))))

(after! org
  (setq org-latex-pdf-process
        '("xelatex -interaction=nonstopmode -output-directory=%o %f"
          "xelatex -interaction=nonstopmode -output-directory=%o %f")))
(add-hook 'LaTeX-mode-hook #'cdlatex-mode)
(after! cdlatex
  (map! :map cdlatex-mode-map
        :i "C-c e" #'cdlatex-environment))

(setq +latex-viewers '(pdf-tools))
(add-hook 'LaTeX-mode-hook (lambda ()
                             (outline-minor-mode 1)))
(map! :map cdlatex-mode-map
      :i "TAB" #'cdlatex-tab)

;   (after! writeroom-mode
;   (setq writeroom-global-effects nil
;           writeroom-scale 1))
;
;   (add-hook 'after-change-major-mode-hook #'writeroom-mode)
(text-scale-set 0)

(setq-default mode-line-format nil)

(after! highlight-indent-guides
  ;; enable in programming modes
  (add-hook 'prog-mode-hook #'highlight-indent-guides-mode)
  ;; appearance
  (setq highlight-indent-guides-method 'character
        highlight-indent-guides-delay 0.1)
  (set-face-attribute 'highlight-indent-guides-odd-face nil :foreground "#444444")
  (set-face-attribute 'highlight-indent-guides-even-face nil :foreground "#333333")
  (set-face-attribute 'highlight-indent-guides-character-face nil :foreground "#555555"))
(map! :leader
      :desc "Toggle indent guides"
      "a h" #'highlight-indent-guides-mode)

(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'prog-mode-hook #'flyspell-prog-mode)

(use-package! wordnut
  :config
  (setq wordnut-command "wn"))

(map! :leader
      :desc "Lookup word meaning"
      "a d" #'wordnut-search)

(defun thanos/wtype-text (text)
"Process TEXT for wtype, handling newlines properly."
(let* ((has-final-newline (string-match-p "\n$" text))
        (lines (split-string text "\n"))
        (last-idx (1- (length lines))))
    (string-join
    (cl-loop for line in lines
            for i from 0
            collect (cond
                    ;; Last line without final newline
                    ((and (= i last-idx) (not has-final-newline))
                        (format "wtype -s 350 \"%s\""
                                (replace-regexp-in-string "\"" "\\\\\"" line)))
                    ;; Any other line
                    (t
                        (format "wtype -s 350 \"%s\" && wtype -k Return"
                                (replace-regexp-in-string "\"" "\\\\\"" line)))))
    " && ")))

(defun thanos/type ()
"Launch a temporary frame with a clean buffer for typing."
(interactive)
(let ((frame (make-frame '((name . "emacs-float")
                            (fullscreen . 0)
                            (undecorated . t)
                            (width . 70)
                            (height . 20))))
        (buf (get-buffer-create "emacs-float")))
    (select-frame frame)
    (switch-to-buffer buf)
    (erase-buffer)
    (org-mode)
    (setq-local header-line-format
                (format " %s to insert text or %s to cancel."
                        (propertize "C-c C-c" 'face 'help-key-binding)
            (propertize "C-c C-k" 'face 'help-key-binding)))
    (local-set-key (kbd "C-c C-k")
        (lambda () (interactive)
            (kill-new (buffer-string))
            (delete-frame)))
    (local-set-key (kbd "C-c C-c")
        (lambda () (interactive)
            (start-process-shell-command
            "wtype" nil
            (thanos/wtype-text (buffer-string)))
            (delete-frame)))))
