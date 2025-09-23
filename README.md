# Artist Tally Tool

A containerized Dart application that fetches artist tally data from an API and sends email reports via SendWithUs.

## Required Runtime Environment Variables

|Variable|Description|Example|
----------|--------------|-------|
`ARTIST_TALLY_API_DOMAIN`|Domain to use as API gateway|`example.com`|
`ARTIST_TALLY_ENV`|Environment|`production` or `development`|
`ARTIST_TALLY_SWU_KEY`|sendwithus.com API key|`your_api_key`|
`ARTIST_TALLY_SWU_TEMPLATE_ID`|sendwithus.com email template id|`tem_abc_123`|
`ARTIST_TALLY_SENDER`|JSON-serialized sender address|`{"name":"Joshua Harms", "address":"joshua@example.com","replyTo":"joshua@example.com"}`|
`ARTIST_TALLY_PRIMARY_RECIPIENT`|JSON-serialized recipient address|`{"name":"Joshua Harms", "address":"joshua@example.com"}`|
`ARTIST_TALLY_CC_LIST`|JSON-serialized list of CC recipients|`[{"name":"Joshua Harms", "address":"joshua@example.com"}]`|

## GitHub Actions Setup

This repository includes a GitHub Actions workflow that automatically builds and pushes container images to GitHub Container Registry when code is pushed to the main branch.
