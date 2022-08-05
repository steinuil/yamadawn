#lang racket/base

(require json
         racket/gui/base
         racket/class
         racket/system
         racket/port)


(define root-window
  (new frame%
       [label "yt-dlp-gui"]
       [width 700]
       [height 700]
       [border 5]))

(define menu-bar
  (new menu-bar% [parent root-window]))
(define edit-menu
  (new menu%
       [label "&Edit"]
       [parent menu-bar]))
(append-editor-operation-menu-items edit-menu #f)

(define frame
  (new vertical-panel%
       [parent root-window]
       [spacing 5]
       [alignment '(left top)]))

(define url-to-download #f)

(define url-to-download-field
  (new text-field%
       [parent frame]
       [label "URL"]
       [callback (lambda (self ev)
                   (set! url-to-download (send self get-value)))]))



(send root-window show #t)