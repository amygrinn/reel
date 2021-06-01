;;; re.el --- Utilities for the remarkable tablet -*- lexical-binding: t -*-

;; Author: Tyler Grinn <<,,tylergrinn@gmail.com>
;; Package-Requires: ((emacs "27") (json "1.5"))
;; Version: 0.0.0
;; Keywords: utility remarkable
;; URL: https://github.com/tylergrinn/reel


;; This program is free software: you can redistribute it and/or modify
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
;;
;; A work in progress to provide emacs integration with the remarkable
;; tablet. The only functionality right now is creating template files
;; from an emacs instance.

;; * Deps

(require 'json)

;; * Customization

(defgroup reel nil
  "Utilities for the remarkable tablet."
  :group 'utility
  :prefix "reel-")

;; * User settings and variables

(defcustom reel-template-dir (concat
			      user-emacs-directory "reel/templates")
  "The location to save template files and update the
  `template.json' file"
  :type 'directory)

(defcustom reel-offset-width 18
  "Extra pixels surrounding your windows. Will be subtracted from
the total width of the frame. Edit this so that the final image
created is exactly 1404 pixels wide."
  :type 'integer)

(defcustom reel-offset-height 2
  "Extra pixels surrounding your windows. Will be subtracted from
the total height of the frame. Edit this so that the final image
created is exactly 1872 pixels tall."
  :type 'integer)
  
;; * Utility functions

(defun reel--screenshot (file type)
  "Save a screenshot of the current frame as an image."
  (let ((data (x-export-frames nil (intern type))))
	 (with-temp-file (concat file "." type)
	   (insert data))))

(defun reel--update-templates-json (name icon categories)
  "Updates the `templates.json' file in the `reel-template-dir'
with a new template"
  (let* ((template-file (concat reel-template-dir "templates.json"))
	 (templates-json (json-read-file template-file))
	 (templates (seq-filter
		     (lambda (template)
		       (not (string= name (alist-get 'name template))))
		     (alist-get 'templates templates-json))))
    (setf (alist-get 'templates templates-json)
	  (append templates 
		  `(((name . ,name)
		     (filename . ,name)
		     (iconCode . ,icon)
		     (categories . ,categories)))))
    (with-temp-file template-file
      (insert (json-encode templates-json))
      (json-pretty-print-buffer))))

(defun reel--exwm-finish-hook ()
  "If using exwm, make the emacs instance appear as a floating
window in order to control frame size"
  (call-interactively #'exwm-input-release-keyboard)
  (exwm-floating-toggle-floating)
  (remove-hook 'exwm-manage-finish-hook #'reel--exwm-finish-hook))

(defun reel--save-template (&optional name)
  "Save the current frame as a remarkable template"
  (interactive)
  (let* ((name (or name (read-string "Template name: ")))
	 (file (concat reel-template-dir name))
	 (categories (vconcat (split-string (read-string "Categories (space-separated): ")))))
    (reel--screenshot file "svg")
    (reel--screenshot file "png")
    (reel--update-templates-json name "" categories)))


;; * Minor mode

(define-minor-mode reel-template-mode
  "Globally enable the key `C-c C-c' to save the current frame as a
remarkable template"
  :global t
  :keymap `((,(kbd "C-c C-c") . (lambda () (interactive) (reel--save-template) (kill-emacs))))
  (when reel-template-mode
    (setq frame-resize-pixelwise t)
    (set-frame-position nil 0 0)
    (set-frame-size nil
		    (- 1404 reel-offset-width)
		    (- 1872 reel-offset-height) t)
    (setq-default mode-line-format nil)
    (setq-default cursor-type nil)
    (message "Creating new remarkable template. Type `C-c C-c' to
	     finish and save")))

;; * Remarkable utilities


(defun reel-create-template ()
  "Create a new emacs instance with the exact size needed for the
remarkable tablet. In this new frame, the mode line will be
disabled and the global minor mode `reel-template-mode' will be
enabled which will take over `C-c C-c' to save the template
files."
  (interactive)
  (if (frame-parameter (selected-frame) 'exwm-active)
      (add-hook 'exwm-manage-finish-hook
		#'reel--exwm-finish-hook))
  (start-process-shell-command
   "reel-template-builder" nil
   (concat invocation-directory invocation-name
	   " --eval '(reel-template-mode)'")))

;;; re.el ends here
