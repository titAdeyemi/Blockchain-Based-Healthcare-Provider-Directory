;; specialty-certification.clar
;; Contract for recording verified medical expertise

(define-data-var admin principal tx-sender)

(define-map specialties
  { specialty-id: (string-ascii 64) }
  { name: (string-ascii 64) }
)

(define-map provider-specialties
  {
    provider-id: (string-ascii 64),
    specialty-id: (string-ascii 64)
  }
  {
    certification-date: uint,
    expiry-date: uint,
    certification-authority: (string-ascii 64),
    is-active: bool
  }
)

(define-read-only (get-specialty (specialty-id (string-ascii 64)))
  (map-get? specialties { specialty-id: specialty-id })
)

(define-read-only (get-provider-specialty
    (provider-id (string-ascii 64))
    (specialty-id (string-ascii 64)))
  (map-get? provider-specialties
    {
      provider-id: provider-id,
      specialty-id: specialty-id
    }
  )
)

(define-public (add-specialty
    (specialty-id (string-ascii 64))
    (name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (get-specialty specialty-id)) (err u100))
    (ok (map-set specialties
      { specialty-id: specialty-id }
      { name: name }
    ))
  )
)

(define-public (certify-provider
    (provider-id (string-ascii 64))
    (specialty-id (string-ascii 64))
    (expiry-date uint)
    (certification-authority (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (get-specialty specialty-id)) (err u404))
    (ok (map-set provider-specialties
      {
        provider-id: provider-id,
        specialty-id: specialty-id
      }
      {
        certification-date: block-height,
        expiry-date: expiry-date,
        certification-authority: certification-authority,
        is-active: true
      }
    ))
  )
)

(define-public (revoke-certification
    (provider-id (string-ascii 64))
    (specialty-id (string-ascii 64)))
  (let ((cert (unwrap! (get-provider-specialty provider-id specialty-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set provider-specialties
        {
          provider-id: provider-id,
          specialty-id: specialty-id
        }
        (merge cert { is-active: false })
      ))
    )
  )
)

(define-public (update-certification
    (provider-id (string-ascii 64))
    (specialty-id (string-ascii 64))
    (expiry-date uint))
  (let ((cert (unwrap! (get-provider-specialty provider-id specialty-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set provider-specialties
        {
          provider-id: provider-id,
          specialty-id: specialty-id
        }
        (merge cert { expiry-date: expiry-date })
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
