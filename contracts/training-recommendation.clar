;; Training Recommendation Contract
;; This contract matches workers with education opportunities

(define-data-var contract-owner principal tx-sender)

;; Data structure for training programs
(define-map training-programs
  { program-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    provider: principal,
    required-skills: (list 10 uint),
    target-skills: (list 10 uint),
    duration: uint,
    active: bool
  }
)

;; Data structure for worker recommendations
(define-map worker-recommendations
  { worker: principal, program-id: uint }
  {
    recommendation-date: uint,
    relevance-score: uint,
    recommended-by: principal
  }
)

;; Counter for program IDs
(define-data-var next-program-id uint u1)

;; Public function to add a training program
(define-public (add-training-program
    (name (string-utf8 100))
    (description (string-utf8 500))
    (required-skills (list 10 uint))
    (target-skills (list 10 uint))
    (duration uint))
  (let ((program-id (var-get next-program-id)))
    (begin
      (map-set training-programs
        {program-id: program-id}
        {
          name: name,
          description: description,
          provider: tx-sender,
          required-skills: required-skills,
          target-skills: target-skills,
          duration: duration,
          active: true
        }
      )
      (var-set next-program-id (+ program-id u1))
      (ok program-id)
    )
  )
)

;; Public function to recommend a training program to a worker
(define-public (recommend-program (worker principal) (program-id uint) (relevance-score uint))
  (begin
    (asserts! (is-some (map-get? training-programs {program-id: program-id})) (err u1))
    (asserts! (<= relevance-score u100) (err u2))
    (ok (map-set worker-recommendations
      {worker: worker, program-id: program-id}
      {
        recommendation-date: block-height,
        relevance-score: relevance-score,
        recommended-by: tx-sender
      }
    ))
  )
)

;; Public function to deactivate a training program
(define-public (deactivate-program (program-id uint))
  (let ((program (map-get? training-programs {program-id: program-id})))
    (begin
      (asserts! (is-some program) (err u1))
      (asserts! (is-eq tx-sender (get provider (unwrap-panic program))) (err u3))
      (ok (map-set training-programs
        {program-id: program-id}
        (merge (unwrap-panic program) {active: false})
      ))
    )
  )
)

;; Read-only function to get training program details
(define-read-only (get-training-program (program-id uint))
  (map-get? training-programs {program-id: program-id})
)

;; Read-only function to get worker recommendation
(define-read-only (get-worker-recommendation (worker principal) (program-id uint))
  (map-get? worker-recommendations {worker: worker, program-id: program-id})
)

;; Initialize contract
(define-private (initialize)
  (var-set contract-owner tx-sender)
)

(initialize)
