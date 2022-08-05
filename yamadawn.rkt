#lang racket/base

(require net/url
         racket/class
         racket/format
         racket/gui/base
         racket/port
         racket/string
         racket/system)

(define yt-dlp-update-spec-url
  (string->url "https://github.com/yt-dlp/yt-dlp/releases/latest/download/_update_spec"))

(define *yt-dlp-path* (simplify-path (find-executable-path "yt-dlp") #t))
(define *url* "")
(define *output-directory*
  (simplify-path
   (or (let ([dl-dir (build-path (find-system-path 'home-dir) "Downloads")])
         (and (eq? (file-or-directory-type dl-dir) 'directory)
              dl-dir))
       (find-system-path 'desk-dir)) #t))

(define (download-video)
  (when (not (equal? *url* ""))
    (define cmd
      (list (path->string *yt-dlp-path*)
            *url*
            "--paths" (path->string *output-directory*)))

    (log #:color "blue" (apply ~a #:separator " " ">" cmd))

    (with-input-from-string ""
      (lambda ()
        (apply system* cmd)
        (log "")))))

(define (fetch-latest-version)
  (define update-spec (get-pure-port yt-dlp-update-spec-url #:redirections 2))
  (let find-lock ()
    (define line (read-line update-spec))
    (cond [(eof-object? line) (error "Update spec not found")]
          [(and (>= (string-length line) 15)
                (equal? (substring line 0 5) "lock "))
           (car (string-split (substring line 5) " "))]
          [else (find-lock)])))

(define root-window
  (new frame%
       [label "yt-dlp"]
       [width 600]
       [height 600]
       [border 5]))

(define menu-bar
  (new menu-bar% [parent root-window]))

(define edit-menu
  (new menu%
       [label "Modifica"]
       [parent menu-bar]))
(append-editor-operation-menu-items edit-menu #f)
(for ([item (send edit-menu get-items)]
      [i '(0 1 2 3)])
  (send item delete))

(define frame
  (new vertical-pane%
       [parent root-window]
       [spacing 5]
       [alignment '(left top)]))

(define (validate-download)
  (send download-button enable
        (and (path? *output-directory*)
             (equal? (file-or-directory-type *output-directory*) 'directory)
             (> (string-length *url*) 0))))

(define url-field
  (new text-field%
       [parent frame]
       [label "URL "]
       [callback (lambda (self ev)
                   (set! *url* (send self get-value))
                   (validate-download))]))

(define output-directory-container
  (new horizontal-pane%
       [parent frame]
       [spacing 5]
       [stretchable-height #f]))

(define output-directory-message
  (new message%
       [parent output-directory-container]
       [label (or (and *output-directory* (path->string *output-directory*))
                  "Nessuna cartella di destinazione selezionata")]
       [stretchable-width #t]))

(define output-directory-select-button
  (new button%
       [parent output-directory-container]
       [label "Seleziona destinazione"]
       [callback
        (lambda (self ev)
          (define dir (get-directory "Seleziona una cartella di destinazione"))
          (set! *output-directory* dir)
          (send output-directory-message set-label
                (if dir
                    (path->string (simplify-path dir #t))
                    "Nessuna cartella di destinazione selezionata"))
          (validate-download))]))

(define download-button
  (new button%
       [parent frame]
       [label "Scarica"]
       [enabled #f]
       [callback
        (lambda (self ev)
          (download-video))]))

(define text-log
  (new text%))
(send text-log lock #t)
(send text-log auto-wrap #t)

(define log-window
  (new editor-canvas%
       [parent frame]
       [editor text-log]
       [style '(no-hscroll auto-vscroll)]
       [min-height 200]))

(define style-delta (make-object style-delta%))
(send style-delta set-family 'modern)

(define (write-line-to text line
                            #:color [color "black"]
                            #:size [size 10])
  (send text begin-edit-sequence)
  (send text lock #f)
  (send text set-position (send text last-position))

  (send style-delta set-delta 'change-size size)
  (send style-delta set-delta-foreground color)
  (send text-log change-style style-delta)

  (send text insert line)
  (send text lock #t)
  (send text end-edit-sequence))

(define (log #:color [color "black"] msg)
  (write-line-to text-log #:color color (~a msg "\n")))

(define (make-text-log-port color)
  (make-output-port
   'text-log-port
   always-evt
   (lambda (s start end non-block? breakable?)
     (write-line-to #:color color text-log (bytes->string/utf-8 s #\? start end))
     (- end start))
   void))

(current-output-port (make-text-log-port "dark slate gray"))
(current-error-port (make-text-log-port "tomato"))

(send root-window show #t)