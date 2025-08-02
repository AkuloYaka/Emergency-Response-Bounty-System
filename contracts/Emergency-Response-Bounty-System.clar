(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-LOCATION (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-ALREADY-RESPONDED (err u105))
(define-constant ERR-INCIDENT-RESOLVED (err u106))
(define-constant ERR-INVALID-ROLE (err u107))
(define-constant ERR-NO-FIRST-RESPONSE (err u108))

(define-data-var next-incident-id uint u1)
(define-data-var next-response-id uint u1)
(define-data-var total-token-supply uint u1000000)
(define-data-var contract-balance uint u0)

(define-map responders
  { responder: principal }
  {
    role: (string-ascii 20),
    latitude: int,
    longitude: int,
    reputation: uint,
    total-responses: uint,
    verified: bool
  }
)

(define-map incidents
  { incident-id: uint }
  {
    reporter: principal,
    incident-type: (string-ascii 50),
    latitude: int,
    longitude: int,
    severity: uint,
    bounty-amount: uint,
    status: (string-ascii 20),
    timestamp: uint,
    priority-votes: uint,
    resolved-by: (optional principal),
    first-response-time: (optional uint)
  }
)

(define-map responses
  { response-id: uint }
  {
    incident-id: uint,
    responder: principal,
    timestamp: uint,
    response-type: (string-ascii 30),
    verified: bool,
    reward-claimed: bool
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map incident-votes
  { incident-id: uint, voter: principal }
  { voted: bool }
)

(define-map response-time-stats
  { responder: principal }
  {
    total-response-time: uint,
    fastest-response: uint,
    average-response-time: uint,
    time-bonus-earned: uint
  }
)

(define-private (calculate-time-bonus (response-time uint) (severity uint))
  (let
    (
      (base-bonus (if (<= response-time u10) u50 
                   (if (<= response-time u20) u25
                    (if (<= response-time u50) u10 u0))))
      (severity-multiplier (+ u1 (/ severity u2)))
    )
    (* base-bonus severity-multiplier)
  )
)

(define-public (register-responder (role (string-ascii 20)) (latitude int) (longitude int))
  (let
    (
      (existing-responder (map-get? responders { responder: tx-sender }))
    )
    (asserts! (is-none existing-responder) ERR-ALREADY-EXISTS)
    (asserts! (or (is-eq role "fire") (is-eq role "ambulance") (is-eq role "security")) ERR-INVALID-ROLE)
    (asserts! (and (>= latitude -90000000) (<= latitude 90000000)) ERR-INVALID-LOCATION)
    (asserts! (and (>= longitude -180000000) (<= longitude 180000000)) ERR-INVALID-LOCATION)
    (map-set responders
      { responder: tx-sender }
      {
        role: role,
        latitude: latitude,
        longitude: longitude,
        reputation: u100,
        total-responses: u0,
        verified: false
      }
    )
    (ok true)
  )
)

(define-public (verify-responder (responder principal))
  (let
    (
      (responder-data (unwrap! (map-get? responders { responder: responder }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set responders
      { responder: responder }
      (merge responder-data { verified: true })
    )
    (ok true)
  )
)

(define-public (report-incident (incident-type (string-ascii 50)) (latitude int) (longitude int) (severity uint) (bounty-amount uint))
  (let
    (
      (incident-id (var-get next-incident-id))
      (reporter-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (and (>= latitude -90000000) (<= latitude 90000000)) ERR-INVALID-LOCATION)
    (asserts! (and (>= longitude -180000000) (<= longitude 180000000)) ERR-INVALID-LOCATION)
    (asserts! (>= reporter-balance bounty-amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (and (>= severity u1) (<= severity u5)) ERR-INVALID-LOCATION)
    (map-set incidents
      { incident-id: incident-id }
      {
        reporter: tx-sender,
        incident-type: incident-type,
        latitude: latitude,
        longitude: longitude,
        severity: severity,
        bounty-amount: bounty-amount,
        status: "open",
        timestamp: stacks-block-height,
        priority-votes: u0,
        resolved-by: none,
        first-response-time: none
      }
    )
    (map-set user-balances
      { user: tx-sender }
      { balance: (- reporter-balance bounty-amount) }
    )
    (var-set contract-balance (+ (var-get contract-balance) bounty-amount))
    (var-set next-incident-id (+ incident-id u1))
    (ok incident-id)
  )
)

(define-public (respond-to-incident (incident-id uint) (response-type (string-ascii 30)))
  (let
    (
      (incident-data (unwrap! (map-get? incidents { incident-id: incident-id }) ERR-NOT-FOUND))
      (responder-data (unwrap! (map-get? responders { responder: tx-sender }) ERR-NOT-FOUND))
      (response-id (var-get next-response-id))
    )
    (asserts! (get verified responder-data) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status incident-data) "open") ERR-INCIDENT-RESOLVED)
    (if (is-none (get first-response-time incident-data))
      (map-set incidents
        { incident-id: incident-id }
        (merge incident-data { first-response-time: (some stacks-block-height) })
      )
      true
    )
    (map-set responses
      { response-id: response-id }
      {
        incident-id: incident-id,
        responder: tx-sender,
        timestamp: stacks-block-height,
        response-type: response-type,
        verified: false,
        reward-claimed: false
      }
    )
    (var-set next-response-id (+ response-id u1))
    (ok response-id)
  )
)

(define-public (verify-response (response-id uint))
  (let
    (
      (response-data (unwrap! (map-get? responses { response-id: response-id }) ERR-NOT-FOUND))
      (incident-data (unwrap! (map-get? incidents { incident-id: (get incident-id response-data) }) ERR-NOT-FOUND))
      (responder-data (unwrap! (map-get? responders { responder: (get responder response-data) }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set responses
      { response-id: response-id }
      (merge response-data { verified: true })
    )
    (map-set responders
      { responder: (get responder response-data) }
      (merge responder-data 
        { 
          reputation: (+ (get reputation responder-data) u10),
          total-responses: (+ (get total-responses responder-data) u1)
        }
      )
    )
    (ok true)
  )
)

(define-public (claim-reward (response-id uint))
  (let
    (
      (response-data (unwrap! (map-get? responses { response-id: response-id }) ERR-NOT-FOUND))
      (incident-data (unwrap! (map-get? incidents { incident-id: (get incident-id response-data) }) ERR-NOT-FOUND))
      (responder-balance (default-to u0 (get balance (map-get? user-balances { user: (get responder response-data) }))))
      (bounty-amount (get bounty-amount incident-data))
      (response-time (- (get timestamp response-data) (get timestamp incident-data)))
      (time-bonus (calculate-time-bonus response-time (get severity incident-data)))
      (total-reward (+ bounty-amount time-bonus))
      (responder-stats (default-to 
        { total-response-time: u0, fastest-response: u999999, average-response-time: u0, time-bonus-earned: u0 }
        (map-get? response-time-stats { responder: (get responder response-data) })))
    )
    (asserts! (is-eq tx-sender (get responder response-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get verified response-data) ERR-NOT-AUTHORIZED)
    (asserts! (not (get reward-claimed response-data)) ERR-ALREADY-RESPONDED)
    (asserts! (>= (var-get contract-balance) total-reward) ERR-INSUFFICIENT-BALANCE)
    (map-set responses
      { response-id: response-id }
      (merge response-data { reward-claimed: true })
    )
    (map-set user-balances
      { user: (get responder response-data) }
      { balance: (+ responder-balance total-reward) }
    )
    (map-set response-time-stats
      { responder: (get responder response-data) }
      {
        total-response-time: (+ (get total-response-time responder-stats) response-time),
        fastest-response: (if (< response-time (get fastest-response responder-stats)) response-time (get fastest-response responder-stats)),
        average-response-time: (/ (+ (get total-response-time responder-stats) response-time) (+ (get total-responses (unwrap-panic (map-get? responders { responder: (get responder response-data) }))) u1)),
        time-bonus-earned: (+ (get time-bonus-earned responder-stats) time-bonus)
      }
    )
    (var-set contract-balance (- (var-get contract-balance) total-reward))
    (map-set incidents
      { incident-id: (get incident-id response-data) }
      (merge incident-data 
        { 
          status: "resolved",
          resolved-by: (some (get responder response-data))
        }
      )
    )
    (ok true)
  )
)

(define-public (vote-incident-priority (incident-id uint))
  (let
    (
      (incident-data (unwrap! (map-get? incidents { incident-id: incident-id }) ERR-NOT-FOUND))
      (existing-vote (map-get? incident-votes { incident-id: incident-id, voter: tx-sender }))
    )
    (asserts! (is-none existing-vote) ERR-ALREADY-EXISTS)
    (asserts! (is-eq (get status incident-data) "open") ERR-INCIDENT-RESOLVED)
    (map-set incident-votes
      { incident-id: incident-id, voter: tx-sender }
      { voted: true }
    )
    (map-set incidents
      { incident-id: incident-id }
      (merge incident-data { priority-votes: (+ (get priority-votes incident-data) u1) })
    )
    (ok true)
  )
)

(define-public (mint-tokens (recipient principal) (amount uint))
  (let
    (
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: recipient }))))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set user-balances
      { user: recipient }
      { balance: (+ current-balance amount) }
    )
    (var-set total-token-supply (+ (var-get total-token-supply) amount))
    (ok true)
  )
)

(define-read-only (get-responder (responder principal))
  (map-get? responders { responder: responder })
)

(define-read-only (get-incident (incident-id uint))
  (map-get? incidents { incident-id: incident-id })
)

(define-read-only (get-response (response-id uint))
  (map-get? responses { response-id: response-id })
)

(define-read-only (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-contract-stats)
  {
    next-incident-id: (var-get next-incident-id),
    next-response-id: (var-get next-response-id),
    total-token-supply: (var-get total-token-supply),
    contract-balance: (var-get contract-balance)
  }
)

(define-read-only (get-response-time-stats (responder principal))
  (map-get? response-time-stats { responder: responder })
)

(define-read-only (get-incident-response-time (incident-id uint))
  (let
    (
      (incident-data (map-get? incidents { incident-id: incident-id }))
    )
    (match incident-data
      incident-info
        (match (get first-response-time incident-info)
          first-response (some (- first-response (get timestamp incident-info)))
          none
        )
      none
    )
  )
)

(define-read-only (calculate-projected-reward (incident-id uint) (estimated-response-time uint))
  (let
    (
      (incident-data (map-get? incidents { incident-id: incident-id }))
    )
    (match incident-data
      incident-info
        (let
          (
            (bounty-amount (get bounty-amount incident-info))
            (time-bonus (calculate-time-bonus estimated-response-time (get severity incident-info)))
          )
          (some (+ bounty-amount time-bonus))
        )
      none
    )
  )
)
