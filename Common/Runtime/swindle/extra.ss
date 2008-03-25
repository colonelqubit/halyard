(module extra (lib "turbo.ss" "swindle")

;;> This module defines some additional useful functionality which requires
;;> Swindle.

(require (lib "clos.ss" "swindle"))

;;; ---------------------------------------------------------------------------
;;; A convenient `defstruct'

;; This makes it possible to create MzScheme structs using Swindle's `main' and
;; keyword arguments.

(define struct-to-slot-names (make-hash-table))

(hash-table-put! struct-to-slot-names <struct> '())

(add-method initialize (method ((s <struct>) initargs) ???))

(define (struct-type->class* stype maker slots)
  (let* ((this (struct-type->class stype))
         (superslots (let ((s (class-direct-supers this)))
                       (and (pair? s) (null? (cdr s))
                            (hash-table-get
                             struct-to-slot-names (car s) (thunk #f))))))
    (when superslots
      (when (some (lambda (x) (memq x superslots)) slots)
        (error 'defstruct "cannot redefine slot names"))
      (let ((allslots (append superslots slots)))
        (hash-table-put! struct-to-slot-names this slots)
        (add-method allocate-instance
          (let ((???s (build-list (length allslots) (lambda _ ???))))
            (method ((class = this)) (maker . ???s))))
        (add-method initialize
          (let ((none "-")
                (keys (build-list
                       (length slots)
                       (lambda (n) (list (symbol-append ': (nth slots n)) n))))
                (setter! (4th (call-with-values
                                  (thunk (struct-type-info stype)) list))))
            (method ((obj this) initargs)
              (for-each (lambda (k)
                          (let ((v (getarg initargs (1st k) none)))
                            (unless (eq? none v)
                              (setter! obj (2nd k) v))))
                        keys)
              (call-next-method))))))
    this))

;;>> (defstruct <struct-name> ([super]) slot ...)
;;>   This is just a Swindle-style syntax for one of
;;>     (define-struct struct-name (slot ...) (make-inspector))
;;>     (define-struct (struct-name super) (slot ...) (make-inspector))
;;>   with an additional binding of <struct-name> to the Swindle class that
;;>   is computed by `struct-type->class'.  The `(make-inspector)' is needed
;;>   to make this a struct that we can access information on.  Note that in
;;>   method specifiers, the `struct:foo' which is defined by
;;>   `define-struct' can be used just like `<foo>'.  What all this means is
;;>   that you can use MzScheme structs if you just want Swindle's generic
;;>   functions, but use built in structs that are more efficient since they
;;>   are part of the implementation.  For example:
;;>
;;>     => (defstruct <foo> () x y)
;;>     => <foo>
;;>     #<primitive-class:foo>
;;>     => (defmethod (bar (x <foo>)) (foo-x x))
;;>     => (bar (make-foo 1 2))
;;>     1
;;>     => (defmethod (bar (x struct:foo)) (foo-x x))
;;>     => (bar (make-foo 3 4))
;;>     3
;;>     => (generic-methods bar)
;;>     (#<method:bar:foo>)
;;>     => (defstruct <foo2> (foo) z)
;;>     => (bar (make-foo2 10 11 12))
;;>     10
;;>
;;>   To make things even easier, the super-struct can be written using a
;;>   "<...>" syntax which will be stripped, and appropriate methods are
;;>   added to `allocate-instance' and `initialize' so structs can be built
;;>   using keywords:
;;>
;;>     => (defstruct <foo3> (<foo>) z)
;;>     => (foo-x (make <foo3> :z 3 :y 2 :x 1))
;;>     1
;;>     => (foo3-z (make <foo3> :z 3 :y 2 :x 2))
;;>     3
;;>
;;>   The `<struct-name>' identifier *must* be of this form -- enclosed in
;;>   "<>"s.  This restriction is due to the fact that defining an MzScheme
;;>   struct `foo', makes `foo' bound as a syntax object to something that
;;>   cannot be used in any other way.
(defsyntax* (defstruct stx)
  (define <>-re (regexp "^<(.*)>$"))
  (define (<>-id? id)
    (and (identifier? id) (regexp-match <>-re (symbol->string (syntax-e id)))))
  (define (doit name super slots)
    (let* ((str (regexp-replace <>-re (symbol->string (syntax-e name)) "\\1"))
           (name-sans-<> (datum->syntax-object name (string->symbol str) name))
           (struct:name (datum->syntax-object
                         name (string->symbol (concat "struct:" str)) name))
           (make-struct (datum->syntax-object
                         name (string->symbol (concat "make-" str)) name))
           (super (and super (datum->syntax-object
                              super (string->symbol
                                     (regexp-replace
                                      <>-re (symbol->string (syntax-e super))
                                      "\\1"))
                              super))))
      (quasisyntax/loc stx
        (begin
          (define-struct #,(if super #`(#,name-sans-<> #,super) name-sans-<>)
            #,slots (make-inspector))
          (define #,name
            (struct-type->class* #,struct:name #,make-struct '#,slots))))))
  (syntax-case stx ()
    ((_ name (s) slot ...) (<>-id? #'name) (doit #'name #'s #'(slot ...)))
    ((_ name ( ) slot ...) (<>-id? #'name) (doit #'name #f  #'(slot ...)))))

;;; ---------------------------------------------------------------------------
;;; Convenient macros

(defsyntax process-with-slots
  (syntax-rules ()
    ((_ obj () (bind ...) body ...)
     (letsubst (bind ...) body ...))
    ((_ obj ((id slot) slots ...) (bind ...) body ...)
     (process-with-slots
      obj (slots ...) (bind ... (id (slot-ref obj slot))) body ...))
    ((_ obj (id slots ...) (bind ...) body ...)
     (process-with-slots
      obj (slots ...) (bind ... (id (slot-ref obj 'id))) body ...))))

;;>> (with-slots obj (slot ...) body ...)
;;>   Evaluate the body in an environment where each `slot' is defined as a
;;>   symbol-macro that accesses the corresponding slot value of `obj'.
;;>   Each `slot' is either an identifier `id' which makes it stand for
;;>   `(slot-ref obj 'id)', or `(id slot)' which makes `id' stand for
;;>   `(slot-ref obj 'slot)'.
(defsubst* (with-slots obj (slot ...) body0 body ...)
  (process-with-slots obj (slot ...) () body0 body ...))

(defsyntax process-with-accessors
  (syntax-rules ()
    ((_ obj () (bind ...) body ...)
     (letsubst (bind ...) body ...))
    ((_ obj ((id acc) accs ...) (bind ...) body ...)
     (process-with-accessors
      obj (accs ...) (bind ... (id (acc obj))) body ...))
    ((_ obj (id accs ...) (bind ...) body ...)
     (process-with-accessors
      obj (accs ...) (bind ... (id (id obj))) body ...))))

;;>> (with-accessors obj (accessor ...) body ...)
;;>   Evaluate the body in an environment where each `accessor' is defined
;;>   as a symbol-macro that accesses `obj'.  Each `accessor' is either an
;;>   identifier `id' which makes it stand for `(id obj)', or
;;>   `(id accessor)' which makes `id' stand for `(accessor obj);.
(defsubst* (with-accessors obj (acc ...) body0 body ...)
  (process-with-accessors obj (acc ...) () body0 body ...))

;;; ---------------------------------------------------------------------------
;;; An "as" conversion operator.

;;>> (as class obj)
;;>   Converts `obj' to an instance of `class'.  This is a convenient
;;>   generic wrapper around Scheme conversion functions (functions that
;;>   look like `foo->bar'), but can be used for other classes too.
(defgeneric* as (class object))

(defmethod (as (c <class>) (x <top>))
  (if (instance-of? x c)
    x
    (error 'as "can't convert ~e -> ~e; given: ~e." (class-of x) c x)))

;;>> (add-as-method from-class to-class op ...)
;;>   Adds a method to `as' that will use the function `op' to convert
;;>   instances of `from-class' to instances of `to-class'.  More operators
;;>   can be used which will make this use their composition.  This is used
;;>   to initialize `as' with the standard Scheme conversion functions.
(define* (add-as-method from to . op)
  (let ((op (apply compose op)))
    (add-method as (method ((c = to) (x from)) (op x)))))

;; Add Scheme primitives.
(add-as-method <symbol>   <string>  symbol->string)
(add-as-method <string>   <symbol>  string->symbol)
(add-as-method <exact>    <inexact> exact->inexact)
(add-as-method <inexact>  <exact>   inexact->exact)
(add-as-method <number>   <string>  number->string)
(add-as-method <string>   <number>  string->number)
(add-as-method <char>     <integer> char->integer)
(add-as-method <integer>  <char>    integer->char)
(add-as-method <string>   <list>    string->list)
(add-as-method <list>     <string>  list->string)
(add-as-method <vector>   <list>    vector->list)
(add-as-method <list>     <vector>  list->vector)
(add-as-method <number>   <integer> inexact->exact round)
(add-as-method <rational> <integer> inexact->exact round)
(add-as-method <struct>   <vector>  struct->vector)
(add-as-method <string>   <regexp>  regexp)
(add-as-method <regexp>   <string>  object-name)
;; Some weird combinations
(add-as-method <symbol>   <number>  string->number symbol->string)
(add-as-method <number>   <symbol>  string->symbol number->string)
(add-as-method <struct>   <list>    vector->list struct->vector)

;;; ---------------------------------------------------------------------------
;;; Recursive equality.

;;>> (equals? x y)
;;>   A generic that compares `x' and `y'.  It has an around method that
;;>   will stop and return `#t' if the two arguments are `equal?'.  It is
;;>   intended for user-defined comparison between any instances.
(defgeneric* equals? (x y))

(defaroundmethod (equals? (x <top>) (y <top>))
  ;; check this first in all cases
  (or (equal? x y) (call-next-method)))

(defmethod (equals? (x <top>) (y <top>))
  ;; the default is false - the around method returns #t if they're equal?
  #f)

(defmethod (equals? (x <list>) (y <list>))
  (cond ((and (null? x) (null? y))
         #t)
        ((or (null? x) (null? y))
         #f)
        (else
         (and (equals? (car x) (car y))
              (equals? (cdr x) (cdr y))))))

;;>> (add-equals?-method class pred?)
;;>   Adds a method to `equals?' that will use the given `pred?' predicate
;;>   to compare instances of `class'.
(define* (add-equals?-method class pred?)
  (add-method equals? (method ((x class) (y class)) (pred? x y))))

;;>> (class+slots-equals? x y)
;;>   This is a predicate function (not a generic function) that will
;;>   succeed if `x' and `y' are instances of the same class, and all of
;;>   their corresponding slots are `equals?'.  This is useful as a quick
;;>   default for comparing simple classes (but be careful and avoid
;;>   circularity problems).
(define* (class+slots-equals? x y)
  (let ((xc (class-of x)) (yc (class-of y)))
    (and (eq? xc yc)
         (every (lambda (s)
                  (equals? (slot-ref x (car s)) (slot-ref y (car s))))
                (class-slots xc)))))

;;>> (make-equals?-compare-class+slots class)
;;>   Make `class' use `class+slots-equals?' for comparison with `equals?'.
(define* (make-equals?-compare-class+slots class)
  (add-equals?-method class class+slots-equals?))

;;; ---------------------------------------------------------------------------
;;; Generic addition for multiple types.

;;>> (add x ...)
;;>   A generic addition operation, initialized for some Scheme types
;;>   (numbers (+), lists (append), strings (string-append), symbols
;;>   (symbol-append), procedures (compose), and vectors).  It dispatches
;;>   only on the first argument.
(defgeneric* add (x . more))

;;>> (add-add-method class op)
;;>   Add a method to `add' that will use `op' to add objects of class
;;>   `class'.
(define* (add-add-method c op)
  ;; dispatch on first argument
  (add-method add (method ((x c) . more) (apply op x more))))

(add-add-method <number>    +)
(add-add-method <list>      append)
(add-add-method <string>    string-append)
(add-add-method <symbol>    symbol-append)
(add-add-method <procedure> compose)

(defmethod (add (v <vector>) . more)
  ;; long but better than vectors->lists->append->vectors
  (let* ((len (apply + (map vector-length (cons v more))))
         (vec (make-vector len)))
    (let loop ((i 0) (v v) (vs more))
      (dotimes (j (vector-length v))
        (set! (vector-ref vec (+ i j)) (vector-ref v j)))
      (unless (null? vs) (loop (+ i (vector-length v)) (car vs) (cdr vs))))
    vec))

;;; ---------------------------------------------------------------------------
;;; Generic len for multiple types.

;;>> (len x)
;;>   A generic length operation, initialized for some Scheme types (lists
;;>   (length), strings (string-length), vectors (vector-length)).
(defgeneric* len (x))

;;>> (add-len-method class op)
;;>   Add a method to `len' that will use `op' to measure objects length for
;;>   instances of `class'.
(define* (add-len-method c op)
  (add-method len (method ((x c)) (op x))))

(add-len-method <list>   length)
(add-len-method <string> string-length)
(add-len-method <vector> vector-length)

;;; ---------------------------------------------------------------------------
;;; Generic ref for multiple types.

;;>> (ref x indexes...)
;;>   A generic reference operation, initialized for some Scheme types and
;;>   instances.  Methods are predefined for lists, vectors, strings,
;;>   objects, hash-tables, boxes, promises, parameters, and namespaces.
(defgeneric* ref (x . indexes))

;;>> (add-ref-method class op)
;;>   Add a method to `ref' that will use `op' to reference objects of class
;;>   `class'.
(define* (add-ref-method c op)
  (add-method ref (method ((x c) . indexes) (op x . indexes))))

(add-ref-method <list>       list-ref)
(add-ref-method <vector>     vector-ref)
(add-ref-method <string>     string-ref)
(add-ref-method <object>     slot-ref)
(add-ref-method <hash-table> hash-table-get)
(add-ref-method <box>        unbox)
(add-ref-method <promise>    force)
(defmethod (ref (p <parameter>) . _) (p))
(defmethod (ref (n <namespace>) . args)
  (parameterize ((current-namespace n))
    (apply namespace-variable-value args)))

;;; ---------------------------------------------------------------------------
;;; Generic set-ref! for multiple types.

;;>> (put! x v indexes)
;;>   A generic setter operation, initialized for some Scheme types and
;;>   instances.  The new value comes first so it is possible to add methods
;;>   to specialize on it.  Methods are predefined for lists, vectors,
;;>   strings, objects, hash-tables, boxes, parameters, and namespaces.
(defgeneric* put! (x v . indexes))

;;>> (set-ref! x indexes... v)
;;>   This syntax will just translate to `(put! x v indexes...)'.  It makes
;;>   it possible to make `(set! (ref ...) ...)' work with `put!'.
(defsyntax* (set-ref! stx)
  (syntax-case stx ()
    ((_ x i ...)
     (let* ((ris  (reverse (syntax->list #'(i ...))))
            (idxs (reverse! (cdr ris)))
            (val  (car ris)))
       (quasisyntax/loc stx
         (put! x #,val #,@(datum->syntax-object #'(i ...) idxs #'(i ...))))))))

;;>> (add-put!-method class op)
;;>   Add a method to `ref' that will use `op' to reference objects of class
;;>   `class'.
(define* (add-put!-method c op)
  (add-method put! (method ((x c) v . indexes) (op x v . indexes))))

(define (put!-arg typename args)
  (if (or (null? args) (pair? (cdr args)))
   (if (null? args)
     (error 'put! "got no index for a ~a argument" typename)
     (error 'put! "got more than one index for a ~a argument ~e"
            typename args))
   (car args)))

(defmethod (put! (l <list>) x . i_)
  (list-set! l (put!-arg '<list> i_) x))
(defmethod (put! (v <vector>) x . i_)
  (vector-set! v (put!-arg '<vector> i_) x))
(defmethod (put! (s <string>) (c <char>) . i_)
  (string-set! s (put!-arg '<string> i_) c))
(defmethod (put! (o <object>) x . s_)
  (slot-set! o (put!-arg '<object> s_) x))
(defmethod (put! (h <hash-table>) x . k_)
  (if (null? k_)
    (error 'put! "got no index for a <hash-table> argument")
    (hash-table-put! h (car k_) x)))
(add-put!-method <box> set-unbox!)
(defmethod (put! (p <parameter>) x . _)
  (if (null? _)
    (p x)
    (error 'put! "got extraneous indexes for a <parameter> argument")))
(defmethod (put! (n <namespace>) x . v_)
  (if (null? v_)
    (error 'put! "got no index for a <namespace> argument")
    (parameterize ((current-namespace n))
      (apply namespace-set-variable-value! (car v_) x
             (if (null? (cdr v_)) '() (list (cadr v_)))))))

;;; ---------------------------------------------------------------------------
;;>>... Generic-based printing mechanism

;;>> *print-level*
;;>> *print-length*
;;>   These parameters control how many levels deep a nested data object
;;>   will print, and how many elements are printed at each level.  `#f'
;;>   means no limit.  The effect is similar to the corresponding globals in
;;>   Lisp.  Only affects printing of container objects (like lists, vectors
;;>   and structures).
(define* *print-level*  (make-parameter 6))
(define* *print-length* (make-parameter 20))

(define orig-write-handler   (port-write-handler   (current-error-port)))
(define orig-display-handler (port-display-handler (current-error-port)))

;;>> (print-object obj esc? port)
;;>   Prints `obj' on `port' using the above parameters -- the effect of
;;>   `esc?' being true is to use a `write'-like printout rather than a
;;>   `display'-like printout when it is false.  Primitive Scheme values are
;;>   printed normally, Swindle objects are printed using the un-`read'-able
;;>   "#<...>" sequence unless a method that handles them is defined.  For
;;>   this printout, objects with a `name' slot are printed using that name
;;>   (and their class's name).
;;>
;;>   Warning: this is the method used for user-interaction output, errors
;;>   etc.  Make sure you only define reliable methods for it.
(defgeneric* print-object (object esc? port))

(defmethod (print-object o esc? port)
  (orig-display-handler "#" port)
  (orig-display-handler (class-name (class-of o)) port))

(defmethod (print-object (o <builtin>) esc? port)
  ((if esc? orig-write-handler orig-display-handler) o port))

(define printer:too-deep "#?#")
(define printer:too-long "...")

(defmethod (print-object (o <improper-list>) esc? port)
  (cond
   ((null? o) (orig-display-handler "()" port))
   ((and (pair? (cdr o)) (null? (cddr o))
         (memq (car o) '(quote quasiquote unquote unquote-splicing
                               syntax quasisyntax unsyntax unsyntax-splicing)))
    (orig-display-handler (case (car o)
                            ((quote)             "'")
                            ((quasiquote)        "`")
                            ((unquote)           ",")
                            ((unquote-splicing)  ",@")
                            ((syntax)            "#'")
                            ((quasisyntax)       "#`")
                            ((unsyntax)          "#,")
                            ((unsyntax-splicing) "#,@"))
                          port)
    (print-object (cadr o) esc? port))
   ((eq? (*print-level*) 0)
    (orig-display-handler printer:too-deep port))
   (else
    (orig-display-handler "(" port)
    (if (eq? (*print-length*) 0)
      (orig-display-handler printer:too-long port)
      (parameterize ((*print-level* (sub1 (or (*print-level*) 0))))
        (print-object (car o) esc? port)
        (do ((o (cdr o) (if (pair? o) (cdr o) '()))
             (n (sub1 (or (*print-length*) 0)) (sub1 n)))
            ((or (null? o)
                 (and (zero? n)
                      (begin (orig-display-handler " " port)
                             (orig-display-handler printer:too-long port)
                             #t))))
          (if (pair? o)
            (begin (orig-display-handler " " port)
                   (print-object (car o) esc? port))
            (begin (orig-display-handler " . " port)
                   (print-object o esc? port))))))
    (orig-display-handler ")" port))))

(defmethod (print-object (o <vector>) esc? port)
  (cond ((eq? (*print-level*) 0)
         (orig-display-handler printer:too-deep port))
        ((zero? (vector-length o)) (orig-display-handler "#()" port))
        (else (orig-display-handler "#(" port)
              (if (eq? (*print-length*) 0)
                (orig-display-handler printer:too-long port)
                (parameterize ((*print-level* (sub1 (or (*print-level*) 0))))
                  (print-object (vector-ref o 0) esc? port)
                  (let ((len (if (*print-length*)
                               (min (vector-length o) (*print-length*))
                               (vector-length o))))
                    (do ((i 1 (add1 i))) ((>= i len))
                      (orig-display-handler " " port)
                      (print-object (vector-ref o i) esc? port))
                    (when (< len (vector-length o))
                      (orig-display-handler " " port)
                      (orig-display-handler printer:too-long port)))))
              (orig-display-handler ")" port))))

(define <>-re (regexp "^<(.*)>$"))
(define (name-sans-<> name)
  (cond ((string? name) (regexp-replace <>-re name "\\1"))
        ((symbol? name) (regexp-replace <>-re (symbol->string name) "\\1"))
        ((eq? ??? name) "???")
        (else name)))

;; Take care of all <object>s with a `name' slot
(defmethod (print-object (o <object>) esc? port)
  (let* ((c  (class-of o))
         (cc (class-of c))
         ((name x) (name-sans-<> (slot-ref x 'name))))
    (if (and (assq 'name (class-slots c)) (assq 'name (class-slots cc)))
      (begin (orig-display-handler "#<" port)
             (orig-display-handler (name c) port)
             (orig-display-handler ":" port)
             (orig-display-handler (name o) port)
             (orig-display-handler ">" port))
      (call-next-method))))

;;>> (print-object-with-slots obj esc? port)
;;>   This is a printer function that can be used for classes where the
;;>   desired output shows slot values.  Note that it is a simple function,
;;>   which should be embedded in a method that is to be added to
;;>   `print-object'.
(define* (print-object-with-slots o esc? port)
  (if (eq? (*print-level*) 0)
    (orig-display-handler printer:too-deep port)
    (let ((class (class-of o)))
      (orig-display-handler "#<" port)
      (orig-display-handler (name-sans-<> (class-name class)) port)
      (orig-display-handler ":" port)
      (parameterize ((*print-level* (sub1 (or (*print-level*) 0))))
        (do ((s (class-slots class) (cdr s))
             (n (or (*print-length*) -1) (sub1 n)))
            ((or (null? s)
                 (and (zero? n)
                      (begin (orig-display-handler " " port)
                             (orig-display-handler printer:too-long port)))))
          (let ((val (slot-ref o (caar s))))
            (if (eq? ??? val)
              (set! n (add1 n))
              (begin (orig-display-handler " " port)
                     (orig-display-handler (caar s) port)
                     (orig-display-handler "=" port)
                     (print-object val esc? port))))))
      (orig-display-handler ">" port))))

;; Add a hook to make <class> so it will initialize a printer if given
(defmethod :after (initialize (c <class>) initargs)
  (let ((printer (or (getarg initargs :printer)
                     (and (getarg initargs :auto) #t))))
    (when printer
      (when (eq? #t printer) (set! printer print-object-with-slots))
      (add-method print-object
                  (method ((x c) esc? port) (printer x esc? port))))))

;;>> (display-object obj [port])
;;>> (write-object obj [port])
;;>   Used to display and write an object using `print-object'.  Used as the
;;>   corresponding output handler functions.
(define* (display-object obj &optional (port (current-output-port)))
  (print-object obj #f port))
(define* (write-object   obj &optional (port (current-output-port)))
  (print-object obj #t port))
;;>> (object->string obj [esc? = #t])
;;>   Convert the given `obj' to a string using its printed form.
(define* (object->string obj &optional (esc? #t))
  (with-output-to-string (thunk (write-object obj))))

;; Hack these to echo
(*echo-display-handler* display-object)
(*echo-write-handler* write-object)

;;>> (install-swindle-printer)
;;>   In MzScheme, output is configurable on a per-port basis.  Use this
;;>   function to install Swindle's `display-object' and `write-object' on
;;>   the current output and error ports whenever they are changed
;;>   (`swindle' does that on startup).  This makes it possible to see
;;>   Swindle values in errors, when using `printf' etc.
(define* (install-swindle-printer)
  (global-port-print-handler write-object)
  (port-display-handler (current-output-port) display-object)
  (port-display-handler (current-error-port)  display-object)
  (port-write-handler   (current-output-port) write-object)
  (port-write-handler   (current-error-port)  write-object))

;;; ---------------------------------------------------------------------------
;;>>... Simple matching

;;>> match-failure
;;>   The result for a matcher function application that failed.  You can
;;>   return this value from a matcher function in a <matcher> so the next
;;>   matching one will get invoked.
(define* match-failure "failure")

;;>> (matching? matcher value)
;;>   The `matcher' argument is a value of any type, which is matched
;;>   against the given `value'.  For most values matching means being equal
;;>   (using `equals?')  to, but there are some exceptions: class objects
;;>   are tested with `instance-of?', functions are used as predicates,
;;>   literals are used with equals?, pairs are compared recursively and
;;>   regexps are used with regexp-match.
(define* (matching? matcher value)
  (cond ((class? matcher)    (instance-of? value matcher))
        ((function? matcher) (matcher value))
        ((pair? matcher)     (and (pair? value)
                                  (matching? (car matcher) (car value))
                                  (matching? (cdr matcher) (cdr value))))
        ;; handle regexps - the code below relies on returning this result
        ((regexp? matcher)   (and (string? value)
                                  (regexp-match matcher value)))
        (else (equals? matcher value))))

;;>> (matcher pattern body ...)
;;>   This creates a matcher function, using the given `pattern'.  The
;;>   pattern specification has a complex syntax as follows:
;;>   - simple values (not symbols) are compared with `matching?' above;
;;>   - :x                 keywords are also used as literal values;
;;>   - *                  is a wildcard that always succeeds;
;;>   - (lambda ...)       use the resulting closure value (for predicates);
;;>   - (quote ...)        use the contents as a simple;
;;>   - (quasiquote ...)   same;
;;>   - (V := P)           assign the variable V to the value matched by P;
;;>   - V                  for a variable V, is the same as (V := *);
;;>   - (! E)              evaluate E, use the result it as a literal value;
;;>   - (!! E)             evaluate E, continue matching only if it is true;
;;>   - (V when E)         same as (and V (!! E));
;;>   - (and P ...)        combine the matchers with and, can bind any
;;>                        variables in all parts;
;;>   - (or P ...)         combine the matchers with or, bound variables are
;;>                        only from the successful form;
;;>   - (if A B C)         same as (or (and A B) C);
;;>   - (F => P)           continue matching P with (F x) (where is x is the
;;>                        current matched object);
;;>   - (V :: P ...)       same as (and (! V) P...), useful for class forms
;;>                        like (<class> :: (foo => f) ...);
;;>   - (make <class> ...) if the value is an instance of <class>, then
;;>                        continue by the `...' part which is a list of
;;>                        slot names and patterns -- a slot name is either
;;>                        :foo or 'foo, and the pattern will be matched
;;>                        against the contents of that slot in the original
;;>                        <class> instance;
;;>   - ???                matches the unspecified value (`???' in tiny-clos)
;;>   - (regexp R)         convert R to a regexp and use that to match
;;>                        strings;
;;>   - (regexp R S ...)   like the above, but continue matching the result
;;>                        with `(S ...)' so it can bind variables to the
;;>                        result (something like `(regexp "a(x?)b" x y)'
;;>                        will bind x to the regexp-match result);
;;>   - (...)              other lists - match the elements of a list
;;>                        recursively (can use a dot suffix for a "rest"
;;>                        arguments).
;;>   Note that normal function application cannot be used since they will
;;>   be taken as list-nested matchers.
(defsyntax (make-matcher-form stx)
  (define (re r)
    ;; Note: this inserts the _literal_ regexp in the code if it is a string.
    (if (string? (syntax-e r))
      (regexp (syntax-e r))
      #`(regexp #,r)))
  (syntax-case stx
      (* ??? := ! !! when and or if => :: make regexp quote quasiquote lambda)
    ;; * is a wildcard
    ((_ x * body)               #'body)
    ((_ x ??? body)             #'(if (matching? ??? x) body match-failure))
    ;; (V := P) - assign the variable V to the value matched by P
    ((_ x (v := p) body)        #'(let ((v x)) (_ v p body)))
    ;; V => (V := *) if V is a symbol
    ((_ x v body) (and (identifier? #'v) (not (syntax-keyword? #'v)))
                                #'(_ x (v := *) body))
    ;; (! E) => evaluate E and use it as a simple value
    ((_ x (! v) body)           #'(if (matching? v x) body match-failure))
    ;; (!! E) => evaluate E and succeed only if it is true
    ((_ x (!! e))               #'(if e body match-failure))
    ;; (V when E) => (and V (!! E))
    ((_ x (v when e) body)      #'(_ x (and v (!! e)) body))
    ;; and/or
    ((_ x (and)   body)         #'body)
    ((_ x (or)    body)         #'match-failure)
    ((_ x (and p) body)         #'(_ x p body))
    ((_ x (or  p) body)         #'(_ x p body))
    ((_ x (and p1 p2 ...) body) #'(_ x p1 (_ x (and p2 ...) body)))
    ((_ x (or  p1 p2 ...) body) #'(let ((tmp (_ x p1 body)))
                                    (if (eq? tmp match-failure)
                                      (_ x (or p2 ...) body)
                                      tmp)))
    ;; (if A B C) => (or (and A B) C)
    ((_ x (if a b c) body)      #'(_ x (or (and a b) c) body))
    ;; (F => P) - continue matching P with (F x)
    ((_ x (f => p) body)        #'(let ((v (f x))) (_ v p body)))
    ;; (V :: ...) => (and (! V) ...) - good for (<class> :: (foo => f) ...)
    ((_ x (v :: . p) body)      #'(_ x (and (! v) . p) body))
    ;; (make <class> :slotname p ...) - match on slots of the given class
    ((_ x (make class initarg+vals ...) body)
     #`(let ((obj x))
         (if (instance-of? obj class)
           #,(let loop ((av #'(initarg+vals ...)))
               (syntax-case av (quote quasiquote)
                 ((key p more ...) (syntax-keyword? #'key)
                  (let* ((s (symbol->string (syntax-e #'key)))
                         (s (datum->syntax-object
                             #'key
                             (string->symbol (substring s 1 (string-length s)))
                             #'key)))
                    #`(_ (slot-ref obj '#,s) p #,(loop #'(more ...)))))
                 (('key p more ...)
                  #`(_ (slot-ref obj 'key) p #,(loop #'(more ...))))
                 (() #'body)))
           match-failure)))
    ;; (regexp R) => use R as a regexp (matching? handles it)
    ((_ x (regexp r) body)      #`(if (matching? #,(re #'r) x)
                                    body match-failure))
    ;; (regexp R S...) => like the above, but continue matching on S... so it
    ;; can bind variables to the result.
    ((_ x (regexp r . s) body)  #`(let ((tmp (matching? #,(re #'r) x)))
                                    (if tmp (_ tmp s body) match-filure)))
    ;; literal lists
    ((_ x 'v body)              #'(if (matching? 'v x) body match-failure))
    ((_ x `v body)              #'(if (matching? `v x) body match-failure))
    ((_ x (lambda a ...) body)  #'(if (matching? (lambda a ...) x)
                                                       body match-failure))
    ;; simple lists
    ((_ x (a . b) body)         #'(if (pair? x)
                                    (let ((hd (car x)) (tl (cdr x)))
                                      (_ hd a (_ tl b body)))
                                    match-failure))
    ((_ x () body)              #'(if (null? x) body match-failure))
    ;; other literals (keywords and non-symbols)
    ((_ x v body)               #'(if (matching? v x) body match-failure))))
(defsubst* (matcher args body ...)
  (lambda marg (make-matcher-form marg args (begin body ...))))

;; Matching similar to `cond'
;;>> (match x (pattern expr ...) ...)
;;>   This is similar to a cond statement but each clause starts with a
;;>   pattern, possibly binding variables for its body.  It also handles
;;>   `else' as a last clause.
(defsyntax match-internal
  (syntax-rules (else)
    ((_ x) match-failure)
    ((_ x (else body0 body ...)) (begin body0 body ...))
    ((_ x (pattern body0 body ...) clause ...)
     (let ((m (make-matcher-form x pattern (begin body0 body ...))))
       (if (eq? m match-failure) (match x clause ...) m)))))
(defsubst* (match x clause ...)
  (let ((v x)) (match-internal v clause ...)))

;;>> <matcher>
;;>   A class similar to a generic function, that holds matcher functions
;;>   such as the ones created by the `matcher' macro.  It has three slots:
;;>   `name', `default' (default value), and `matchers' (a list of matcher
;;>   functions).
(defentityclass* <matcher> (<generic>)
  (name     :initarg :name     :initvalue '-anonymous-)
  (default  :initarg :default  :initvalue #f)
  (matchers :initarg :matchers :initvalue '()))

;; Set the entity's proc
'(defmethod (initialize (matcher <matcher>) initargs)
  (set-instance-proc!
   matcher
   (lambda args
     (let loop ((matchers (slot-ref matcher 'matchers)))
       (if (null? matchers)
         (let ((default (slot-ref matcher 'default)))
           (if default
             (default . args)
             (error (slot-ref matcher 'name) "no match found.")))
         (let ((r (apply (car matchers) args)))
           (if (eq? r match-failure)
             (loop (cdr matchers))
             r)))))))

;;; Add a matcher - normally at the end, with add-matcher0 at the beginning
(define (add-matcher matcher m)
  (slot-set! matcher 'matchers
             (append! (slot-ref matcher 'matchers) (list m))))
(define (add-matcher0 matcher m)
  (slot-set! matcher 'matchers
             (cons m (slot-ref matcher 'matchers))))

(defsyntax (defmatcher-internal stx)
  (syntax-case stx ()
    ((_ adder name args body ...)
     (with-syntax ((matcher-make (syntax/loc stx (matcher args body ...))))
       (if (or
            ;; not enabled
            (not (syntax-e
                  ((syntax-local-value #'-defmethod-create-generics-))))
            ;; defined symbol or second module binding
            (identifier-binding #'name)
            ;; local definition -- don't know which is first => no define
            (eq? 'lexical (syntax-local-context)))
         (syntax/loc stx (adder name matcher-make))
         ;; top-level or first module binding
         (syntax/loc stx
           (define name ; trick: try using exising generic
             (let ((m (or (no-errors name) (make <matcher> :name 'name))))
               (adder m matcher-make)
               m))))))))

;;>> (defmatcher (name pattern) body ...)
;;>> (defmatcher0 (name pattern) body ...)
;;>   These macros define a matcher (if not defined yet), create a matcher
;;>   function and add it to the matcher (either at the end or at the
;;>   beginning).
(defsyntax* (defmatcher stx)
  (syntax-case stx ()
    ((_ (name . args) body0 body ...) (identifier? #'name)
     #'(defmatcher-internal add-matcher name args body0 body ...))
    ((_ name args body0 body ...) (identifier? #'name)
     #'(defmatcher-internal add-matcher name args body0 body ...))))
(defsyntax* (defmatcher0 stx)
  (syntax-case stx ()
    ((_ (name . args) body0 body ...) (identifier? #'name)
     #'(defmatcher-internal add-matcher0 name args body0 body ...))
    ((_ name args body0 body ...) (identifier? #'name)
     #'(defmatcher-internal add-matcher0 name args body0 body ...))))

;;; ---------------------------------------------------------------------------
;;>>... An amb macro
;;> This is added just because it is too much fun too miss.  To learn about
;;> `amb', look for it in the Help Desk, in the "Teach Yourself Scheme in
;;> Fixnum Days" on-line manual.

(define amb-fail (make-parameter #f))
(define (initialize-amb-fail)
  (amb-fail (thunk (error 'amb "tree exhausted"))))
(initialize-amb-fail)

;;>> (amb expr ...)
;;>   Execute forms in a nondeterministic way: each form is tried in
;;>   sequence, and if one fails then evaluation continues with the next.
;;>   `(amb)' fails immediately.
(defsubst* (amb expr ...)
  (let ((prev-amb-fail (amb-fail)))
    (let/cc sk
      (let/cc fk
        (amb-fail (thunk (amb-fail prev-amb-fail) (fk 'fail)))
        (sk expr)) ...
      (prev-amb-fail))))

;;>> (amb-assert cond)
;;>   Asserts that `cond' is true, fails otherwise.
(define* (amb-assert bool) (unless bool ((amb-fail))))

;;>> (amb-collect expr)
;;>   Evaluate expr, using amb-fail repeatedly until all options are
;;>   exhausted and returns the list of all results.
(defsubst* (amb-collect e)
  (let ((prev-amb-fail (amb-fail))
        (results '()))
    (when (let/cc k
            (amb-fail (thunk (k #f)))
            (let ((v e)) (push! v results) (k #t)))
      ((amb-fail)))
    (amb-fail prev-amb-fail)
    (reverse! results)))

;;; ---------------------------------------------------------------------------
;;>>... Very basic UI - works also in console mode
;;> The following defines some hacked UI functions that works using MrEd GUI
;;> if it is available, or the standard error and input ports otherwise.
;;> The check is done by looking for a GUI global binding.

;;>> *dialog-title*
;;>   This parameter defines the title used for the hacked UI interface.
(define* *dialog-title* (make-parameter "Swindle Message"))

;;>> (message fmt-string arg ...)
;;>   Like `printf' with a prefix title, or using a message dialog box.
(define* (message str . args)
  (let ((msg (format str . args)))
    (if (namespace-defined? 'message-box)
      ((namespace-variable-value 'message-box) (*dialog-title*) msg)
      (echo :>e :s- "<<<" (*dialog-title*) ": " msg ">>>")))
  (void))

(define (first-non-ws-char str idx)
  (and (< idx (string-length str))
       (let ((c (string-ref str idx)))
         (if (memq c '(#\space #\tab #\newline))
           (first-non-ws-char str (add1 idx))
           c))))

(define (ui-question str args prompt positive-result msg-style
                     positive-char negative-char)
  (let ((msg (apply format str args)))
    (if (namespace-defined? 'message-box)
      (eq? ((namespace-variable-value 'message-box)
            (*dialog-title*) msg #f msg-style)
           positive-result)
      (begin (echo :>e :n- :s- (*dialog-title*) ">>> " msg " " prompt " ")
             (let loop ()
               (let ((inp (first-non-ws-char (read-line) 0)))
                 (cond ((char-ci=? inp positive-char) #t)
                       ((char-ci=? inp negative-char) #f)
                       (else (loop)))))))))

;;>> (ok/cancel? fmt-string arg ...)
;;>> (yes/no? fmt-string arg ...)
;;>   These functions are similar to `message', but they are used to ask an
;;>   "ok/cancel" or a "yes/no" question.  They return a boolean.
(define* (ok/cancel? str . args)
  (ui-question str args "Ok/Cancel" 'ok '(ok-cancel) #\o #\c))
(define* (yes/no? str . args)
  (ui-question str args "Yes/No" 'yes '(yes-no) #\y #\n))

)