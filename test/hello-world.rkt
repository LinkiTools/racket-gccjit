#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require "../gccjit/bindings.rkt"
         (only-in ffi/unsafe cast _pointer _fun _string _void))

;; ---------------------------------------------------------------------------------------------------

;; Tutorial
(define ctx (gcc-jit-context-acquire))
(gcc-jit-context-set-bool-option ctx 'GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE 0)

(define (create-code ctx)
  (define void-type
    (gcc-jit-context-get-type ctx 'GCC_JIT_TYPE_VOID))
  (define const-char-ptr-type
    (gcc-jit-context-get-type ctx 'GCC_JIT_TYPE_CONST_CHAR_PTR))
  (define param-name
    (gcc-jit-context-new-param ctx #false const-char-ptr-type "name"))
  (define func
    (gcc-jit-context-new-function ctx
                                  #false
                                  'GCC_JIT_FUNCTION_EXPORTED
                                  void-type
                                  "greet"
                                  (list param-name)
                                  1))
  (define param-format
    (gcc-jit-context-new-param ctx #false const-char-ptr-type "format"))
  (define printf-func
    (gcc-jit-context-new-function ctx
                                  #false
                                  'GCC_JIT_FUNCTION_IMPORTED
                                  (gcc-jit-context-get-type ctx 'GCC_JIT_TYPE_INT)
                                  "printf"
                                  (list param-format)
                                  1))



  (define block
    (gcc-jit-function-new-block func ""))

  (gcc-jit-block-add-eval
   block
   #false
   (gcc-jit-context-new-call ctx #false printf-func
                             (list (gcc-jit-context-new-string-literal ctx "hello %s\n")
                                   (gcc-jit-param-as-rvalue param-name))))

  (gcc-jit-block-end-with-void-return block #false))

(create-code ctx)
(define result (gcc-jit-context-compile ctx))
(define raw-greet-fn (gcc-jit-result-get-code result "greet"))
(define greet-fn (cast raw-greet-fn _pointer (_fun _string -> _void)))
(greet-fn "world")
(flush-output)
