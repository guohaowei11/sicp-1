
; 基本功能快

; (get-signal <wire>)
; (set-signal! <wire> <new value>)
; (add-action! <wire> <procedure of no arguments>)
; 线路的表示

(define (make-wire)
  (let ((signal-value 0)
        (action-procedures '()))
    (define (set-my-signal! new-value)
      (if (not (= signal-value new-value))
        (begin
          (set! signal-value new-value)
          (call-each action-procedures))
        "done"))
    (define (accept-action-procedure! proc)
      (set! action-procedures (cons proc action-procedures))
      ; 这里将 proc 加入后，立即执行了 proc，为什么？ 见习题3.31
      (proc)
      )
    (define (dispatch m)
      (cond
        ((eq? m 'get-signal) signal-value)
        ((eq? m 'set-signal!) set-my-signal!)
        ((eq? m 'add-action!) accept-action-procedure!)
        ((eq? m 'get-action) action-procedures)
        (else (error "Unknown operation -- WIRE" m))))
    dispatch))
(define (call-each procedures)
  (if (null? procedures)
    "done"
    (begin
      ((car procedures))
      (call-each (cdr procedures)))))

(define (get-signal wire)
  (wire 'get-signal))
(define (set-signal! wire new-value)
  ((wire 'set-signal!) new-value))
(define (add-action! wire action-procedure)
  ((wire 'add-action!) action-procedure))

; 待处理表
(define (make-time-segment time queue)
  (cons time queue))
(define (segment-time s) (car s))
(define (segment-queue s) (cdr s))
(define (make-agenda) (list 0))
(define (current-time agenda) (car agenda))
(define (set-current-time! agenda time)
  (set-car! agenda time))
(define (segments agenda)
  (cdr agenda))
(define (set-segments! agenda segments)
  (set-cdr! agenda segments))
(define (first-segment agenda)
  (car (segments agenda)))
(define (rest-segments agenda) (cdr (segments agenda)))
(define (empty-agenda? agenda) (null? (segments agenda)))

(define (add-to-agenda! time action agenda)
  (define (belongs-before? segments)
    (or (null? segments)
        (< time (segment-time (car segments)))))
  (define (make-new-time-segment time action)
    (let ((q (make-queue)))
      (insert-queue! q action)
      (make-time-segment time q)))
  (define (add-to-segments! segments)
    (if (= (segment-time (car segments)) time)
      (insert-queue! (segment-queue (car segments))
                     action)
      (let ((rest (cdr segments)))
        (if (belongs-before? rest)
          (set-cdr! segments (cons (make-new-time-segment time action)
                                   (cdr segments)))
          (add-to-segments! rest)))))
  (let ((segs (segments agenda)))
    (if (belongs-before? segs)
      (set-segments! agenda (cons (make-new-time-segment time action)
                                  segs))
      (add-to-segments! segs))))
(define (remove-first-agenda-item! agenda)
  (let ((q (segment-queue (first-segment agenda))))
    (delete-queue! q)
    (if (empty-queue? q)
      (set-segments! agenda (rest-segments agenda)))))
(define (first-agenda-item agenda)
  (if (empty-agenda? agenda)
    (error "Agenda is empty -- FIRST-AGENDA-ITEM")
    (let ((first-seg (first-segment agenda)))
    ; (display agenda)
    ; (newline)
    ; (display (segment-queue first-seg))
    ; (newline)
    ; (display (front-queue (car (segment-queue first-seg))))
    ; (newline)
    ; (display 1)
    ; (newline)
      (set-current-time! agenda (segment-time first-seg))
      (front-queue (car (segment-queue first-seg))))))

(define (after-delay delay action)
  (add-to-agenda! (+ delay (current-time the-agenda))
                  action
                  the-agenda))

(define (propagate)
  (if (empty-agenda? the-agenda)
    'done
    (let ((first-item (first-agenda-item the-agenda)))
      (first-item)
      (remove-first-agenda-item! the-agenda)
      (propagate))))

; 一个简单的实例模拟
(define (probe name wire)
  (add-action! wire
    (lambda ()
      (newline)
      (display name)
      (display "  ")
      (display (current-time the-agenda))
      (display " New-value = ")
      (display (get-signal wire)))))

(define the-agenda (make-agenda))
(define or-gate-delay 5)
(define and-gate-delay 3)
(define inverter-delay 2)


(define (inverter input output)
  (define (logical-not s)
    (cond
      ((= s 0) 1)
      ((= s 1) 0)
      (else (error "Invalid signal" s))))
  (define (invert-input)
    (let ((new-value (logical-not (get-signal input))))
      (after-delay inverter-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! input invert-input)
  "ok")


(define (and-gate a1 a2 output)
  (define (logical-and x y)
    (if (and (= 1 x) (= 1 y))
      1
      0))
  (define (and-action-procedure)
    (let ((new-value (logical-and (get-signal a1)
                                  (get-signal a2))))
      (after-delay and-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! a1 and-action-procedure)
  (add-action! a2 and-action-procedure)
  "ok")
(define (or-gate a1 a2 output)
  (define (logical-or x y)
    (if (or (= 1 x) (= 1 y))
      1
      0))
  (define (or-action-procedure)
    (let ((new-value (logical-or (get-signal a1)
                                 (get-signal a2))))
      (after-delay or-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! a1 or-action-procedure)
  (add-action! a2 or-action-procedure)
  "ok")

(define (half-adder a b s c)
  (let ((d (make-wire))
        (e (make-wire)))
    (or-gate a b d)
    (and-gate a b c)
    (inverter c e)
    (and-gate d e s)
    "ok"))

(define (full-adder a b c-in sum c-out)
  (let ((s (make-wire))
        (c1 (make-wire))
        (c2 (make-wire)))
    (half-adder b c-in s c1)
    (half-adder a s sum c2)
    (or-gate c1 c2 c-out)
    "ok"))
