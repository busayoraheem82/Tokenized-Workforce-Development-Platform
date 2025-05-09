;; Certification Contract
;; This contract validates completed training and issues certificates

(define-data-var contract-owner principal tx-sender)

;; Data structure for certificate types
(define-map certificate-types
  { type-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    issuer: principal,
    required-program-id: (optional uint),
    validity-period: uint, ;; in blocks, 0 means forever
    active: bool
  }
)

;; Data structure for issued certificates
(define-map certificates
  { certificate-id: uint }
  {
    recipient: principal,
    type-id: uint,
    issue-date: uint,
    expiry-date: uint, ;; 0 means never expires
    revoked: bool,
    metadata: (string-utf8 500)
  }
)

;; Counter for certificate type IDs
(define-data-var next-type-id uint u1)

;; Counter for certificate IDs
(define-data-var next-certificate-id uint u1)

;; Public function to create a certificate type
(define-public (create-certificate-type
    (name (string-utf8 100))
    (description (string-utf8 500))
    (required-program-id (optional uint))
    (validity-period uint))
  (let ((type-id (var-get next-type-id)))
    (begin
      (map-set certificate-types
        {type-id: type-id}
        {
          name: name,
          description: description,
          issuer: tx-sender,
          required-program-id: required-program-id,
          validity-period: validity-period,
          active: true
        }
      )
      (var-set next-type-id (+ type-id u1))
      (ok type-id)
    )
  )
)

;; Public function to issue a certificate
(define-public (issue-certificate (recipient principal) (type-id uint) (metadata (string-utf8 500)))
  (let (
    (certificate-type (map-get? certificate-types {type-id: type-id}))
    (certificate-id (var-get next-certificate-id))
    (current-block block-height)
  )
    (begin
      (asserts! (is-some certificate-type) (err u1))
      (asserts! (is-eq tx-sender (get issuer (unwrap-panic certificate-type))) (err u2))
      (asserts! (get active (unwrap-panic certificate-type)) (err u3))

      (let ((validity (get validity-period (unwrap-panic certificate-type))))
        (map-set certificates
          {certificate-id: certificate-id}
          {
            recipient: recipient,
            type-id: type-id,
            issue-date: current-block,
            expiry-date: (if (is-eq validity u0) u0 (+ current-block validity)),
            revoked: false,
            metadata: metadata
          }
        )
      )

      (var-set next-certificate-id (+ certificate-id u1))
      (ok certificate-id)
    )
  )
)

;; Public function to revoke a certificate
(define-public (revoke-certificate (certificate-id uint))
  (let ((certificate (map-get? certificates {certificate-id: certificate-id})))
    (begin
      (asserts! (is-some certificate) (err u4))
      (let (
        (cert (unwrap-panic certificate))
        (cert-type (unwrap-panic (map-get? certificate-types {type-id: (get type-id cert)})))
      )
        (begin
          (asserts! (is-eq tx-sender (get issuer cert-type)) (err u2))
          (ok (map-set certificates
            {certificate-id: certificate-id}
            (merge cert {revoked: true})
          ))
        )
      )
    )
  )
)

;; Read-only function to get certificate type details
(define-read-only (get-certificate-type (type-id uint))
  (map-get? certificate-types {type-id: type-id})
)

;; Read-only function to get certificate details
(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates {certificate-id: certificate-id})
)

;; Read-only function to verify if a certificate is valid
(define-read-only (is-certificate-valid (certificate-id uint))
  (match (map-get? certificates {certificate-id: certificate-id})
    certificate (and
                  (not (get revoked certificate))
                  (or
                    (is-eq (get expiry-date certificate) u0)
                    (> (get expiry-date certificate) block-height)
                  )
                )
    false
  )
)

;; Initialize contract
(define-private (initialize)
  (var-set contract-owner tx-sender)
)

(initialize)
