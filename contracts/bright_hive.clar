;; BrightHive - Decentralized Brainstorming Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-contract-paused (err u105))
(define-constant err-idea-archived (err u106))
(define-constant err-invalid-collection (err u107))
(define-constant max-events u1000)
(define-constant reward-amount u10)

;; Contract status
(define-data-var contract-paused bool false)
(define-data-var last-idea-id uint u0)
(define-data-var last-event-id uint u0)

;; Data structures
(define-map ideas
  { id: uint }
  {
    title: (string-ascii 100),
    description: (string-utf8 1000),
    creator: principal,
    votes: uint,
    created-at: uint,
    collection-id: uint,
    category: (string-ascii 50),
    reward-claimed: bool,
    archived: bool,
    last-modified: uint
  }
)

(define-map categories
  { name: (string-ascii 50) }
  { active: bool }
)

(define-map collections
  { id: uint }
  { 
    name: (string-ascii 100),
    active: bool
  }
)

(define-map events
  { id: uint }
  {
    event-type: (string-ascii 20),
    data: (string-utf8 200),
    timestamp: uint
  }
)

;; Administrative functions
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok true)
  )
)

;; Helper functions
(define-private (emit-event (event-type (string-ascii 20)) (data (string-utf8 200)))
  (let
    ((new-id (+ (var-get last-event-id) u1)))
    (asserts! (<= new-id max-events) err-invalid-input)
    (map-set events
      { id: new-id }
      {
        event-type: event-type,
        data: data,
        timestamp: block-height
      }
    )
    (var-set last-event-id new-id)
    new-id
  )
)

;; Enhanced idea functions
(define-public (create-idea (title (string-ascii 100)) (description (string-utf8 1000)) (collection-id uint) (category (string-ascii 50)))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    
    (let
      (
        (new-id (+ (var-get last-idea-id) u1))
        (category-exists (unwrap! (map-get? categories {name: category}) err-not-found))
        (collection-exists (unwrap! (map-get? collections {id: collection-id}) err-invalid-collection))
      )
      (asserts! (get active category-exists) err-invalid-input)
      (asserts! (get active collection-exists) err-invalid-collection)
      
      (map-set ideas
        { id: new-id }
        {
          title: title,
          description: description,
          creator: tx-sender,
          votes: u0,
          created-at: block-height,
          collection-id: collection-id,
          category: category,
          reward-claimed: false,
          archived: false,
          last-modified: block-height
        }
      )
      (var-set last-idea-id new-id)
      (emit-event "idea-created" (concat (to-string new-id) ": " title))
      (ok new-id)
    )
  )
)

[Rest of the contract remains unchanged...]
