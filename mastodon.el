;;; Code:
(require 'cl-lib)

;;
;; Constants
;;

(defconst mstdn-buffer-name " *Mastodon*"
  "Name of the buffer where mastodon.el shows Mastodon toot.")

(eval-and-compile

  ;; Added in Emacs 24.3
  (unless (fboundp 'user-error)
    (defalias 'user-error 'error))

  ;; Added in Emacs 24.3 (mirrors/emacs@b335efc3).
  (unless (fboundp 'setq-local)
    (defmacro setq-local (var val)
      "Set variable VAR to value VAL in current buffer."
      (list 'set (list 'make-local-variable (list 'quote var)) val)))

  ;; Added in Emacs 24.3 (mirrors/emacs@b335efc3).
  (unless (fboundp 'defvar-local)
    (defmacro defvar-local (var val &optional docstring)
      "Define VAR as a buffer-local variable with default value VAL.
Like `defvar' but additionally marks the variable as being automatically
buffer-local wherever it is set."
      (declare (debug defvar) (doc-string 3))
      (list 'progn (list 'defvar var val docstring)
            (list 'make-variable-buffer-local (list 'quote var))))))

;;
;; Macros
;;

;;
;; Customization
;;

(defgroup mastodon nil
  "Options for Mastodon."
  :prefix "mstdn-"
  :group 'files)

(defcustom mstdn-window-position 'bottom
  "*The position of Mastodon window."
  :group 'mastodon
  :type '(choice (const left)
                 (const right)
                 (const top)
                 (const bottom)))

(defcustom mstdn-display-action '(mstdn-default-display-fn)
  "*Action to use for displaying Mastodon window.
If you change the action so it doesn't use
`mstdn-default-display-fn', then other variables such as
`mstdn-window-position' won't be respected when opening Toot
window."
  :type 'sexp
  :group 'mastodon)

;;
;; Faces
;;

;;
;; Variables
;;

(defvar mstdn-global--buffer nil)

(defvar mstdn-global--window nil)

;;
;; Major mode definitions
;;

(define-derived-mode mastodon-mode special-mode "Mastodon"
  "A major mode for Mastodon client."
  (setq indent-tabs-mode nil            ; only spaces
        buffer-read-only t              ; read only
        truncate-lines -1)
  ;; fix for electric-indent-mode
  ;; for emacs 24.4
  (if (fboundp 'electric-indent-local-mode)
      (electric-indent-local-mode -1)
    ;; for emacs 24.3 or less
    (add-hook 'electric-indent-functions
              (lambda (arg) 'no-indent) nil 'local)))

;;
;; Global methods
;;

(defun mstdn-global--window-exists-p ()
  "Return non-nil if Mastodon window exists."
  (and (not (null (window-buffer mstdn-global--window)))
       (eql (window-buffer mstdn-global--window) (mstdn-global--get-buffer))))

(defun mstdn-global--select-window ()
  "Select the Mastodon window."
  (interactive)
  (let ((window (mstdn-global--get-window t)))
    (select-window window)))

(defun mstdn-global--get-window (&optional auto-create-p)
  "Return the Mastodon window if it exists, else return nil.
But when the Mastodon window does not exist and AUTO-CREATE-P is non-nil,
it will create the Mastodon window and return it."
  (unless (mstdn-global--window-exists-p)
    (setq mstdn-global--window nil))
  (when (and (null mstdn-global--window)
             auto-create-p)
    (setq mstdn-global--window
          (mstdn-global--create-window)))
  mstdn-global--window)

(defun mstdn-default-display-fn (buffer _alist)
  "Display BUFFER to the left or right of the root window.
The side is decided according to `mstdn-window-position'.
The root window is the root window of the selected frame.
_ALIST is ignored."
  (let ((window-pos (pcase mstdn-window-position
                      ('left 'left)
                      ('right 'right)
                      ('top 'top)
                      (mstdn-window-position 'bottom))))
    (display-buffer-in-side-window buffer `((side . ,window-pos)))))

(defun mstdn-global--create-window ()
  "Create global Mastodon window."
  (let ((window nil)
        (buffer (mstdn-global--get-buffer t)))
    (setq window
          (select-window
           (display-buffer buffer mstdn-display-action)))))

(defun mstdn-global--get-buffer (&optional init-p)
  "Return the global Mastodon buffer if it exists.
If INIT-P is non-nil and global Mastodon buffer not exists, then create it."
  (unless (equal (buffer-name mstdn-global--buffer)
                 mstdn-buffer-name)
    (setf mstdn-global--buffer nil))
  (when (and init-p
             (null mstdn-global--buffer))
    (save-window-excursion
      (setf mstdn-global--buffer
            (mstdn-buffer--create))))
  mstdn-global--buffer)

(defun mstdn-global--open ()
  "Show the Mastodon window."
  (mstdn-global--get-window t))

;;
;; Advices
;;

;;
;; Hooks
;;

;;
;; Util methods
;;

;;
;; Buffer methods
;;

(defun mstdn-buffer--create ()
  "Create and switch to Mastodon buffer."
  (switch-to-buffer
   (generate-new-buffer-name mstdn-buffer-name))
  (mastodon-mode)
  ;; disable linum-mode
  (when (and (boundp 'linum-mode)
             (not (null linum-mode)))
    (linum-mode -1))
  (current-buffer))

;;
;; Mode-line methods
;;

;;
;; Window methods
;;

;;
;; Interactive functions
;;

(defun mastodon-toggle ()
  "Toggle show the new Mastodon window."
  (interactive)
  (if (mstdn-global--window-exists-p)
      (mastodon-hide)
    (mastodon-show)))

(defun mastodon-show ()
  "Show the Mastodon window."
  (interactive)
  (let ((cw (selected-window)))
    (mstdn-global--open))
  (mstdn-global--select-window))

(defun mastodon-hide ()
  "Close the Mastodon window."
  (interactive)
  (if (mstdn-global--window-exists-p)
      (delete-window mstdn-global--window)))

;;
;; backward compatible
;;

(provide 'toot)
;;; toot.el ends here
