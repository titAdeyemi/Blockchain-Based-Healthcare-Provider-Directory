;; provider-verification.clar
;; Contract for validating healthcare practitioners

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: (string-ascii 64) }
  {
    principal: principal,
    status: uint,
    license-number: (string-ascii 64),
    license-expiry: uint,
    verification-date: uint
  }
)

(define-read-only (get-provider (provider-id (string-ascii 64)))
  (map-get? providers { provider-id: provider-id })
)

(define-public (register-provider
    (provider-id (string-ascii 64))
    (license-number (string-ascii 64))
    (license-expiry uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (get-provider provider-id)) (err u100))
    (ok (map-set providers
      { provider-id: provider-id }
      {
        principal: tx-sender,
        status: u0,
        license-number: license-number,
        license-expiry: license-expiry,
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-provider (provider-id (string-ascii 64)))
  (let ((provider (unwrap! (get-provider provider-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set providers
        { provider-id: provider-id }
        (merge provider {
          status: u1,
          verification-date: block-height
        })
      ))
    )
  )
)

(define-public (suspend-provider (provider-id (string-ascii 64)))
  (let ((provider (unwrap! (get-provider provider-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set providers
        { provider-id: provider-id }
        (merge provider { status: u2 })
      ))
    )
  )
)

(define-public (update-license
    (provider-id (string-ascii 64))
    (license-number (string-ascii 64))
    (license-expiry uint))
  (let ((provider (unwrap! (get-provider provider-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set providers
        { provider-id: provider-id }
        (merge provider {
          license-number: license-number,
          license-expiry: license-expiry
        })
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
