;; practice-location.clar
;; Contract for tracking service delivery sites

(define-data-var admin principal tx-sender)

(define-map locations
  { location-id: (string-ascii 64) }
  {
    address: (string-ascii 256),
    city: (string-ascii 64),
    state: (string-ascii 64),
    zip: (string-ascii 16),
    phone: (string-ascii 32),
    is-active: bool
  }
)

(define-map provider-locations
  {
    provider-id: (string-ascii 64),
    location-id: (string-ascii 64)
  }
  {
    start-date: uint,
    end-date: (optional uint),
    is-primary: bool
  }
)

(define-read-only (get-location (location-id (string-ascii 64)))
  (map-get? locations { location-id: location-id })
)

(define-read-only (get-provider-location
    (provider-id (string-ascii 64))
    (location-id (string-ascii 64)))
  (map-get? provider-locations
    {
      provider-id: provider-id,
      location-id: location-id
    }
  )
)

(define-public (add-location
    (location-id (string-ascii 64))
    (address (string-ascii 256))
    (city (string-ascii 64))
    (state (string-ascii 64))
    (zip (string-ascii 16))
    (phone (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (get-location location-id)) (err u100))
    (ok (map-set locations
      { location-id: location-id }
      {
        address: address,
        city: city,
        state: state,
        zip: zip,
        phone: phone,
        is-active: true
      }
    ))
  )
)

(define-public (deactivate-location (location-id (string-ascii 64)))
  (let ((location (unwrap! (get-location location-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set locations
        { location-id: location-id }
        (merge location { is-active: false })
      ))
    )
  )
)

(define-public (associate-provider-location
    (provider-id (string-ascii 64))
    (location-id (string-ascii 64))
    (is-primary bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (get-location location-id)) (err u404))
    (ok (map-set provider-locations
      {
        provider-id: provider-id,
        location-id: location-id
      }
      {
        start-date: block-height,
        end-date: none,
        is-primary: is-primary
      }
    ))
  )
)

(define-public (end-provider-location
    (provider-id (string-ascii 64))
    (location-id (string-ascii 64)))
  (let ((assoc (unwrap! (get-provider-location provider-id location-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set provider-locations
        {
          provider-id: provider-id,
          location-id: location-id
        }
        (merge assoc { end-date: (some block-height) })
      ))
    )
  )
)

(define-public (update-location
    (location-id (string-ascii 64))
    (address (string-ascii 256))
    (city (string-ascii 64))
    (state (string-ascii 64))
    (zip (string-ascii 16))
    (phone (string-ascii 32)))
  (let ((location (unwrap! (get-location location-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set locations
        { location-id: location-id }
        {
          address: address,
          city: city,
          state: state,
          zip: zip,
          phone: phone,
          is-active: (get is-active location)
        }
      ))
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
