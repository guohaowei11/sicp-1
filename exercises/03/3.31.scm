(load "lib/queue.scm")
(load "lib/simulator.scm")
; 测试时，需要把 add-action! 中的 (proc) 调用注释掉 😊
(define a (make-wire))
(define b (make-wire))
(define s (make-wire))
(define c (make-wire))
(define (half-adder a b s c)
  (let ((d (make-wire))
        (e (make-wire)))
    (or-gate a b d)
    (and-gate a b c)
    (inverter c e)
    (and-gate d e s)
    "ok"))
(half-adder a b s c)
; (display the-agenda) (newline)
(set-signal! a 1)
; (display the-agenda) (newline)
(propagate)
; (display (s 'get-signal))
