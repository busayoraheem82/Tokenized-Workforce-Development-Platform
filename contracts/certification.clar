;; Individual Verification Contract
;; This contract validates worker identities and stores verification status

(define-data-var contract-owner principal tx-sender)

;; Data structure for individual verification
(define-map individuals
  { id: principal }
  {
    verified: bool,
    name: (string-utf8 100),
    contact: (string-utf8 100),
    date-verified: uint,
    verification-authority: principal
  }
)

;; Public function to register an individual
(define-public (register-individual (name (string-utf8 100)) (contact (string-utf8 100)))
  (begin
    (asserts! (not (is-some (map-get? individuals {id: tx-sender}))) (err u1))
    (ok (map-set individuals
      {id: tx-sender}
      {
        verified: false,
        name: name,
        contact: contact,
        date-verified: u0,
        verification-authority: tx-sender
      }
    ))
  )
)

;; Public function to verify an individual (only by contract owner)
(define-public (verify-individual (id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u2))
    (asserts! (is-some (map-get? individuals {id: id})) (err u3))
    (ok (map-set individuals
      {id: id}
      (merge (unwrap-panic (map-get? individuals {id: id}))
        {
          verified: true,
          date-verified: block-height,
          verification-authority: tx-sender
        }
      )
    ))
  )
)

;; Read-only function to check if an individual is verified
(define-read-only (is-verified (id principal))
  (match (map-get? individuals {id: id})
    individual (ok (get verified individual))
    (err u4)
  )
)

;; Read-only function to get individual details
(define-read-only (get-individual-details (id principal))
  (map-get? individuals {id: id})
)

;; Initialize contract
(define-private (initialize)
  (var-set contract-owner tx-sender)
)

(initialize)
