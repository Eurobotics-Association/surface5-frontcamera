# Persistent project rules

- Target Ubuntu/Zorin generic kernel 7.x; current reference is
  `7.0.0-31-generic`.
- Do not solve the camera issue by downgrading to or permanently switching to
  the linux-surface 6.18 kernel. It is a comparison reference only.
- Work directly on `main` unless an experiment genuinely needs isolation.
- Commit and push useful milestones regularly.
- Privileged system changes require explicit operator approval with purpose,
  command, expected result, verification, rollback, and risk.
- Never commit captured personal camera imagery or machine secrets.
- Prefer minimal fixes with upstream provenance.
- Every installed fix needs documented rollback.
- Validate actual moving frames and restart resilience; enumeration alone is
  insufficient.
- Prepare verified results for existing upstream/community discussions. Do not
  create duplicate reports or post externally under the operator's identity
  without explicit approval; never post speculative results or personal data.
- Keep licensing explicit: kernel-derived code and derivative patches remain
  GPL-2.0-only as required by their upstream provenance; original project
  kernel tooling is GPL-2.0-only unless documented otherwise.
- Treat the first `7.0.0-31-generic` module install as a controlled experiment,
  not final deployment. Future maintenance tooling must inspect each target
  kernel's native `dw9719` aliases and never override a kernel that already
  exports `i2c:dw9719`; fail safely on API incompatibility.
