;; Skill Assessment Contract
;; This contract records verified capabilities of workers

(define-data-var contract-owner principal tx-sender)

;; Data structure for skills
(define-map skills
  { skill-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    category: (string-utf8 100)
  }
)

;; Data structure for worker skills
(define-map worker-skills
  { worker: principal, skill-id: uint }
  {
    proficiency-level: uint,
    verified: bool,
    verifier: principal,
    verification-date: uint
  }
)

;; Counter for skill IDs
(define-data-var next-skill-id uint u1)

;; Public function to add a new skill type
(define-public (add-skill (name (string-utf8 100)) (description (string-utf8 500)) (category (string-utf8 100)))
  (let ((skill-id (var-get next-skill-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
      (map-set skills
        {skill-id: skill-id}
        {
          name: name,
          description: description,
          category: category
        }
      )
      (var-set next-skill-id (+ skill-id u1))
      (ok skill-id)
    )
  )
)

;; Public function for workers to claim a skill
(define-public (claim-skill (skill-id uint) (proficiency-level uint))
  (begin
    (asserts! (is-some (map-get? skills {skill-id: skill-id})) (err u2))
    (asserts! (<= proficiency-level u5) (err u3))
    (ok (map-set worker-skills
      {worker: tx-sender, skill-id: skill-id}
      {
        proficiency-level: proficiency-level,
        verified: false,
        verifier: tx-sender,
        verification-date: u0
      }
    ))
  )
)

;; Public function to verify a worker's skill
(define-public (verify-skill (worker principal) (skill-id uint) (proficiency-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4))
    (asserts! (is-some (map-get? skills {skill-id: skill-id})) (err u2))
    (asserts! (<= proficiency-level u5) (err u3))
    (ok (map-set worker-skills
      {worker: worker, skill-id: skill-id}
      {
        proficiency-level: proficiency-level,
        verified: true,
        verifier: tx-sender,
        verification-date: block-height
      }
    ))
  )
)

;; Read-only function to get skill details
(define-read-only (get-skill (skill-id uint))
  (map-get? skills {skill-id: skill-id})
)

;; Read-only function to get worker's skill
(define-read-only (get-worker-skill (worker principal) (skill-id uint))
  (map-get? worker-skills {worker: worker, skill-id: skill-id})
)

;; Read-only function to check if a worker has a verified skill
(define-read-only (has-verified-skill (worker principal) (skill-id uint))
  (match (map-get? worker-skills {worker: worker, skill-id: skill-id})
    skill (get verified skill)
    false
  )
)

;; Initialize contract
(define-private (initialize)
  (var-set contract-owner tx-sender)
)

(initialize)
