#lang web-server
(require web-server/servlet-env
         web-server/http/response-structs
         net/http-client
         net/head
         web-server/http/json
         json)

;; https://en.wikipedia.org/api/rest_v1/page/random/summary

(define (build-wikipedia-query keyword) keyword)

(define (query-wikipedia)
  (let-values ([(status headers port)
                (http-sendrecv
                 "en.wikipedia.org"
                 "https://en.wikipedia.org/api/rest_v1/page/summary/Sweet_potato"
                 #:ssl? #t
                 #:version "1.1"
                 )])
    (read-json port)))

(define (get-summary s) (hash-ref s 'extract))

(define (summary-to-list s) (string-split s "."))

(define (build-response summary is-split)
  (if is-split
      (response/jsexpr (summary-to-list summary))
      (response/jsexpr summary)))

(define (is-split req)
  (let ([binds (request-bindings req)])
    (if (exists-binding? 'split binds)
        (match (extract-binding/single 'split binds)
          ["true" #t]
          ["false" #f]
          [_ #f])
        #f)))

(define (start req)
  (start
   (send/suspend
    (lambda (k-url)
      (let ([summary (get-summary (query-wikipedia))]
            [is-split (is-split req)])
        (build-response summary is-split))))))

;; Change port
(serve/servlet start
               #:stateless? #t
               #:command-line? #t
               #:servlet-path "/")
