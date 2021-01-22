(module wikipedia racket
  (provide (all-defined-out))

  (require web-server/servlet-env
           web-server/http/response-structs
           net/http-client
           net/head
           web-server/http/json
           json
           net/url-string
           racket/match)

  (define (build-wikipedia-query random? article)
    (if random?
        (string->url "https://en.wikipedia.org/api/rest_v1/page/random/summary")
        (string->url "https://en.wikipedia.org/api/rest_v1/page/summary/Sweet_potato")))

  ;; url should be
  (define (query-wikipedia [url (build-wikipedia-query #t "")])
    (http-sendrecv
     "en.wikipedia.org"
     (url->string url)
     #:ssl? #t
     #:version "1.1"
     ))

  (define (get-summary s) (hash-ref s 'extract))

  (define (summary-to-list s) (string-split s ".")))
