;; Simple Basic Staking Platform Contract
;; A minimal staking platform with only two core functions: stake and unstake

;; Define the reward token
(define-fungible-token staking-reward-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-no-stake-found (err u104))
(define-constant err-insufficient-stake (err u105))

;; Token name and symbol
(define-data-var token-name (string-ascii 32) "Staking Reward Token")
(define-data-var token-symbol (string-ascii 10) "SRT")
(define-data-var token-decimals uint u6)

;; Total supply tracking
(define-data-var total-supply uint u0)

;; Staking tracking
(define-map stakes principal uint)
(define-data-var total-staked uint u0)

;; Function 1: Stake STX tokens
(define-public (stake (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= (stx-get-balance tx-sender) amount) err-insufficient-balance)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update stake record
    (map-set stakes tx-sender
             (+ (default-to u0 (map-get? stakes tx-sender)) amount))
    
    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) amount))
    
    ;; Mint reward tokens (1:1 ratio for simplicity)
    (try! (ft-mint? staking-reward-token amount tx-sender))
    (var-set total-supply (+ (var-get total-supply) amount))
    
    (print {
      event: "stake-created",
      user: tx-sender,
      amount: amount,
      total-staked: (+ (default-to u0 (map-get? stakes tx-sender)) amount)
    })
    
    (ok true)))

;; Function 2: Unstake STX tokens
(define-public (unstake (amount uint))
  (let (
    (current-stake (default-to u0 (map-get? stakes tx-sender)))
    (remaining-stake (- current-stake amount))
  )
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= current-stake amount) err-insufficient-stake)
    (asserts! (>= (ft-get-balance staking-reward-token tx-sender) amount) err-insufficient-balance)
    
    ;; Burn reward tokens
    (try! (ft-burn? staking-reward-token amount tx-sender))
    (var-set total-supply (- (var-get total-supply) amount))
    
    ;; Update stake record
    (if (> remaining-stake u0)
        (map-set stakes tx-sender remaining-stake)
        (map-delete stakes tx-sender))
    
    ;; Update total staked
    (var-set total-staked (- (var-get total-staked) amount))
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (print {
      event: "stake-withdrawn",
      user: tx-sender,
      amount: amount,
      remaining-stake: remaining-stake
    })
    
    (ok true))))

;; Read-only functions for basic information

;; Get stake balance
(define-read-only (get-stake-balance (account principal))
  (ok (default-to u0 (map-get? stakes account))))

;; Get reward token balance
(define-read-only (get-reward-balance (account principal))
  (ok (ft-get-balance staking-reward-token account)))

;; Get total staked
(define-read-only (get-total-staked)
  (ok (var-get total-staked)))

;; Get token info
(define-read-only (get-name)
  (ok (var-get token-name)))

(define-read-only (get-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-decimals)
  (ok (var-get token-decimals)))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))