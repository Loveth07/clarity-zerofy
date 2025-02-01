;; Zerofy Carbon Offset Tracking System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-invalid-amount (err u102))

;; Data Variables
(define-map businesses
  { business-id: principal }
  {
    name: (string-ascii 64),
    total-emissions: uint,
    total-offsets: uint
  }
)

(define-map offset-certificates
  { certificate-id: uint }
  {
    owner: principal,
    amount: uint,
    timestamp: uint,
    verified: bool
  }
)

(define-data-var certificate-counter uint u0)

;; Public Functions
(define-public (register-business (name (string-ascii 64)))
  (begin
    (map-insert businesses
      { business-id: tx-sender }
      {
        name: name,
        total-emissions: u0,
        total-offsets: u0
      }
    )
    (ok true))
)

(define-public (add-emissions (amount uint))
  (let (
    (business (unwrap! (get-business tx-sender) (err err-not-registered)))
  )
    (map-set businesses
      { business-id: tx-sender }
      {
        name: (get name business),
        total-emissions: (+ amount (get total-emissions business)),
        total-offsets: (get total-offsets business)
      }
    )
    (ok true))
)

(define-public (create-offset-certificate (amount uint))
  (let (
    (new-id (+ (var-get certificate-counter) u1))
  )
    (map-insert offset-certificates
      { certificate-id: new-id }
      {
        owner: tx-sender,
        amount: amount,
        timestamp: block-height,
        verified: false
      }
    )
    (var-set certificate-counter new-id)
    (ok new-id))
)

;; Read Only Functions
(define-read-only (get-business (id principal))
  (map-get? businesses { business-id: id })
)

(define-read-only (get-certificate (id uint))
  (map-get? offset-certificates { certificate-id: id })
)
