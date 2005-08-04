;;;; -*- lisp -*-

(in-package :it.bese.arnesi)

;;;; * Portable lexical environment access

;;;; ** OpenMCL

#+openmcl
(defun environment-p (environment)
  (subtypep (class-of environment) 'ccl::lexical-environment))

#+openmcl
(defun lexical-variables (environment)
  (loop
     for env = environment
          then (ccl::lexenv.parent-env env)
     while (and env
                (not (ccl::istruct-typep env 'ccl::definition-environment)))
     for vars = (ccl::lexenv.variables env)
     when (listp vars)
     append (mapcar (lambda (var)
                      ;; ccl::var-name is a macro, se we can't do #'ccl::var-name directly
                      (ccl::var-name var))
                    vars)))  

;fixme 
#+openmcl
(defun lexical-functions (environment)
  (declare (ignore environment))
  nil)

;;;; ** SBCL
 
#+sbcl
(defun environment-p (environment)
  (subtypep (class-of environment) (find-class 'sb-kernel:lexenv)))

#+sbcl
(defun lexical-variables (environment)
  (loop
     for var-spec in (sb-c::lexenv-vars environment)
     when (and (atom (cdr var-spec))
               (not (sb-c::lambda-var-ignorep (cdr var-spec))))
       collect (car var-spec)))

#+sbcl
(defun lexical-functions (environment)
  (mapcar #'first (sb-c::lexenv-funs environment)))

;;;; ** CMUCL

#+cmu
(defun environment-p (environment)
  (subtypep (class-of environment) (find-class 'c::lexenv)))

#+cmu
(defun lexical-variables (environment)
  (loop
     for var-spec in (c::lexenv-variables environment)
     ;; variable refs are (NAME . LAMBDA-VAR), we want to void
     ;; symbol-macrolets which are (NAME SYSTEM:MACRO . EXPANSION)
     when (and (atom (cdr var-spec))
               ;; don't return ignored vars
               (not (c::lambda-var-ignorep (cdr var-spec))))
       collect (car var-spec)))

#+cmu
(defun lexical-functions (environment)
  (loop
     for func-spec in (c::lexenv-functions environment)
     ;; flet and labels function look like ((FLET ACTUAL-NAME) . STUFF)
     if (and (consp (first func-spec))
             (member (car (first func-spec)) '(flet labels)))
       collect (second (first func-spec))
     ;; macrolets look like (NAME SYSTEM:MACRO . STUFF)
     else if (and (consp (cdr func-spec))
                  (eql 'system:macro (second func-spec)))
       ;; except that we don't return macros for now
       do (progn)
     ;; if we get here we're confused :(
     else
       do (error "Sorry, don't know how to handle the lexcial function spec ~S."
                 func-spec)))




