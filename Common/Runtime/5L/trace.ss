;;=========================================================================
;;  Tracing of Function Applications in the Debug Log
;;=========================================================================
;;  Handy code by Brian Campbell, with some later hacking by Eric Kidd.

(module trace (lib "lispish.ss" "5L")
  (require (lib "begin-var.ss" "5L"))
  
  (provide with-tracing
           set-trace-output-printer!
           format-result-values)
  
  (define *trace-output-fn*
    (lambda (str)
      (display "Tracing: ")
      (display str)
      (newline)))
  
  (define (set-trace-output-printer! fun)
    (set! *trace-output-fn* fun))
  
  (define-syntax with-values
    (syntax-rules []
      [(with-values [arglist expr] body ...)
       (call-with-values (lambda () expr) (lambda arglist body ...))]))
  
  (define *trace-depth* 0)

  (define (get-trace-prefix)
    (let loop [[depth *trace-depth*]]
      (if (= depth 0)
          ""
          (string-append "  " (loop (- depth 1))))))
  
  (define (format-result-values . results)
    (let [[out (open-output-string)]]
      (parameterize [[print-struct #t]]

        ;; Attempt to print the results tatsefully.
        (case (length results)
            
          ;; No results--a void function.
          [[0] (display "(values)" out)]
          
          ;; The normal case--a single return value.
          [[1] (write-object (car results) out)]
          
          ;; Multiple return values. 
          [else
           (display "(values" out)
           (let loop [[results results]]
             (unless (null? results)
               (display " " out)
               (write-object (car results) out)
               (loop (cdr results))))
           (display ")" out)]))
      (get-output-string out)))

  (define (trace-call name-of-f f . args)
    (let [[out (open-output-string)]]
      (parameterize [[print-struct #t]]
        (display (get-trace-prefix) out)
        (display ">>> (" out)
      
        ;; Print the function name, and perhaps the value if it might
        ;; be informative.
        (display name-of-f out)
        (unless (and (procedure? f) (symbol? name-of-f))
          (display ":" out)
          (write-object f out))
        
        ;; Print each argument.
        (let loop [[args args]]
          (unless (null? args)
            (display " " out)
            (write-object (car args) out)
            (loop (cdr args))))
        
        (display ")" out))
      (*trace-output-fn* (get-output-string out)))

    ;; f might return multiple values, so we'll use with-values to capture
    ;; them into the single variable 'results.'
    (with-values [results
                  ;; Bump up our trace depth so nested calls can indent nicely.
                  (fluid-let [[*trace-depth* (+ *trace-depth* 1)]]
                    ;; Call our function.
                    (apply f args))]
      (*trace-output-fn* (string-append (get-trace-prefix)
                                        ">>> -> "
                                        (apply format-result-values results)))
      
      ;; Actually return the result of f to our caller.
      (apply values results)))
  
  ;; The goal: With a with-tracing form, replace (#%app name . values)
  ;; with (#%app trace-call 'name name . values).  We do this using
  ;; let-syntax, which imposes certain limitations--namely, we can't
  ;; wrap with-tracing around a top-level defining form.
  ;;
  ;; We use #,(datum->syntax-object stx '#%app) instead of simply #%app
  ;; to name the syntax we're overriding, because if we don't, nothing
  ;; happens.  Brian, could you please explain this?
  (define-syntax (with-tracing stx)
    (syntax-case stx []
      [(with-tracing body ...)
       (quasisyntax/loc
        stx
        (let-syntax [[#,(datum->syntax-object stx '#%app)
                      (syntax-rules []
                        [(_ name . values)
                         (#%app trace-call 'name name . values)])]]
          (begin/var body ...)))]))

  ) ; end module