# AI Use Policy
Contributors may use generative AI tools (e.g., GitHub Copilot, ChatGPT) to assist in writing code, documentation, and tests under the following conditions:

**TL;DR**
- **Not used for:** architecture/general structure, production bug fixes, security- or privacy-affecting code.
- **Allowed:** documentation edits, test scaffolding, refactors that preserve behavior, formatting/linters, issue triage.
- **Disclosure required** for any AI assistance (see PR template).

**Rationale**
We follow a provenance-first approach similar to projects that restrict AI-generated code to protect DCO/licensing and quality. See [QEMU’s policy for background.](https://www.qemu.org/docs/master/devel/code-provenance.html)
(Contributors must be able to attest authorship and rights; AI outputs can lack clear provenance.)

**Rules**
1. **Disclosure:** PRs must answer the AI assistance questions (tool/version, what was generated, links to prompts/inputs where feasible).
2. **Human review:** A maintainer must verify/modify AI-assisted changes.
3. **No verbatim vendor snippets** unless license is explicit and compatible.
4. **Exceptions:** by maintainer approval; must be documented in the PR.

_Last updated: 2025-10-07_
