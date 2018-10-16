# Truststore
automate certs add/remove to truststore and show expiry date of each certificate in truststore

./TrustStore_script.sh --keystore <truststore_name> --password <password>

# Certificates CI

### Goal:
* Maintain one TrustStore for environment(s)
* Checkin a new Certificate(s) to certificates repository to run the CI process.
* New TrustStore will be deployed to the specific environment(s)

### Branching strategy
* certificates will have 3 branches.
  - qa    - QA environment certificate(s)
  - stage - Perf/stage environment certificate(s)
  - master - Production certificate(s)

### Repositories
* certificates-repository is for Certificates version control.
* truststore-repository is created to maintain TrustStore version control.
* scripts-repository is created to maintain the TrustStore script.

### How the pipeline is configured
* Checking the new certificate(s) in to certificates repository.
* Make sure you checkin the certificate(s) to __appropriate branch (qa, stage, master)__
* Certificates build plan will be triggered once the new certificate(s) are pushed in to certificates repository.
* The CI plan will run in 3 phases.
  - First phase: pull the latest TrustStore from truststore-repository and the script from scripts-repository
  - Second phase: CI to **add new certificates and show us the certificate expiry dates.**
  - Third Phase: Check-in the latest TrustStore to truststore-repository.
  - Forth Phase: Deploy the latest TrustStore in to appropriate environment.

## Dependencies

certificates-repository
scripts-repository


Note: I have used Bitbucket and Bamboo to implement this CI process.
