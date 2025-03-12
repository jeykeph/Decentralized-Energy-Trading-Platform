;; Energy Production Contract
;; Tracks energy generated from various sources

(define-data-var producer-id-counter uint u0)

(define-map producers
  { id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    energy-type: (string-ascii 16),
    location: (string-ascii 64),
    is-active: bool
  }
)

(define-map production-records
  { producer-id: uint, record-id: uint }
  {
    timestamp: uint,
    energy-amount: uint,
    is-certified: bool
  }
)

;; Register a new energy producer
(define-public (register-producer
                (name (string-ascii 64))
                (energy-type (string-ascii 16))
                (location (string-ascii 64)))
  (let
    ((new-id (+ (var-get producer-id-counter) u1)))

    ;; Update counter
    (var-set producer-id-counter new-id)

    ;; Store producer data
    (ok (map-set producers
      { id: new-id }
      {
        owner: tx-sender,
        name: name,
        energy-type: energy-type,
        location: location,
        is-active: true
      }
    ))
  )
)

;; Record energy production
(define-public (record-production
                (producer-id uint)
                (record-id uint)
                (energy-amount uint))
  (let
    ((producer (default-to
                 { owner: tx-sender, name: "", energy-type: "", location: "", is-active: false }
                 (map-get? producers { id: producer-id }))))

    ;; Only producer owner can record production
    (asserts! (is-eq tx-sender (get owner producer)) (err u1))

    ;; Producer must be active
    (asserts! (get is-active producer) (err u2))

    ;; Store production record
    (ok (map-set production-records
      { producer-id: producer-id, record-id: record-id }
      {
        timestamp: block-height,
        energy-amount: energy-amount,
        is-certified: false
      }
    ))
  )
)

;; Certify energy production
(define-public (certify-production (producer-id uint) (record-id uint))
  (let
    ((record (default-to
               { timestamp: u0, energy-amount: u0, is-certified: false }
               (map-get? production-records { producer-id: producer-id, record-id: record-id }))))

    ;; Only contract owner can certify for now (simplified)
    (asserts! (is-eq tx-sender (as-contract tx-sender)) (err u1))

    ;; Update certification status
    (ok (map-set production-records
      { producer-id: producer-id, record-id: record-id }
      (merge record { is-certified: true })
    ))
  )
)

;; Get producer details
(define-read-only (get-producer (producer-id uint))
  (map-get? producers { id: producer-id })
)

;; Get production record
(define-read-only (get-production-record (producer-id uint) (record-id uint))
  (map-get? production-records { producer-id: producer-id, record-id: record-id })
)

;; Get total production for a producer
(define-read-only (get-total-production (producer-id uint))
  ;; In a real implementation, this would sum all records
  ;; Simplified version just returns 0
  u0
)
