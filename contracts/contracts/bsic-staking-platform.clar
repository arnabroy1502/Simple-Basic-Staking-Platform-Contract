
;; Simple Basic Staking Platform Contract

(define-map stakes
  principal
  uint)

(define-data-var total-staked uint u0)

;; Function 1: Stake tokens (amount to be staked)
(define-public (stake (amount uint))
  (let ((previous (default-to u0 (map-get? stakes tx-sender))))
    (begin
      (map-set stakes tx-sender (+ previous amount))
      (var-set total-staked (+ (var-get total-staked) amount))
      (ok true))))

;; Function 2: View user’s staked amount
(define-read-only (get-stake (user principal))
  (ok (map-get? stakes user)))
