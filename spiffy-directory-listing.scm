(module spiffy-directory-listing
  (spiffy-directory-listing

   ;; parameters
   list-dotfiles?
   format-listing
   directory-listing-page
   directory-listing-css
   directory-listing-doctype
   directory-listing-title
   list-directory
   sxml->html
   encode-path)

(import scheme)
(cond-expand
  (chicken-4
   (import chicken)
   (use data-structures extras files ports posix srfi-1 sxml-transforms)
   (use (only srfi-14 char-set-complement char-set-delete))
   (use (only uri-common uri-encode-string char-set:uri-unreserved))
   (use intarweb spiffy))
  (chicken-5
   (import (chicken base)
           (chicken file)
           (chicken file posix)
           (chicken pathname)
           (chicken port)
           (chicken sort)
           (chicken time posix))
   (import (only srfi-14 char-set-complement char-set-delete))
   (import (only uri-common uri-encode-string char-set:uri-unreserved))
   (import intarweb spiffy sxml-transforms))
  (else (error "Unsupported CHICKEN version")))

(define list-dotfiles? (make-parameter #f))

(define list-directory
  (make-parameter
   (lambda (path)
     (sort (directory (make-pathname (root-path) path)
                      (list-dotfiles?))
           string<?))))

(define sxml->html
  (make-parameter
   (let ((rules `((literal *preorder* . ,(lambda (t b) b))
                  . ,universal-conversion-rules*)))
     (lambda (sxml)
       (with-output-to-string
         (lambda ()
           (SRV:send-reply (pre-post-order* sxml rules))))))))

(define (tabularize data)
  (let ((body
         (map (lambda (line)
                (cons 'tr
                      (list (map (lambda (cell) `(td ,cell)) line))))
              data)))
    (cons 'table (list body))))

(define format-listing
  (make-parameter
   (lambda (path listing)
     (tabularize
      (map (lambda (file)
             (let* ((local-file (make-pathname (list (root-path) path)
                                               file))
                    (remote-file (pathname-strip-directory
                                  (make-pathname path file)))
                    (dir? (directory? local-file))
                    (maybe-append-slash
                     (lambda (path)
                       (if dir?
                           (string-append path "/")
                           path))))
               `((a (@ (href ,(encode-path remote-file)))
                    ,(maybe-append-slash remote-file))
                 ,(file-size local-file)
                 ,(seconds->string (file-modification-time local-file)))))
           listing)))))

(define directory-listing-css (make-parameter #f))

(define directory-listing-doctype (make-parameter ""))

(define directory-listing-title
  (make-parameter
   (lambda (path)
     (string-append "Index of " path))))

(define (encode-path p)
  (let ((cs (char-set-delete (char-set-complement char-set:uri-unreserved) #\/)))
    (uri-encode-string p cs)))

(define directory-listing-page
  (make-parameter
   (lambda (path contents)
     `(,(directory-listing-doctype)
       (html
        (head
         (meta (@ (charset "utf-8")))
         (title ,((directory-listing-title) path))
         ,(if (directory-listing-css)
              `(link (@ (rel "stylesheet")
                        (href ,(directory-listing-css))
                        (type "text/css")))
              '()))
        (body
         (h2 "Index of " (code ,path) ":")
         (p (a (@ (href ,(encode-path (or (pathname-directory path) path))))
               "Go to parent directory"))
         ,contents))))))

(define (spiffy-directory-listing path)
  (let* ((file-listing ((format-listing) path ((list-directory) path)))
         (page ((sxml->html) ((directory-listing-page) path file-listing))))
    (with-headers `((content-type text/html)
                    (content-length ,(string-length page)))
      (lambda ()
        (write-logged-response)
        (unless (eq? 'HEAD (request-method (current-request)))
          (display page (response-port (current-response))))))))

) ; end module
