;; Peer-to-Peer Trading Contract
;; Facilitates direct energy exchange between users

(define-data-var offer-id-counter uint u0)

(define-map energy-offers
  { id: uint }
  {
    seller: principal,
    energy-amount: uint,
    price-per-unit: uint,
    producer-id: uint,
    expiration: uint,
    is-active: bool
  }
)

(define-map energy-trades
  { offer-id: uint }
  {
    buyer: principal,
    seller: principal,
    energy-amount: uint,
    total-price: uint,
    timestamp: uint,
    is-completed: bool
  }
)

;; Create energy offer
(define-public (create-offer
                (energy-amount uint)
                (price-per-unit uint)
                (producer-id uint)
                (expiration uint))
  (let
    ((new-id (+ (var-get offer-id-counter) u1)))

    ;; Update counter
    (var-set offer-id-counter new-id)

    ;; Store offer data
    (ok (map-set energy-offers
      { id: new-id }
      {
        seller: tx-sender,
        energy-amount: energy-amount,
        price-per-unit: price-per-unit,
        producer-id: producer-id,
        expiration: expiration,
        is-active: true
      }
    ))
  )
)

;; Cancel energy offer
(define-public (cancel-offer (offer-id uint))
  (let
    ((offer (default-to
              { seller: tx-sender, energy-amount: u0, price-per-unit: u0, producer-id: u0, expiration: u0, is-active: false }
              (map-get? energy-offers { id: offer-id }))))

    ;; Only seller can cancel offer
    (asserts! (is-eq tx-sender (get seller offer)) (err u1))

    ;; Offer must be active
    (asserts! (get is-active offer) (err u2))

    ;; Update offer status
    (ok (map-set energy-offers
      { id: offer-id }
      (merge offer { is-active: false })
    ))
  )
)

;; Buy energy from offer
(define-public (buy-energy (offer-id uint))
  (let
    ((offer (default-to
              { seller: tx-sender, energy-amount: u0, price-per-unit: u0, producer-id: u0, expiration: u0, is-active: false }
              (map-get? energy-offers { id: offer-id }))))

    ;; Offer must be active
    (asserts! (get is-active offer) (err u1))

    ;; Offer must not be expired
    (asserts! (< block-height (get expiration offer)) (err u2))

    ;; Buyer cannot be seller
    (asserts! (not (is-eq tx-sender (get seller offer))) (err u3))

    ;; Calculate total price
    (let
      ((total-price (* (get energy-amount offer) (get price-per-unit offer))))

      ;; Transfer payment (simplified - in real implementation would use STX transfer)
      ;; (try! (stx-transfer? total-price tx-sender (get seller offer)))

      ;; Record trade
      (map-set energy-trades
        { offer-id: offer-id }
        {
          buyer: tx-sender,
          seller: (get seller offer),
          energy-amount: (get energy-amount offer),
          total-price: total-price,
          timestamp: block-height,
          is-completed: true
        }
      )

      ;; Update offer status
      (map-set energy-offers
        { id: offer-id }
        (merge offer { is-active: false })
      )

      (ok total-price)
    )
  )
)

;; Get offer details
(define-read-only (get-offer (offer-id uint))
  (map-get? energy-offers { id: offer-id })
)

;; Get trade details
(define-read-only (get-trade (offer-id uint))
  (map-get? energy-trades { offer-id: offer-id })
)

;; Get active offers
(define-read-only (is-offer-active (offer-id uint))
  (let
    ((offer (default-to
              { seller: tx-sender, energy-amount: u0, price-per-unit: u0, producer-id: u0, expiration: u0, is-active: false }
              (map-get? energy-offers { id: offer-id }))))

    (and (get is-active offer) (< block-height (get expiration offer)))
  )
)
