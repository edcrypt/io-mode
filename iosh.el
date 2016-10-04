(require 'io-mode)


(defvar iolang-cli-file-path "/usr/local/bin/io"
  "Path to the program used by `run-iolang'")

(defvar iolang-cli-arguments '()
  "Commandline arguments to pass to `iolang-cli'")

(defvar iolang-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; example definition
    (define-key map "\t" 'completion-at-point)
    map)
  "Basic mode map for `run-iolang'")

(defvar iolang-prompt-regexp "^Io>"
  "Prompt for `run-iolang'.")

(defun run-iolang ()
  "Run an inferior instance of `iolang-cli' inside Emacs."
  (interactive)
  (let* ((iolang-program iolang-cli-file-path)
         (buffer (comint-check-proc "IoLanguage")))
    ;; pop to the "*IoLanguage*" buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (pop-to-buffer-same-window
     (if (or buffer (not (derived-mode-p 'iolang-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create (or buffer "*IoLanguage*"))
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer "IoLanguage" buffer
             iolang-program iolang-cli-arguments)
      (iolang-mode))))


(defun iolang--initialize ()
  "Helper function to initialize Io"
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(define-derived-mode iolang-mode comint-mode "IoLanguage"
  "Major mode for `run-iolang'.

\\<iolang-mode-map>"
  nil "IoLanguage"
  ;; this sets up the prompt so it matches things like: [foo@bar]
  (setq comint-prompt-regexp iolang-prompt-regexp)
  ;; this makes it read only; a contentious subject as some prefer the
  ;; buffer to be overwritable.
  (setq comint-prompt-read-only t)
  ;; XXX this makes it so commands like M-{ and M-} work.
  ;; (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'font-lock-defaults) '(io-font-lock-keywords t))

  ;; comments
  ;; a) python style
  (modify-syntax-entry ?# "< b" io-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" io-mode-syntax-table)
  ;; b) c style
  (modify-syntax-entry ?/ ". 124b" io-mode-syntax-table)
  (modify-syntax-entry ?* ". 23" io-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" io-mode-syntax-table)


  (set (make-local-variable 'syntax-propertize-function)
       (syntax-propertize-rules
        (io-string-delimiter-re
         (0 (ignore (io-syntax-stringify))))))

  (setq comment-start "# "
        comment-start-skip "# *"
        comment-end ""
        comment-column 40
        comment-style 'indent)

  ;; strings
  (modify-syntax-entry ?\' "\"" io-mode-syntax-table)
  (modify-syntax-entry ?\" "\"" io-mode-syntax-table)

  ;; indentation
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'io-indent-line
        io-tab-width tab-width ;; just in case...
        indent-tabs-mode nil) ;; tabs are evil..

  (set (make-local-variable 'paragraph-start) iolang-prompt-regexp))

;; this has to be done in a hook. grumble grumble.
(add-hook 'iolang-mode-hook 'iolang--initialize)

(provide 'iolang-mode)
