#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require ffi/unsafe
         ffi/unsafe/define
          ffi/unsafe/alloc)
;; ---------------------------------------------------------------------------------------------------

(define-ffi-definer define-gccjit (ffi-lib "libgccjit"))

(define _gcc-jit-context (_cpointer/null 'gcc-jit-context))
(define _gcc-jit-type (_cpointer 'gcc-jit-type))
(define _gcc-jit-result (_cpointer/null 'gcc-jit-result))
(define _gcc-jit-param (_cpointer 'gcc-jit-param))
(define _gcc-jit-location (_cpointer 'gcc-jit-location))
(define _gcc-jit-function (_cpointer 'gcc-jit-function))
(define _gcc-jit-rvalue (_cpointer 'gcc-jit-rvalue))
(define _gcc-jit-block (_cpointer 'gcc-jit-block))
(define _gcc-jit-object (_cpointer 'gcc-jit-object))

(define _gcc-jit-types
  (_enum '(GCC_JIT_TYPE_VOID
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
           GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE)))

(define _gcc-jit-set-bool-option
  (_enum '(GCC_JIT_BOOL_OPTION_DEBUGINFO
           GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
           GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
           GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE
           GCC_JIT_BOOL_OPTION_DUMP_SUMMARY
           GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING
           GCC_JIT_BOOL_OPTION_SELFCHECK_GC
           GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES
           GCC_JIT_NUM_BOOL_OPTIONS)))

(define _gcc-jit-function-kind
  (_enum '(GCC_JIT_FUNCTION_EXPORTED
           GCC_JIT_FUNCTION_INTERNAL
           GCC_JIT_FUNCTION_IMPORTED
           GCC_JIT_FUNCTION_ALWAYS_INLINE)))

(define-gccjit gcc_jit_context_get_type (_fun _gcc-jit-context _gcc-jit-types -> _gcc-jit-type))
(define-gccjit gcc_jit_context_release (_fun _gcc-jit-context -> _void)
  #:wrap (deallocator))
(define-gccjit gcc_jit_result_release (_fun _gcc-jit-result -> _void)
  #:wrap (deallocator))
(define-gccjit gcc_jit_context_acquire (_fun -> (_or-null _gcc-jit-context))
  #:wrap (allocator gcc_jit_context_release))
(define-gccjit gcc_jit_context_set_bool_option (_fun _gcc-jit-context _gcc-jit-set-bool-option _int -> _void))
(define-gccjit gcc_jit_context_compile (_fun _gcc-jit-context -> (_or-null _gcc-jit-result))
  #:wrap (allocator gcc_jit_result_release))
(define-gccjit gcc_jit_context_new_param (_fun _gcc-jit-context (_or-null _gcc-jit-location) _gcc-jit-type _string -> _gcc-jit-param))
(define-gccjit gcc_jit_context_new_function (_fun _gcc-jit-context (_or-null _gcc-jit-location) _gcc-jit-function-kind _gcc-jit-type _string [_int = (length params)] [params : (_list i _gcc-jit-param)] _int -> _gcc-jit-function))
(define-gccjit gcc_jit_context_new_string_literal (_fun _gcc-jit-context _string -> _gcc-jit-rvalue))
(define-gccjit gcc_jit_function_new_block (_fun _gcc-jit-function _string -> _gcc-jit-block))
(define-gccjit gcc_jit_block_as_object (_fun _gcc-jit-block -> _gcc-jit-object))
(define-gccjit gcc_jit_block_get_function (_fun _gcc-jit-block -> _gcc-jit-function))
(define-gccjit gcc_jit_param_as_rvalue (_fun _gcc-jit-param -> _gcc-jit-rvalue))
(define-gccjit gcc_jit_block_add_eval (_fun _gcc-jit-block (_or-null _gcc-jit-location) _gcc-jit-rvalue -> _void))
(define-gccjit gcc_jit_block_end_with_void_return (_fun _gcc-jit-block (_or-null _gcc-jit-location) -> _void))
(define-gccjit gcc_jit_result_get_code (_fun _gcc-jit-result _string -> _pointer))
(define-gccjit gcc_jit_context_new_call
  (_fun _gcc-jit-context (_or-null _gcc-jit-location) _gcc-jit-function [_int = (length args)]  [args : (_list i _gcc-jit-rvalue)] -> _gcc-jit-rvalue))

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
    (gcc_jit_context_new_function ctx #false 'GCC_JIT_FUNCTION_EXPORTED void-type "greet" (list param-name) 1))
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
