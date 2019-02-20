#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require ffi/unsafe
         ffi/unsafe/define
          ffi/unsafe/alloc)
;; ---------------------------------------------------------------------------------------------------

;;  GCC JIT library import and definer creation
(define-ffi-definer define-gccjit (ffi-lib "libgccjit"))

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

;; Enums
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
;;
;; Function declarations
;;
(define-gccjit gcc_jit_context_get_type
  (_fun _gcc-jit-context _gcc-jit-types -> _gcc-jit-type))

; Releasers
(define-gccjit gcc_jit_context_release
  (_fun _gcc-jit-context -> _void)
  #:wrap (deallocator))
(define-gccjit gcc_jit_result_release
  (_fun _gcc-jit-result -> _void)
  #:wrap (deallocator))

; Context acquisition
; You will always need to acquire one of these
(define-gccjit gcc_jit_context_acquire
  (_fun -> (_or-null _gcc-jit-context))
  #:wrap (allocator gcc_jit_context_release))

(define-gccjit gcc_jit_context_set_bool_option
  (_fun _gcc-jit-context _gcc-jit-set-bool-option _int -> _void))
(define-gccjit gcc_jit_context_compile
  (_fun _gcc-jit-context -> (_or-null _gcc-jit-result))
  #:wrap (allocator gcc_jit_result_release))
(define-gccjit gcc_jit_context_new_param
  (_fun _gcc-jit-context (_or-null _gcc-jit-location) _gcc-jit-type _string -> _gcc-jit-param))
(define-gccjit gcc_jit_context_new_function
  (_fun _gcc-jit-context
        (_or-null _gcc-jit-location)
        _gcc-jit-function-kind
        _gcc-jit-type
        _string
        [_int = (length params)]
        [params : (_list i _gcc-jit-param)]
        _int
        -> _gcc-jit-function))
(define-gccjit gcc_jit_context_new_string_literal
  (_fun _gcc-jit-context _string -> _gcc-jit-rvalue))
(define-gccjit gcc_jit_function_new_block
  (_fun _gcc-jit-function _string -> _gcc-jit-block))
(define-gccjit gcc_jit_block_as_object
  (_fun _gcc-jit-block -> _gcc-jit-object))
(define-gccjit gcc_jit_block_get_function
  (_fun _gcc-jit-block -> _gcc-jit-function))
(define-gccjit gcc_jit_param_as_rvalue
  (_fun _gcc-jit-param -> _gcc-jit-rvalue))
(define-gccjit gcc_jit_block_add_eval
  (_fun _gcc-jit-block (_or-null _gcc-jit-location) _gcc-jit-rvalue -> _void))
(define-gccjit gcc_jit_block_end_with_void_return
  (_fun _gcc-jit-block (_or-null _gcc-jit-location) -> _void))
(define-gccjit gcc_jit_result_get_code
  (_fun _gcc-jit-result _string -> _pointer))
(define-gccjit gcc_jit_context_new_call
  (_fun _gcc-jit-context
        (_or-null _gcc-jit-location)
        _gcc-jit-function
        [_int = (length args)]
        [args : (_list i _gcc-jit-rvalue)]
        -> _gcc-jit-rvalue))
