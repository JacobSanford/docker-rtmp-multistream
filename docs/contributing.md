---
title: Contributing to Documentation
description: Style guide and best practices for docker-rtmp-multistream documentation
audience: developers
doc_type: reference
tags: [contributing, style-guide, documentation, standards]
status: ready
owner: maintainers
lastReviewed: 2025-11-08
version: 1.x
---

# Contributing to Documentation

## Adding Images

When adding screenshots or diagrams:

1. **Use descriptive file names**: `twitch-dashboard-stream-key.png` not `screenshot1.png`
2. **Optimize size**: Max 500KB per image; use PNG for screenshots, SVG for diagrams
3. **Always include alt text**:
   ```markdown
   ![Screenshot of Twitch dashboard showing stream key location](images/twitch-dashboard-stream-key.png)
   ```
4. **Store in**: `docs/images/{section}/` (e.g., `docs/images/services/twitch-dashboard.png`)

## Style Guide

### Terminology

Use consistent terminology and capitalization throughout documentation:

- **Docker** (not "docker" or "DOCKER")
- **GitHub** (not "github" or "GITHUB")
- **docker compose** (not "docker-compose" or "Docker Compose")
- **FFmpeg** (not "ffmpeg" or "FFMPEG")
- **nginx** (not "Nginx" or "NGINX")
- **stream key** (lowercase in body text)
- **environment variable** (not "env var" in formal documentation)

### Headings

- Use sentence case: "Quick start guide" not "Quick Start Guide"
- Keep headings short and descriptive
- Don't skip heading levels (h2 → h4)

### Code Blocks

Always include a language tag:

````markdown
```bash
docker compose up
```
````

For placeholders, use angle brackets:

```bash
rtmp://<relay-ip>:1935/relay
```

### Links

- Use descriptive link text (not "click here")
- Add `{target="_blank"}` for external links
- Use relative paths for internal links: `../services/twitch.md`

## Front Matter

All documentation pages should include front matter:

```yaml
---
title: Page Title
description: One-sentence summary for search
audience: users|operators|developers
doc_type: tutorial|howto|explanation|reference
tags: [relevant, tags]
lastReviewed: YYYY-MM-DD
version: 1.x
---
```

## Avoiding Staleness

- **Don't hardcode version numbers** in prose (use "latest" or reference variables)
- **Don't include test counts** or specific numbers that change frequently
- **Don't duplicate lists** that are maintained elsewhere (link to the source instead)
- **Update `lastReviewed`** date when making significant changes

## Testing Documentation

Before submitting:

1. Build locally: `mkdocs serve`
2. Check for broken links (CI will verify)
3. Verify code examples are copy-pasteable
4. Test any commands/examples you've added

## See Also

- [Testing Guide](developer/testing.md) - Running and writing tests
- [Adding Services Overview](developer/adding-services/overview.md) - Extending the system
