---
title: Quality Optimization
description: Optimizing stream quality for different content types and constraints
audience: users
doc_type: explanation
tags: [quality, optimization, resolution, bitrate, frame-rate]
lastReviewed: 2025-11-05
version: 1.x
---

# Quality Optimization

This page covers strategies for optimizing stream quality based on your content type and resource constraints.

## Quality Fundamentals

Stream quality is determined by three primary factors:

1. **Resolution**: Image dimensions (e.g., 1920x1080, 1280x720)
2. **Frame Rate**: Frames per second (e.g., 60fps, 30fps)
3. **Bitrate**: Data transmitted per second (e.g., 6000 kbps)

Higher values for each = better quality, but also:

- Increased bandwidth usage (see [Bandwidth Requirements](bandwidth.md))
- Increased CPU usage for encoding (see [Hardware Requirements](hardware.md))

## Content-Specific Optimization

Different stream content benefits from different quality priorities.

### High Motion Content

**Examples**: FPS games, racing games, fast-paced action, IRL streaming

**Optimization strategy**:

- **Prioritize frame rate** (60fps) for smooth motion
- **Accept lower resolution** (720p) to maintain frame rate
- Viewers perceive smooth motion as higher quality than static detail

**Recommended settings**: 720p @ 60fps

### High Detail Content

**Examples**: Strategy games, puzzle games, art streams, slow-paced content

**Optimization strategy**:

- **Prioritize resolution** (1080p) for crisp detail
- **Accept lower frame rate** (30fps) since motion is minimal
- Static scenes benefit more from resolution than frame rate

**Recommended settings**: 1080p @ 30fps

## Balancing Quality and Resources

When optimizing, consider the relationship between quality, bandwidth, and CPU:

```
Higher Quality → More Bandwidth + More CPU
Lower Quality → Less Bandwidth + Less CPU
```

**If bandwidth-constrained**: Reduce resolution or frame rate (see [Bandwidth Requirements](bandwidth.md))

**If CPU-constrained**: Use faster encoder presets or disable encoding services (see [Hardware Requirements](hardware.md))

## See Also

- [Bandwidth Requirements](bandwidth.md) - Network bandwidth considerations
- [Hardware Requirements](hardware.md) - CPU and encoding performance
- [Services Overview](../services/overview.md) - Service pattern comparison
