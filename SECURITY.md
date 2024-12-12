# Security Policy

## Vulnerability Mitigations

### CVE-2024-21510 - Sinatra

**Vulnerability:** Sinatra vulnerable to Reliance on Untrusted Inputs in a Security Decision

**Mitigation:** This vulnerability affects Sinatra when used for parsing HTTP requests. In our application, Sinatra is not directly used for this purpose. It is a dependency of Resque, which we use for background job processing. The vulnerable component of Sinatra is not exercised in our usage context, therefore the risk is minimal.

**Actions Taken:**
1. We have documented this issue and our mitigation strategy.
2. We are monitoring for updates to Resque that might include a patched version of Sinatra.
3. We have verified that our usage of Resque does not expose Sinatra to untrusted input in our application setup.
4. We have configured bundler-audit to ignore this specific vulnerability in our CI/CD pipeline.

**Ongoing Measures:**
1. Regular review of dependencies and their security advisories.
2. Periodic assessment of our usage of Resque to ensure it remains unexposed to the vulnerable Sinatra components.

### Advisory GHSA-vfm5-rmrh-j26v - Action Dispatch 2024-12-10

**Vulnerability:**

Source: https://github.com/rails/rails/security/advisories/GHSA-vfm5-rmrh-j26v
NVD: https://nvd.nist.gov/vuln/detail/CVE-2024-54133

There is a possible Cross Site Scripting (XSS) vulnerability in the content_security_policy helper in Action Pack.

Applications which set Content-Security-Policy (CSP) headers dynamically from untrusted user input may be vulnerable to carefully crafted inputs being able to inject new directives into the CSP. This could lead to a bypass of the CSP and its protection against XSS and other attacks.

**Mitigation:**

No mitigation required as we are not vulnerable.

We do not dynamically set our CSP values using user input.

This specific security advisory has been added to the bundler audit ignore file.