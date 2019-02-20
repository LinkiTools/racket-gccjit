#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require "../gccjit/bindings.rkt")

;; ---------------------------------------------------------------------------------------------------

;; Tutorial
(define ctx (gcc_jit_context_acquire))
(gcc_jit_context_set_bool_option ctx 'GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE 0)

(define (create-code ctx)
  (define void-type
    (gcc_jit_context_get_type ctx 'GCC_JIT_TYPE_VOID))
  (define const-char-ptr-type
    (gcc_jit_context_get_type ctx 'GCC_JIT_TYPE_CONST_CHAR_PTR))
  (define param-name
    (gcc_jit_context_new_param ctx #false const-char-ptr-type "name"))
  (define func
    (gcc_jit_context_new_function ctx
                                  #false
                                  'GCC_JIT_FUNCTION_EXPORTED
                                  void-type
                                  "greet"
                                  (list param-name)
                                  1))
  (define param-format
    (gcc_jit_context_new_param ctx #false const-char-ptr-type "format"))
  (define printf-func
    (gcc_jit_context_new_function ctx
                                  #false
                                  'GCC_JIT_FUNCTION_IMPORTED
                                  (gcc_jit_context_get_type ctx 'GCC_JIT_TYPE_INT)
                                  "printf"
                                  (list param-format)
                                  1))



  (define block
    (gcc_jit_function_new_block func #false))

  (gcc_jit_block_add_eval
   block #false
   (gcc_jit_context_new_call ctx #false printf-func
                             (list (gcc_jit_context_new_string_literal ctx "hello %s\n")
                                   (gcc_jit_param_as_rvalue param-name))))

  (gcc_jit_block_end_with_void_return block #false))

(create-code ctx)
(define result (gcc_jit_context_compile ctx))
(define raw-greet-fn (gcc_jit_result_get_code result "greet"))
(define greet-fn (cast raw-greet-fn _pointer (_fun _string -> _void)))
(greet-fn "world")
(flush-output)
