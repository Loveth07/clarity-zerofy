;; Zerofy Carbon Offset Tracking System
;; Enhanced version with certificate verification and transfer capabilities

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-not-found (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-already-verified (err u105))

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
    verified: bool,
    verifier: (optional principal)
  }
)

(define-data-var certificate-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    event-type: (string-ascii 24),
    participant: principal,
    data: (optional uint),
    timestamp: uint
  }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 24)) (data (optional uint)))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events
      { event-id: event-id }
      {
        event-type: event-type,
        participant: tx-sender,
        data: data,
        timestamp: block-height
      }
    )
    event-id
  )
)

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
    (emit-event "business-registered" none)
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
    (emit-event "emissions-added" (some amount))
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
        verified: false,
        verifier: none
      }
    )
    (var-set certificate-counter new-id)
    (emit-event "certificate-created" (some new-id))
    (ok new-id))
)

(define-public (verify-certificate (certificate-id uint))
  (let (
    (certificate (unwrap! (get-certificate certificate-id) (err err-not-found)))
  )
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (asserts! (not (get verified certificate)) (err err-already-verified))
    (map-set offset-certificates
      { certificate-id: certificate-id }
      (merge certificate {
        verified: true,
        verifier: (some tx-sender)
      })
    )
    (emit-event "certificate-verified" (some certificate-id))
    (ok true))
)

(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (let (
    (certificate (unwrap! (get-certificate certificate-id) (err err-not-found)))
  )
    (asserts! (is-eq (get owner certificate) tx-sender) (err err-unauthorized))
    (map-set offset-certificates
      { certificate-id: certificate-id }
      (merge certificate {
        owner: recipient
      })
    )
    (emit-event "certificate-transferred" (some certificate-id))
    (ok true))
)

;; Read Only Functions
(define-read-only (get-business (id principal))
  (map-get? businesses { business-id: id })
)

(define-read-only (get-certificate (id uint))
  (map-get? offset-certificates { certificate-id: id })
)

(define-read-only (get-event (id uint))
  (map-get? events { event-id: id })
)
