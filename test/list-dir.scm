;; access http://localhost:8080/dir

(import scheme)
(cond-expand
  (chicken-4
   (use spiffy spiffy-directory-listing))
  (chicken-5
   (import (chicken file)
           (chicken pathname))
   (import spiffy spiffy-directory-listing))
  (else (error "Unsupported CHICKEN version.")))

(unless (file-exists? "dir")
  (create-directory "dir")
  (create-directory (make-pathname "dir" "another dir [] with () special chars"))
  (create-directory (make-pathname "dir/another dir [] with () special chars" "subdir"))
  (with-output-to-file (make-pathname "dir" "1.txt") (cut display ""))
  (with-output-to-file (make-pathname "dir" "2.txt") (cut display "")))

(directory-listing-css "http://wiki.call-cc.org/chicken.css")
(directory-listing-title (lambda (path) (string-append "Listing " path)))

(directory-listing-page
 (lambda (path contents)
   `(,(directory-listing-doctype)
     (html
      (head
       (title ,((directory-listing-title) path))
       (link (@ (rel "stylesheet")
                (href ,(directory-listing-css))
                (type "text/css"))))
      (body
       (div (@ (id "content"))
            (h2 "Index of " (code ,path) ":")
            (p (a (@ (href ,(encode-path (or (pathname-directory path) path))))
                  "Go to parent directory"))
            ,contents))))))

(handle-directory spiffy-directory-listing)

(root-path ".")
(start-server)
