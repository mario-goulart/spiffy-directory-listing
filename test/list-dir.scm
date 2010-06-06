#!/usr/bin/awful

;; access http://localhost:8080/dir

(use awful html-utils html-tags spiffy spiffy-directory-listing)

(unless (file-exists? "dir")
  (create-directory "dir")
  (create-directory (make-pathname "dir" "another-dir"))
  (with-output-to-file (make-pathname "dir" "1.txt") (cut display ""))
  (with-output-to-file (make-pathname "dir" "2.txt") (cut display "")))

(directory-listing-css "http://wiki.call-cc.org/chicken.css")
(directory-listing-title (lambda (path) (string-append "Listing " path)))
(handle-directory spiffy-directory-listing)
