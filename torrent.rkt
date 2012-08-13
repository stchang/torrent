#lang racket

(define VIP-IMG "vip.gif")
(define TRUSTED-IMG "trusted.png")
(define PROGRAM "transmission-gtk")

(define (trusted? s) (or (string=? s VIP-IMG) (string=? s TRUSTED-IMG)))

(define arg
  (string-join (vector->list (current-command-line-arguments)) "%20"))

(define url (string-append "http://thepiratebay.se/search/" arg "/0/7/0"))

(define wget-args (string-append "-U Mozilla -qO- " url))

(define src
  (with-output-to-string
    (lambda () (system (string-append "wget " wget-args)))))

(define pat (pregexp (string-join (list "\"magnet\\:.*?\""
                                        "<td align=\"right\">[[:digit:]]*"
                                        VIP-IMG
                                        TRUSTED-IMG) "|")))
;; xs will be either:
;; 1) magnet link
;; 2) vip.gif or trusted.png
;; 3) # seeders
;; 4) # leechers
;;    OR
;; 1) magnet link
;; 2) # seeders
;; 3) # leechers
;; we only download in the first case
(define (dl-torrent t)
  (system (string-append PROGRAM " " t)))
(let LOOP
    ([xs (for/list ([s (regexp-match* pat src)])
           (string-trim s "<td align=\"right\">"))])
  (when (not (null? xs))
    (if (trusted? (second xs)) ;; must be trusted seeder
        (when (> (string->number (third xs)) 100) ;; must be over 100 seeders
          (dl-torrent (first xs)))
        (when (> (length xs) 3) (LOOP (cdddr xs))))))