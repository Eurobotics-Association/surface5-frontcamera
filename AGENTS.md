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
