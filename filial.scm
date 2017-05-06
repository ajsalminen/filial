#!/usr/bin/csi -s

(use utils)

(define mime_path "/etc/mime.types")
(define mailcap_path "/etc/mailcap")

;; Only process lines that contain mime definitions.
(define (process-line toplevel line)
  (let ((lineparts (string-split line)))
    (if (null? lineparts)
        lineparts
        (process-mime-definition toplevel lineparts))))

;; Check if the mimetype's top-level type is the one passed.
(define (check-mimetype toptype mimetype)
  (string= toptype (car (string-split mimetype "/"))
           ))

;; Return extensions for all matching mimetypes.
(define (process-mime-definition toptype lineparts)
  (if (check-mimetype toptype (car lineparts))
      (cdr lineparts)
      '()
      ))

;; Read file and create a single list of all extensions for the top level type.
(define (extensions toptype)
  (flatten
   (map
    (lambda (mimetype)
      (process-line
       toptype mimetype))
    (read-lines mime_path))))

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
