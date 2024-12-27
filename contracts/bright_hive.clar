;; BrightHive - Decentralized Brainstorming Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map ideas
  { id: uint }
  {
    title: (string-ascii 100),
    description: (string-utf8 1000),
    creator: principal,
    votes: uint,
    created-at: uint,
    collection-id: uint
  }
)

(define-map collections
  { id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    created-at: uint
  }
)

(define-map comments
  { idea-id: uint, comment-id: uint }
  {
    text: (string-utf8 500),
    author: principal,
    created-at: uint
  }
)

(define-map idea-votes
  { idea-id: uint, voter: principal }
  { voted: bool }
)

;; Data variables
(define-data-var last-idea-id uint u0)
(define-data-var last-collection-id uint u0)
(define-data-var last-comment-id uint u0)

;; Collection functions
(define-public (create-collection (name (string-ascii 100)))
  (let
    (
      (new-id (+ (var-get last-collection-id) u1))
    )
    (map-set collections
      { id: new-id }
      {
        name: name,
        owner: tx-sender,
        created-at: block-height
      }
    )
    (var-set last-collection-id new-id)
    (ok new-id)
  )
)

;; Idea functions
(define-public (create-idea (title (string-ascii 100)) (description (string-utf8 1000)) (collection-id uint))
  (let
    (
      (new-id (+ (var-get last-idea-id) u1))
    )
    (map-set ideas
      { id: new-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        votes: u0,
        created-at: block-height,
        collection-id: collection-id
      }
    )
    (var-set last-idea-id new-id)
    (ok new-id)
  )
)

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
        created-at: block-height
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