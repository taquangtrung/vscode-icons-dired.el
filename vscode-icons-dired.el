;;; vscode-icons-dired.el --- Shows icons for each file in dired mode -*- lexical-binding: t -*-

;; Copyright (C) 2025 Ta Quang Trung <taquangtrungvn@gmail.com>

;; Author: Ta Quang Trung <taquangtrungvn@gmail.com>
;; Keywords: lisp
;; Package-Version:
;; Package-Revision:
;; Package-Requires: ((vscode-icons "0.0.1"))
;; URL: https://github.com/taquangtrung/vscode-icons-dired
;; Keywords: files, icons, dired

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To use this package, simply install and add this to your init.el
;; (require 'vscode-icons-dired)
;; (add-hook 'dired-mode-hook 'vscode-icons-dired-mode)

;; or use use-package:
;; (use-package vscode-icons-dired
;;   :hook
;;   (dired-mode . vscode-icons-dired-mode))

;;; Code:

(require 'dired)
(require 'vscode-icons)

(defvar vscode-icons-dired-mode)

(defun vscode-icons-dired--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((ov (make-overlay (1- pos) pos)))
    (overlay-put ov 'vscode-icons-dired-overlay t)
    (overlay-put ov 'after-string string)))

(defun vscode-icons-dired--overlays-in (beg end)
  "Get all vscode-icons-dired overlays between BEG to END."
  (cl-remove-if-not
   (lambda (ov)
     (overlay-get ov 'vscode-icons-dired-overlay))
   (overlays-in beg end)))

(defun vscode-icons-dired--overlays-at (pos)
  "Get vscode-icons-dired overlays at POS."
  (apply #'vscode-icons-dired--overlays-in `(,pos ,pos)))

(defun vscode-icons-dired--remove-all-overlays ()
  "Remove all `vscode-icons-dired' overlays."
  (save-restriction
    (widen)
    (mapc #'delete-overlay
          (vscode-icons-dired--overlays-in (point-min) (point-max)))))

(defun vscode-icons-dired--refresh ()
  "Display the icons of files in a Dired buffer."
  (vscode-icons-dired--remove-all-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (dired-move-to-filename nil)
        (let ((file (dired-get-filename 'relative 'noerror)))
          (when file
            (let* ((icon (cond ((member file '("." ".."))
                                (vscode-icons-default-dir-icon))
                               ((file-directory-p file)
                                (or (vscode-icons-icon-for-dir file)
                                    (vscode-icons-default-dir-icon)))
                               (t (or (vscode-icons-icon-for-file file)
                                      (vscode-icons-default-file-icon)))))
                   (icon-str (propertize " " 'display icon))
                   (inhibit-read-only t))
              (vscode-icons-dired--add-overlay (dired-move-to-filename)
                                               (concat icon-str "\t"))))))
      (forward-line 1))))

(defun vscode-icons-dired--refresh-advice (fn &rest args)
  "Advice function for FN with ARGS."
  (let ((result (apply fn args))) ;; Save the result of the advised function
    (when vscode-icons-dired-mode
      (vscode-icons-dired--refresh))
    result)) ;; Return the result

(defun vscode-icons-dired--setup ()
  "Setup `vscode-icons-dired'."
  (when (derived-mode-p 'dired-mode)
    (setq-local tab-width 1)
    (advice-add 'dired-readin :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-revert :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-internal-do-deletions :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-insert-subdir :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-create-directory :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-do-redisplay :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-kill-subdir :around #'vscode-icons-dired--refresh-advice)
    (advice-add 'dired-do-kill-lines :around #'vscode-icons-dired--refresh-advice)
    (with-eval-after-load 'dired-narrow
      (advice-add 'dired-narrow--internal :around #'vscode-icons-dired--refresh-advice))
    (with-eval-after-load 'dired-subtree
      (advice-add 'dired-subtree-toggle :around #'vscode-icons-dired--refresh-advice))
    (with-eval-after-load 'wdired
      (advice-add 'wdired-abort-changes :around #'vscode-icons-dired--refresh-advice))
    (vscode-icons-dired--refresh)))

(defun vscode-icons-dired--teardown ()
  "Functions used as advice when redisplaying buffer."
  (advice-remove 'dired-readin #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-revert #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-internal-do-deletions #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-narrow--internal #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-subtree-toggle #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-insert-subdir #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-do-kill-lines #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-create-directory #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-do-redisplay #'vscode-icons-dired--refresh-advice)
  (advice-remove 'dired-kill-subdir #'vscode-icons-dired--refresh-advice)
  (advice-remove 'wdired-abort-changes #'vscode-icons-dired--refresh-advice)
  (vscode-icons-dired--remove-all-overlays))

;;;###autoload
(define-minor-mode vscode-icons-dired-mode
  "Display vscode-icons icon for each files in a Dired buffer."
  :lighter " vscode-icons-dired-mode"
  (when (derived-mode-p 'dired-mode)
    (if vscode-icons-dired-mode
        (vscode-icons-dired--setup)
      (vscode-icons-dired--teardown))))

(provide 'vscode-icons-dired)
;;; vscode-icons-dired.el ends here
