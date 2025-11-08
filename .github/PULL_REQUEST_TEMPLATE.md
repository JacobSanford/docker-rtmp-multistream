# Pull Request

## Description

Brief description of what this PR does.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (describe):

## Documentation Changes

If this PR updates documentation, please ensure:

- [ ] Front matter added to new/updated pages:
  ```yaml
  ---
  title: Page Title
  description: One-sentence summary
  audience: users|operators|developers
  doc_type: tutorial|howto|explanation|reference
  tags: [relevant, tags]
  lastReviewed: YYYY-MM-DD
  version: 1.x
  ---
  ```
- [ ] Internal links tested (run `mkdocs serve` locally)
- [ ] Code examples tested/verified
- [ ] Added to `mkdocs.yml` nav if new page
- [ ] "See Also" section updated with relevant cross-references
- [ ] No hardcoded version numbers or test counts
- [ ] Images optimized (<500KB) and include alt text
- [ ] Followed [contributing guidelines](../docs/contributing.md)

## Testing

- [ ] All tests pass locally (`./tests/test.sh`)
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my changes
- [ ] I have commented my code where necessary
- [ ] My changes generate no new warnings
- [ ] Any dependent changes have been merged
