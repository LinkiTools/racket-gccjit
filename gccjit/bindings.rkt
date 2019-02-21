#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require (prefix-in c: racket/contract)
         ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         ffi/unsafe/define/conventions)

(provide
 (c:contract-out
  [gcc-jit-context-get-type
   (gcc-jit-context? gcc-jit-type-id? . c:-> . gcc-jit-type?)]
  [gcc-jit-context-acquire
   (c:-> gcc-jit-context?)]
  [gcc-jit-context-set-bool-option
   (gcc-jit-context? gcc-jit-set-bool-option? integer? . c:-> . void?)]
  [gcc-jit-context-compile
   (gcc-jit-context? . c:-> . (c:or/c #false gcc-jit-result?))]
  [gcc-jit-context-new-param
   (gcc-jit-context? (c:or/c #false gcc-jit-location?) gcc-jit-type? string? . c:-> . gcc-jit-param?)]
  [gcc-jit-context-new-function
   (gcc-jit-context? (c:or/c #false gcc-jit-location?) gcc-jit-function-kind? gcc-jit-type? string? (c:listof gcc-jit-param?) integer? . c:-> . gcc-jit-function?)]
  [gcc-jit-context-new-string-literal
   (gcc-jit-context? string? . c:-> . gcc-jit-rvalue?)]
  [gcc-jit-function-new-block
   (gcc-jit-function? string? . c:-> . gcc-jit-block?)]
  [gcc-jit-block-as-object
   (gcc-jit-block? . c:-> . gcc-jit-object?)]
  [gcc-jit-block-get-function
   (gcc-jit-block? . c:-> . gcc-jit-function?)]
  [gcc-jit-param-as-rvalue
   (gcc-jit-param? . c:-> . gcc-jit-rvalue?)]
  [gcc-jit-block-add-eval
   (gcc-jit-block? (c:or/c #false gcc-jit-location?) gcc-jit-rvalue? . c:-> . void?)]
  [gcc-jit-block-end-with-void-return
   (gcc-jit-block? (c:or/c #false gcc-jit-location?) . c:-> . void?)]
  [gcc-jit-result-get-code
   (gcc-jit-result? string? . c:-> . gcc-jit-code-pointer?)]
  [gcc-jit-context-new-call
   (gcc-jit-context? (c:or/c #false gcc-jit-location?) gcc-jit-function? (c:listof gcc-jit-rvalue?) . c:-> . gcc-jit-rvalue?)]))

;; ---------------------------------------------------------------------------------------------------

;;  GCC JIT library import and definer creation
(define-ffi-definer define-gccjit (ffi-lib "libgccjit")
  #:make-c-id convention:hyphen->underscore)

;; List of C types showing up in function declarations.
;; These are opaque types which we don't care about the internals
; hopefully what they represent if self explanatory
(define _gcc-jit-context  (_cpointer 'gcc-jit-context))
(define _gcc-jit-type     (_cpointer 'gcc-jit-type))
(define _gcc-jit-result   (_cpointer 'gcc-jit-result))
(define _gcc-jit-param    (_cpointer 'gcc-jit-param))
(define _gcc-jit-location (_cpointer 'gcc-jit-location))
(define _gcc-jit-function (_cpointer 'gcc-jit-function))
(define _gcc-jit-rvalue   (_cpointer 'gcc-jit-rvalue))
(define _gcc-jit-block    (_cpointer 'gcc-jit-block))
(define _gcc-jit-object   (_cpointer 'gcc-jit-object))

; This one is not really a gcc jit type but we use it
; to distinguish it from other pointers
(define _gcc-jit-code     (_cpointer 'gcc-jit-code-pointer))

;; Predicates for the tagged pointers above
(define (gcc-jit-context? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-context)))
(define (gcc-jit-type? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-type)))
(define (gcc-jit-result? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-result)))
(define (gcc-jit-param? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-param)))
(define (gcc-jit-location? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-location)))
(define (gcc-jit-function? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-function)))
(define (gcc-jit-rvalue? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-rvalue)))
(define (gcc-jit-block? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-block)))
(define (gcc-jit-object? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-object)))
(define (gcc-jit-code-pointer? x)
  (and (cpointer? x)
       (cpointer-has-tag? x 'gcc-jit-code-pointer)))


;; Enums
(define gcc-jit-types/values
  '(GCC_JIT_TYPE_VOID
    GCC_JIT_TYPE_VOID_PTR
    GCC_JIT_TYPE_BOOL
    GCC_JIT_TYPE_CHAR
    GCC_JIT_TYPE_SIGNED_CHAR
    GCC_JIT_TYPE_UNSIGNED_CHAR
    GCC_JIT_TYPE_SHORT
    GCC_JIT_TYPE_UNSIGNED_SHORT
    GCC_JIT_TYPE_INT
    GCC_JIT_TYPE_UNSIGNED_INT
    GCC_JIT_TYPE_LONG
    GCC_JIT_TYPE_UNSIGNED_LONG
    GCC_JIT_TYPE_LONG_LONG
    GCC_JIT_TYPE_UNSIGNED_LONG_LONG
    GCC_JIT_TYPE_FLOAT
    GCC_JIT_TYPE_DOUBLE
    GCC_JIT_TYPE_LONG_DOUBLE
    GCC_JIT_TYPE_CONST_CHAR_PTR
    GCC_JIT_TYPE_SIZE_T
    GCC_JIT_TYPE_FILE_PTR
    GCC_JIT_TYPE_COMPLEX_FLOAT
    GCC_JIT_TYPE_COMPLEX_DOUBLE
    GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE))
(define _gcc-jit-types (_enum gcc-jit-types/values))
(define (gcc-jit-type-id? x) (memq x gcc-jit-types/values))

(define gcc-jit-set-bool-option/values
  '(GCC_JIT_BOOL_OPTION_DEBUGINFO
    GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
    GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
    GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE
    GCC_JIT_BOOL_OPTION_DUMP_SUMMARY
    GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING
    GCC_JIT_BOOL_OPTION_SELFCHECK_GC
    GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES
    GCC_JIT_NUM_BOOL_OPTIONS))
(define _gcc-jit-set-bool-option
  (_enum gcc-jit-set-bool-option/values))
(define (gcc-jit-set-bool-option? x)
  (memq x gcc-jit-set-bool-option/values))

(define gcc-jit-function-kind/values
  '(GCC_JIT_FUNCTION_EXPORTED
    GCC_JIT_FUNCTION_INTERNAL
    GCC_JIT_FUNCTION_IMPORTED
    GCC_JIT_FUNCTION_ALWAYS_INLINE))
(define _gcc-jit-function-kind
  (_enum gcc-jit-function-kind/values))
(define (gcc-jit-function-kind? x)
  (memq x gcc-jit-function-kind/values))

;;
;; Function declarations
;;
(define-gccjit gcc-jit-context-get-type
  (_fun _gcc-jit-context _gcc-jit-types -> _gcc-jit-type))

; Releasers
(define-gccjit gcc-jit-context-release
  (_fun _gcc-jit-context -> _void)
  #:wrap (deallocator))
(define-gccjit gcc-jit-result-release
  (_fun _gcc-jit-result -> _void)
  #:wrap (deallocator))

; Context acquisition
; You will always need to acquire one of these
(define-gccjit gcc-jit-context-acquire
  (_fun -> (_or-null _gcc-jit-context))
  #:wrap (allocator gcc-jit-context-release))

(define-gccjit gcc-jit-context-set-bool-option
  (_fun _gcc-jit-context _gcc-jit-set-bool-option _int -> _void))
(define-gccjit gcc-jit-context-compile
  (_fun _gcc-jit-context -> (_or-null _gcc-jit-result))
  #:wrap (allocator gcc-jit-result-release))
(define-gccjit gcc-jit-context-new-param
  (_fun _gcc-jit-context (_or-null _gcc-jit-location) _gcc-jit-type _string -> _gcc-jit-param))
(define-gccjit gcc-jit-context-new-function
  (_fun _gcc-jit-context
        (_or-null _gcc-jit-location)
        _gcc-jit-function-kind
        _gcc-jit-type
        _string
        [_int = (length params)]
        [params : (_list i _gcc-jit-param)]
        _int
        -> _gcc-jit-function))
(define-gccjit gcc-jit-context-new-string-literal
  (_fun _gcc-jit-context _string -> _gcc-jit-rvalue))
(define-gccjit gcc-jit-function-new-block
  (_fun _gcc-jit-function _string -> _gcc-jit-block))
(define-gccjit gcc-jit-block-as-object
  (_fun _gcc-jit-block -> _gcc-jit-object))
(define-gccjit gcc-jit-block-get-function
  (_fun _gcc-jit-block -> _gcc-jit-function))
(define-gccjit gcc-jit-param-as-rvalue
  (_fun _gcc-jit-param -> _gcc-jit-rvalue))
(define-gccjit gcc-jit-block-add-eval
  (_fun _gcc-jit-block (_or-null _gcc-jit-location) _gcc-jit-rvalue -> _void))
(define-gccjit gcc-jit-block-end-with-void-return
  (_fun _gcc-jit-block (_or-null _gcc-jit-location) -> _void))
(define-gccjit gcc-jit-result-get-code
  (_fun _gcc-jit-result _string -> _gcc-jit-code))
(define-gccjit gcc-jit-context-new-call
  (_fun _gcc-jit-context
        (_or-null _gcc-jit-location)
        _gcc-jit-function
        [_int = (length args)]
        [args : (_list i _gcc-jit-rvalue)]
        -> _gcc-jit-rvalue))
