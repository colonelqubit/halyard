(module tags (lib "lispish.ss" "5L")

  (require (lib "kernel.ss" "5L"))

  (define (insert-def name type line)
    (call-5l-prim 'ScriptEditorDBInsertDef name type line))

  (define (maybe-insert-def name type)
    (let [[sym (syntax-object->datum name)]]
      (when (symbol? sym)
        (insert-def sym type (syntax-line name)))))

  (define (form-name stx)
    (syntax-case stx ()
      [(name . body)
       (let [[datum (syntax-object->datum #'name)]]
         (if (symbol? datum)
             datum
             #f))]
      [anything-else
       #f]))
  
  (define (process-definition stx)
    (case (form-name stx)
      [[module]
       (syntax-case stx ()
         [(module name language . body)
          (for-each process-definition (syntax->list #'body))]
         [anything-else #f])]
      [[begin]
       (syntax-case stx ()
         [(begin . body)
          (for-each process-definition (syntax->list #'body))]
         [anything-else #f])]
      [[define]
       (syntax-case stx ()
         [(define (name . args) . body)
          (maybe-insert-def #'name 'function)]
         [(define name . body)
          (maybe-insert-def #'name 'variable)]
         [anything-else #f])]
      [else
       #f]))

  (define (extract-definitions file-path)
    (call-with-input-file file-path
      (lambda (port)
        (define (next)
          (read-syntax file-path port))
        (port-count-lines! port)
        (let recurse [[stx (next)]]
          (unless (eof-object? stx)
            (process-definition stx)
            (recurse (next)))))))

  (set-extract-definitions-fn! extract-definitions))