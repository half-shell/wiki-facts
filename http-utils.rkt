(module http-utils racket
  (provide (all-defined-out))

  (require web-server/servlet-env
           web-server/http/response-structs
           net/http-client
           net/head
           web-server/http/json
           json
           net/url-string
           racket/match)
  (require "wikipedia.rkt")

  ;; For now, we only need content & content-location
  ;; Maybe in the long run, having a way to parse all kind of headers might be useful
  (define (parse-headers headers)
    ;; TODO: Check if using #px here doesn't solve the need of only matching the first colon ":"
    (let ([h (map (lambda (h) (regexp-split #rx#": " h)) headers)])
      (make-hash h)))

  (define (get-status status)
    (car (regexp-match #px#"[[:digit:]]{3}" status)))

  ;; Given those two response headers, generate a location URL
  ;; #"location: ../summary/Alakamisy%2C_Antananarivo"
  ;; #"content-location: https://en.wikipedia.org/api/rest_v1/page/random/summary"
  (define (get-new-endpoint headers)
    (let ([location (bytes->string/utf-8 (car (hash-ref headers #"location")))]
          [content-location (bytes->string/utf-8 (car (hash-ref headers #"content-location")))])
      (combine-url/relative
       (string->url content-location) location)))

  ;; Function to follow 303 redirection from location & content-location
  ;; query-fn should be a function executing the query
  (define (follow-response query-fn)
    (let*-values ([(status headers port) (query-fn)]
                  [(parsed-headers) (parse-headers headers)]
                  [(status-code) (get-status status)])
      (if (bytes=? status-code #"303")
          ;; TODO: Abstract so we're only talking query here
          (follow-response  (lambda () (query-wikipedia (get-new-endpoint parsed-headers))))
          (read-json port)))))
