;; network-participation.clar
;; Contract for recording insurance affiliations

(define-data-var admin principal tx-sender)

(define-map networks
  { network-id: (string-ascii 64) }
  {
    name: (string-ascii 64),
    insurance-type: (string-ascii 64),
    is-active: bool
  }
)

(define-map provider-networks
  {
    provider-id: (string-ascii 64),
    network-id: (string-ascii 64)
  }
  {
    start-date: uint,
    end-date: (optional uint),
    contract-id: (string-ascii 64),
    is-accepting-new-patients: bool
  }
)

(define-read-only (get-network (network-id (string-ascii 64)))
  (map-get? networks { network-id: network-id })
)

(define-read-only (get-provider-network
    (provider-id (string-ascii 64))
    (network-id (string-ascii 64)))
  (map-get? provider-networks
    {
      provider-id: provider-id,
      network-id: network-id
    }
  )
)

(define-public (add-network
    (network-id (string-ascii 64))
    (name (string-ascii 64))
    (insurance-type (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (get-network network-id)) (err u100))
    (ok (map-set networks
      { network-id: network-id }
      {
        name: name,
        insurance-type: insurance-type,
        is-active: true
      }
    ))
  )
)

(define-public (deactivate-network (network-id (string-ascii 64)))
  (let ((network (unwrap! (get-network network-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set networks
        { network-id: network-id }
        (merge network { is-active: false })
      ))
    )
  )
)

(define-public (add-provider-to-network
    (provider-id (string-ascii 64))
    (network-id (string-ascii 64))
    (contract-id (string-ascii 64))
    (is-accepting-new-patients bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (get-network network-id)) (err u404))
    (ok (map-set provider-networks
      {
        provider-id: provider-id,
        network-id: network-id
      }
      {
        start-date: block-height,
        end-date: none,
        contract-id: contract-id,
        is-accepting-new-patients: is-accepting-new-patients
      }
    ))
  )
)

(define-public (remove-provider-from-network
    (provider-id (string-ascii 64))
    (network-id (string-ascii 64)))
  (let ((assoc (unwrap! (get-provider-network provider-id network-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set provider-networks
        {
          provider-id: provider-id,
          network-id: network-id
        }
        (merge assoc { end-date: (some block-height) })
      ))
    )
  )
)

(define-public (update-patient-acceptance
    (provider-id (string-ascii 64))
    (network-id (string-ascii 64))
    (is-accepting-new-patients bool))
  (let ((assoc (unwrap! (get-provider-network provider-id network-id) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set provider-networks
        {
          provider-id: provider-id,
          network-id: network-id
        }
        (merge assoc { is-accepting-new-patients: is-accepting-new-patients })
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
