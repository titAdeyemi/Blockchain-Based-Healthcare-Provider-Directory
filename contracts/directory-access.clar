;; directory-access.clar
;; Contract for managing third-party information retrieval

(define-data-var admin principal tx-sender)

(define-map access-keys
  { key-id: (string-ascii 64) }
  {
    principal: principal,
    access-level: uint,
    expiry-date: uint,
    is-active: bool,
    organization: (string-ascii 64)
  }
)

(define-map access-logs
  {
    key-id: (string-ascii 64),
    log-id: uint
  }
  {
    timestamp: uint,
    resource-type: (string-ascii 64),
    resource-id: (string-ascii 64),
    action: (string-ascii 64)
  }
)

(define-data-var log-counter uint u0)

(define-read-only (get-access-key (key-id (string-ascii 64)))
  (map-get? access-keys { key-id: key-id })
)

(define-read-only (get-access-log (key-id (string-ascii 64)) (log-id uint))
  (map-get? access-logs { key-id: key-id, log-id: log-id })
)

(define-public (create-access-key
    (key-id (string-ascii 64))
    (user principal)
    (access-level uint)
    (expiry-date uint)
    (organization (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (get-access-key key-id)) (err u100))
    (ok (map-set access-keys
      { key-id: key-id }
      {
        principal: user,
        access-level: access-level,
        expiry-date: expiry-date,
        is-active: true,
        organization: organization
      }
    ))
  )
)

(define-public (revoke-access-key (key-id (string-ascii 64)))
  (let ((key (unwrap! (get-access-key key-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set access-keys
        { key-id: key-id }
        (merge key { is-active: false })
      ))
    )
  )
)

(define-public (extend-access-key (key-id (string-ascii 64)) (new-expiry uint))
  (let ((key (unwrap! (get-access-key key-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set access-keys
        { key-id: key-id }
        (merge key { expiry-date: new-expiry })
      ))
    )
  )
)

(define-public (log-access
    (key-id (string-ascii 64))
    (resource-type (string-ascii 64))
    (resource-id (string-ascii 64))
    (action (string-ascii 64)))
  (let (
    (key (unwrap! (get-access-key key-id) (err u404)))
    (current-log-id (var-get log-counter))
  )
    (begin
      (asserts! (is-eq tx-sender (get principal key)) (err u403))
      (asserts! (get is-active key) (err u401))
      (asserts! (< block-height (get expiry-date key)) (err u401))
      (var-set log-counter (+ current-log-id u1))
      (ok (map-set access-logs
        {
          key-id: key-id,
          log-id: current-log-id
        }
        {
          timestamp: block-height,
          resource-type: resource-type,
          resource-id: resource-id,
          action: action
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
