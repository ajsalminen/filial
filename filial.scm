#!/usr/bin/csi -s

(use utils)

(define mime_path "/etc/mime.types")
(define mailcap_path "/etc/mailcap")

;; Only process lines that contain mime definitions.
(define (process-line toplevel line matching-definition? process-definition)
  (let ((lineparts (string-split line)))
    (if (< (length lineparts) 2)
        '()
        ((process-definition toplevel matching-definition?) lineparts))))

;; Check if the mimetype's top-level type is the one passed.
(define (check-top-mimetype toptype)
  (lambda (mimetype)
    (string= toptype (car (string-split mimetype "/"))
             )))

;; Check if the mimetype's type is the one passed.
(define (check-mimetype wanted-mimetype)
  (lambda (mimetype)
    (string= wanted-mimetype mimetype)
    ))

;; Check if the mimetype's type is the one of the passed.
(define (check-mimetype-list wanted-mimetype)
  (lambda (mimetype)
    (member mimetype wanted-mimetype)
    ))


;; Return extensions for all matching mimetypes.
(define (process-mime-definition toptype matching-definition?)
  (lambda (lineparts)
    (if ((matching-definition? toptype) (car lineparts))
        (cdr lineparts)
        '()
        )))

;; Return extensions for all matching mimetypes.
(define (process-mailcap-definition program matching-definition?)
  (lambda (lineparts)
    (if ((matching-definition? program) (car(cdr lineparts)))
        (string-drop-right (car lineparts) 1)
        '()
        )))


;; Read file and create a single list of all extensions for the top level type.
(define (process-config-file path toptype matching-definition? process-definition)
  (flatten
   (map
    (lambda (mimetype)
      (process-line
       toptype mimetype matching-definition? process-definition))
    (read-lines path))))

(define (extensions toptype)
  (let ((mailcap-result (process-config-file mailcap_path toptype check-mimetype process-mailcap-definition)))
    ( if (null? mailcap-result)
         (process-config-file mime_path toptype check-top-mimetype process-mime-definition)
         (process-config-file mime_path mailcap-result check-mimetype-list process-mime-definition)
         )))

;; Format the arguments for use with "find".
(define (generate-find-args extensions)
  (print (string-append " -iname *." (string-join
                                      extensions " -o -iname *."))))

;; Format the arguments for use with "grep".
(define (generate-grep-args extensions)
  (print (string-join
          extensions " --include=*." 'prefix)))

;; Format the arguments for use with the shell.
(define (generate-bash-args extensions)
  (format #t "*.@(~A)" (string-join
                        extensions "|")))

;; Format the arguments for use with the shell.
(define (generate-zsh-args extensions)
  (format #t "*.(~A)" (string-join
                       extensions "|")))


(define type-map '(("bash" generate-bash-args)
                   ("zsh" generate-zsh-args)
                   ("grep" generate-grep-args)
                   ("find" generate-find-args)
                   ("regex" generate-regex-args)
                   ("plain" generate-plain-args)))

(define wanted-args-type (car (command-line-arguments)))
(define wanted-files-type (car (cdr (command-line-arguments))))
(define function-to-call (car (cdr (assoc wanted-args-type type-map))))

((eval function-to-call) (extensions wanted-files-type))
