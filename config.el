(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19)
      doom-unicode-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 19))

(setq doom-theme 'doom-ir-black)

(setq display-line-numbers-type 'relative)

(map! :leader
      "." #'dirvish)

(defun my/neotree-toggle ()
  "Neotree-toggle fails to track the path of the current file so i toggled neotree-find"
  (interactive)
  (if (neo-global--window-exists-p)
      (neotree-hide)
    (neotree-find (buffer-file-name))))

(map! :n "T" #'my/neotree-toggle)
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
      "t v" #'my/vterm-right)

(map! :leader
      "m g" #'magit-status)

(map! :leader
      "v" (cmd! (mpv-play (read-file-name "Play video: "))))

(defun my/run-current-file ()
  "Run the current file in a persistent vterm buffer at the bottom, depending on its type."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer not visiting a file"))
  (save-buffer)

  (let* ((file buffer-file-name)
         (ext (file-name-extension file))
         (default-directory (or (locate-dominating-file file "Cargo.toml")
                                default-directory))
         cmd)

    (setq cmd
          (cond
           ;; Rust Cargo project
           ((and (string= ext "rs")
                 (file-exists-p (expand-file-name "Cargo.toml" default-directory)))
            "cargo run")
           ;; Rust standalone file
           ((string= ext "rs")
            (format "rustc '%s' -o /tmp/a.out && /tmp/a.out" file))
           ;; C
           ((string= ext "c")
            (format "gcc '%s' -o /tmp/a.out && /tmp/a.out" file))
           ;; C++
           ((string= ext "cpp")
            (format "g++ '%s' -o /tmp/a.out && /tmp/a.out" file))
           ;; Python
           ((string= ext "py")
            (format "python3 '%s'" file))
           ;; LaTeX
           ((string= ext "tex")
            (format "pdflatex -interaction=nonstopmode '%s'" file))
           ;; unknown
           (t (user-error "No run rule defined for *.%s files" ext))))

    ;; spawn or reuse persistent vterm buffer
    (require 'vterm)
    (let ((vterm-buffer (get-buffer-create "*Run File*")))
      ;; display at bottom with smaller height
      (display-buffer-in-side-window
       vterm-buffer
       '((side . right)
         (slot . 0)
         (window-height . 0.2)))  ;; 20% of frame height

      ;; start vterm if not running
      (unless (comint-check-proc vterm-buffer)
        (with-current-buffer vterm-buffer
          (vterm-mode)))

      ;; send command
      (with-current-buffer vterm-buffer
        (vterm-send-string cmd)
        (vterm-send-return)))))

(map! :n "<f5>" #'my/run-current-file)
