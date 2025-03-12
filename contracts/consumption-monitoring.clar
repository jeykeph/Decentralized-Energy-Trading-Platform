;; Consumption Monitoring Contract
;; Records energy usage by consumers

(define-data-var consumer-id-counter uint u0)

(define-map consumers
  { id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    location: (string-ascii 64),
    meter-id: (string-ascii 32),
    is-active: bool
  }
)

(define-map consumption-records
  { consumer-id: uint, record-id: uint }
  {
    timestamp: uint,
    energy-amount: uint,
    is-verified: bool
  }
)

;; Register a new energy consumer
(define-public (register-consumer
                (name (string-ascii 64))
                (location (string-ascii 64))
                (meter-id (string-ascii 32)))
  (let
    ((new-id (+ (var-get consumer-id-counter) u1)))

    ;; Update counter
    (var-set consumer-id-counter new-id)

    ;; Store consumer data
    (ok (map-set consumers
      { id: new-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        meter-id: meter-id,
        is-active: true
      }
    ))
  )
)

;; Record energy consumption
(define-public (record-consumption
                (consumer-id uint)
                (record-id uint)
                (energy-amount uint))
  (let
    ((consumer (default-to
                 { owner: tx-sender, name: "", location: "", meter-id: "", is-active: false }
                 (map-get? consumers { id: consumer-id }))))

    ;; Only authorized entities can record consumption
    ;; In a real system, this would be the smart meter or utility
    ;; For simplicity, we allow the consumer to self-report
    (asserts! (is-eq tx-sender (get owner consumer)) (err u1))

    ;; Consumer must be active
    (asserts! (get is-active consumer) (err u2))

    ;; Store consumption record
    (ok (map-set consumption-records
      { consumer-id: consumer-id, record-id: record-id }
      {
        timestamp: block-height,
        energy-amount: energy-amount,
        is-verified: false
      }
    ))
  )
)

;; Verify energy consumption
(define-public (verify-consumption (consumer-id uint) (record-id uint))
  (let
    ((record (default-to
               { timestamp: u0, energy-amount: u0, is-verified: false }
               (map-get? consumption-records { consumer-id: consumer-id, record-id: record-id }))))

    ;; Only contract owner can verify for now (simplified)
    (asserts! (is-eq tx-sender (as-contract tx-sender)) (err u1))

    ;; Update verification status
    (ok (map-set consumption-records
      { consumer-id: consumer-id, record-id: record-id }
      (merge record { is-verified: true })
    ))
  )
)

;; Get consumer details
(define-read-only (get-consumer (consumer-id uint))
  (map-get? consumers { id: consumer-id })
)

;; Get consumption record
(define-read-only (get-consumption-record (consumer-id uint) (record-id uint))
  (map-get? consumption-records { consumer-id: consumer-id, record-id: record-id })
)

;; Get total consumption for a consumer
(define-read-only (get-total-consumption (consumer-id uint))
  ;; In a real implementation, this would sum all records
  ;; Simplified version just returns 0
  u0
)
