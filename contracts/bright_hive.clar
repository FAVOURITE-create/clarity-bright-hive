;; BrightHive - Decentralized Brainstorming Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant reward-amount u10) ;; Amount of tokens awarded for contributions

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
    reward-claimed: bool
  }
)

(define-map collections
  { id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    created-at: uint,
    category: (string-ascii 50)
  }
)

(define-map comments
  { idea-id: uint, comment-id: uint }
  {
    text: (string-utf8 500),
    author: principal,
    created-at: uint,
    reward-claimed: bool
  }
)

(define-map idea-votes
  { idea-id: uint, voter: principal }
  { voted: bool }
)

(define-map categories
  { name: (string-ascii 50) }
  { active: bool }
)

;; Data variables
(define-data-var last-idea-id uint u0)
(define-data-var last-collection-id uint u0)
(define-data-var last-comment-id uint u0)
(define-data-var total-rewards-distributed uint u0)

;; Category functions
(define-public (add-category (name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set categories
      { name: name }
      { active: true }
    )
    (ok true)
  )
)

;; Collection functions
(define-public (create-collection (name (string-ascii 100)) (category (string-ascii 50)))
  (let
    (
      (new-id (+ (var-get last-collection-id) u1))
      (category-exists (unwrap! (map-get? categories {name: category}) err-not-found))
    )
    (map-set collections
      { id: new-id }
      {
        name: name,
        owner: tx-sender,
        created-at: block-height,
        category: category
      }
    )
    (var-set last-collection-id new-id)
    (ok new-id)
  )
)

;; Idea functions
(define-public (create-idea (title (string-ascii 100)) (description (string-utf8 1000)) (collection-id uint) (category (string-ascii 50)))
  (let
    (
      (new-id (+ (var-get last-idea-id) u1))
      (category-exists (unwrap! (map-get? categories {name: category}) err-not-found))
    )
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
        reward-claimed: false
      }
    )
    (var-set last-idea-id new-id)
    (ok new-id)
  )
)

(define-public (claim-idea-reward (idea-id uint))
  (let
    (
      (idea (unwrap! (map-get? ideas {id: idea-id}) err-not-found))
      (vote-threshold u5)
    )
    (asserts! (is-eq (get creator idea) tx-sender) err-unauthorized)
    (asserts! (>= (get votes idea) vote-threshold) err-unauthorized)
    (asserts! (not (get reward-claimed idea)) err-already-exists)
    
    (try! (stx-transfer? reward-amount contract-owner tx-sender))
    (map-set ideas
      {id: idea-id}
      (merge idea {reward-claimed: true})
    )
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward-amount))
    (ok true)
  )
)

(define-public (claim-comment-reward (idea-id uint) (comment-id uint))
  (let
    (
      (comment (unwrap! (map-get? comments {idea-id: idea-id, comment-id: comment-id}) err-not-found))
    )
    (asserts! (is-eq (get author comment) tx-sender) err-unauthorized)
    (asserts! (not (get reward-claimed comment)) err-already-exists)
    
    (try! (stx-transfer? reward-amount contract-owner tx-sender))
    (map-set comments
      {idea-id: idea-id, comment-id: comment-id}
      (merge comment {reward-claimed: true})
    )
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward-amount))
    (ok true)
  )
)

;; Existing functions remain unchanged
(define-public (vote-idea (idea-id uint))
  (let
    (
      (idea (unwrap! (map-get? ideas {id: idea-id}) err-not-found))
      (has-voted (map-get? idea-votes {idea-id: idea-id, voter: tx-sender}))
    )
    (asserts! (is-none has-voted) err-already-exists)
    (map-set idea-votes
      {idea-id: idea-id, voter: tx-sender}
      {voted: true}
    )
    (map-set ideas
      {id: idea-id}
      (merge idea {votes: (+ (get votes idea) u1)})
    )
    (ok true)
  )
)

(define-public (add-comment (idea-id uint) (text (string-utf8 500)))
  (let
    (
      (new-comment-id (+ (var-get last-comment-id) u1))
    )
    (map-set comments
      {idea-id: idea-id, comment-id: new-comment-id}
      {
        text: text,
        author: tx-sender,
        created-at: block-height,
        reward-claimed: false
      }
    )
    (var-set last-comment-id new-comment-id)
    (ok new-comment-id)
  )
)

;; Read functions
(define-read-only (get-idea (idea-id uint))
  (map-get? ideas {id: idea-id})
)

(define-read-only (get-collection (collection-id uint))
  (map-get? collections {id: collection-id})
)

(define-read-only (get-comment (idea-id uint) (comment-id uint))
  (map-get? comments {idea-id: idea-id, comment-id: comment-id})
)

(define-read-only (get-total-rewards-distributed)
  (var-get total-rewards-distributed)
)
