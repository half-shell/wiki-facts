#lang web-server
(require web-server/servlet-env
         web-server/http/response-structs
         net/http-client
         net/head
         web-server/http/json
         json
         net/url-string
         racket/match)
(require "wikipedia.rkt")
(require "http-utils.rkt")

(define (split? req)
  (let ([binds (request-bindings req)])
    (if (exists-binding? 'split binds)
        (match (extract-binding/single 'split binds)
          ["true" #t]
          ["false" #f]
          [_ #f])
        #f)))

(define (build-response summary split)
  (if split (response/jsexpr (summary-to-list summary))
      (response/jsexpr summary)))

(define (start req)
  (start
   (send/suspend
    (lambda (k-url)
      ;; TODO: we need to change this so we parse k-url first with let*, and then
      ;; have a comprehensive way of building wikipedia queries
      (let ([summary (get-summary (follow-response (lambda () (query-wikipedia))))])
        (build-response summary (split? req)))))))

;; Change port
(serve/servlet start
               #:stateless? #t
               #:command-line? #t
               #:servlet-path "/")
