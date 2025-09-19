# Genos

## Overview

Genos is a decentralized genomic data marketplace that enables secure registration, controlled access, and research collaboration for genomic datasets. It supports researcher verification, genome access requests, approval workflows, and trust-based reputation management.

## Features

* Register genomic datasets with encrypted hashes and metadata
* Register scientists with qualifications and organizational affiliations
* Request and approve access to genomic datasets
* Contract-admin verification of scientists
* Trust score and reputation management for researchers
* Query and track genome details, scientist profiles, and access status

## Data Structures

* **genomes**: Stores dataset metadata, holder, cost, and accessibility
* **genome-access**: Tracks approved scientist access to genomes
* **scientists**: Stores scientist registration details, verification, and trust score
* **access-queries**: Manages dataset access requests and their approval states
* **scientist-contributions**: Tracks researcher contributions
* **genome-count**: Global counter for registered genomes
* **contract-admin**: Contract administrator for governance

## Validation Functions

* `validate-cost`: Ensures dataset cost is within valid limits
* `validate-query-id`: Ensures query IDs are valid
* `validate-scientist`: Checks scientist registration status
* `validate-rating`: Ensures trust score is within range

## Key Functions

* `register-genome`: Register a new genomic dataset
* `register-scientist`: Register a scientist with qualifications
* `request-access`: Request access to a genome dataset
* `approve-access`: Approve scientist access to a genome dataset
* `verify-scientist`: Verify scientist identity (admin only)
* `update-reputation`: Update trust score of a scientist (admin only)

## Read-Only Functions

* `get-genome-details`: Retrieve details of a genomic dataset
* `get-scientist-profile`: Retrieve scientist profile
* `get-access-status`: Check if a scientist has genome access

## Error Handling

* `u1`: Unauthorized
* `u2`: Invalid genome
* `u3`: Already handled
* `u4`: Transaction failed
* `u5`: Invalid arguments
* `u6`: Invalid cost
* `u7`: Invalid query
* `u8`: Scientist not found
* `u9`: Invalid rating
