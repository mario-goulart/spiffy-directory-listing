(module spiffy-directory-listing
  (spiffy-directory-listing

   ;; parameters
   list-dotfiles?
   format-listing
   directory-listing-page
   directory-listing-css
   directory-listing-doctype
   directory-listing-title
   list-directory)

(import chicken scheme srfi-1 extras spiffy files posix data-structures ports)
(require-extension intarweb html-tags html-utils spiffy)

(define list-dotfiles? (make-parameter #f))

(define list-directory
  (make-parameter
   (lambda (path)
     (sort (directory (make-pathname (root-path) path)
                      (list-dotfiles?))
           string<?))))

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
               (list (<a> href: remote-file (maybe-append-slash remote-file))
                     (file-size local-file)
                     (seconds->string (file-modification-time local-file)))))
           listing)))))

(define directory-listing-css (make-parameter #f))

(define directory-listing-doctype (make-parameter ""))

(define directory-listing-title
  (make-parameter
   (lambda (path)
     (string-append "Index of " path))))

(define directory-listing-page
  (make-parameter
   (lambda (path contents)
     (html-page
      (string-append
       (<h2> "Index of " (<code> path) ":")
       (<p> (<a> href: (or (pathname-directory path) path)
                 "Go to parent directory"))
       contents)
      css: (directory-listing-css)
      doctype: (directory-listing-doctype)
      title: ((directory-listing-title) path)))))

(define (spiffy-directory-listing path)
  (let* ((file-listing ((format-listing) path ((list-directory) path)))
         (page ((directory-listing-page) path file-listing)))
    (with-headers `((content-type text/html)
                    (content-length ,(string-length page)))
      (lambda ()
        (write-logged-response)
        (unless (eq? 'HEAD (request-method (current-request)))
          (display page (response-port (current-response))))))))

) ; end module
