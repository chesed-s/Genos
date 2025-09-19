;; Genomic Data Marketplace
;; Implements a decentralized marketplace for genomic data

;; Constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-GENOME (err u2))
(define-constant ERR-ALREADY-HANDLED (err u3))
(define-constant ERR-TRANSACTION-FAILED (err u4))
(define-constant ERR-INVALID-ARGS (err u5))
(define-constant ERR-INVALID-COST (err u6))
(define-constant ERR-INVALID-QUERY (err u7))
(define-constant ERR-SCIENTIST-NOT-FOUND (err u8))
(define-constant ERR-INVALID-RATING (err u9))

;; Configuration Constants
(define-constant MAX-COST u1000000000000) ;; 1 million STX
(define-constant MAX-QUERY-ID u1000000)

;; Data Variables
(define-data-var genome-count uint u0)

;; Maps
(define-map genomes
    uint
    {
        holder: principal,
        encrypted-genome-hash: (string-utf8 256),
        metadata-hash: (string-utf8 256),
        cost: uint,
        is-accessible: bool
    }
)

(define-map genome-access {genome-id: uint, scientist: principal} bool)

(define-map scientists
    principal
    {
        name: (string-utf8 100),
        organization: (string-utf8 100),
        qualifications: (string-utf8 256),
        is-verified: bool,
        trust-score: uint
    }
)

(define-map access-queries
    {genome-id: uint, query-id: uint}
    {
        scientist: principal,
        approved: bool,
        handled: bool
    }
)

(define-map scientist-contributions principal uint)

;; Governance
(define-data-var contract-admin principal tx-sender)

;; Validation Functions
(define-private (validate-cost (cost uint))
    (and (> cost u0) (<= cost MAX-COST)))

(define-private (validate-query-id (query-id uint))
    (<= query-id MAX-QUERY-ID))

(define-private (validate-scientist (scientist principal))
    (is-some (map-get? scientists scientist)))

(define-private (validate-rating (rating uint))
    (<= rating u100))

;; Authorization check
(define-private (is-contract-admin)
    (is-eq tx-sender (var-get contract-admin)))

;; Dataset Management
(define-public (register-genome 
    (encrypted-genome-hash (string-utf8 256))
    (metadata-hash (string-utf8 256))
    (cost uint))
    (let
        ((genome-id (var-get genome-count)))
        (asserts! (validate-cost cost) ERR-INVALID-COST)
        (asserts! (and
            (> (len encrypted-genome-hash) u0)
            (> (len metadata-hash) u0))
            ERR-INVALID-ARGS)
        
        (begin
            (map-set genomes genome-id
                {
                    holder: tx-sender,
                    encrypted-genome-hash: encrypted-genome-hash,
                    metadata-hash: metadata-hash,
                    cost: cost,
                    is-accessible: true
                })
            (var-set genome-count (+ genome-id u1))
            (ok genome-id))))

;; Researcher Registration
(define-public (register-scientist 
    (name (string-utf8 100))
    (organization (string-utf8 100))
    (qualifications (string-utf8 256)))
    (if (and
            (> (len name) u0)
            (> (len organization) u0)
            (> (len qualifications) u0))
        (begin
            (map-set scientists tx-sender
                {
                    name: name,
                    organization: organization,
                    qualifications: qualifications,
                    is-verified: false,
                    trust-score: u0
                })
            (ok true))
        ERR-INVALID-ARGS))

;; Access Management
(define-public (request-access (genome-id uint))
    (let ((genome (unwrap! (map-get? genomes genome-id) ERR-INVALID-GENOME)))
        (if (get is-accessible genome)
            (begin
                (map-set access-queries 
                    {genome-id: genome-id, query-id: u0}
                    {
                        scientist: tx-sender,
                        approved: false,
                        handled: false
                    })
                (ok true))
            ERR-INVALID-GENOME)))

(define-public (approve-access (genome-id uint) (query-id uint))
    (let
        (
            (genome (unwrap! (map-get? genomes genome-id) ERR-INVALID-GENOME))
            (query (unwrap! (map-get? access-queries {genome-id: genome-id, query-id: query-id}) ERR-INVALID-GENOME))
        )
        (asserts! (validate-query-id query-id) ERR-INVALID-QUERY)
        (asserts! (and
            (is-eq (get holder genome) tx-sender)
            (not (get handled query)))
            ERR-UNAUTHORIZED)
        
        (begin
            (map-set access-queries
                {genome-id: genome-id, query-id: query-id}
                {
                    scientist: (get scientist query),
                    approved: true,
                    handled: true
                })
            (map-set genome-access
                {genome-id: genome-id, scientist: (get scientist query)}
                true)
            (ok true))))

;; Researcher Verification
(define-public (verify-scientist (scientist principal))
    (begin
        (asserts! (is-contract-admin) ERR-UNAUTHORIZED)
        (asserts! (validate-scientist scientist) ERR-SCIENTIST-NOT-FOUND)
        
        (match (map-get? scientists scientist)
            scientist-data (begin
                (map-set scientists scientist
                    (merge scientist-data {is-verified: true}))
                (ok true))
            ERR-INVALID-ARGS)))

;; Reputation Management
(define-public (update-reputation (scientist principal) (rating uint))
    (begin
        (asserts! (is-contract-admin) ERR-UNAUTHORIZED)
        (asserts! (validate-scientist scientist) ERR-SCIENTIST-NOT-FOUND)
        (asserts! (validate-rating rating) ERR-INVALID-RATING)
        
        (match (map-get? scientists scientist)
            scientist-data (begin
                (map-set scientists scientist
                    (merge scientist-data {trust-score: rating}))
                (ok true))
            ERR-INVALID-ARGS)))

;; Read-only functions
(define-read-only (get-genome-details (genome-id uint))
    (map-get? genomes genome-id))

(define-read-only (get-scientist-profile (scientist principal))
    (map-get? scientists scientist))

(define-read-only (get-access-status (genome-id uint) (scientist principal))
    (default-to false
        (map-get? genome-access {genome-id: genome-id, scientist: scientist})))