# CI/CD templates

Reusable GitHub Actions workflows, kept in one place so that every repository
runs the same checks and a fix is made once. All of them run on GitHub-hosted
runners.

## What is here

| Workflow | What it does | Settings it reads from your repository |
| --- | --- | --- |
| [`python-lint.yml`](.github/workflows/python-lint.yml) | Lints Python with ruff | `pyproject.toml` or `ruff.toml` |
| [`markdown-lint.yml`](.github/workflows/markdown-lint.yml) | Lints Markdown with markdownlint-cli2 | `.markdownlint-cli2.yaml` |
| [`python-tests.yml`](.github/workflows/python-tests.yml) | Installs the project and runs pytest, on one or more Python versions | `pyproject.toml` |
| [`secret-scan.yml`](.github/workflows/secret-scan.yml) | Scans the commits of a push or pull request for secrets with gitleaks | `.gitleaks.toml`, if present |

## Using them

Add a workflow to your repository, for example `.github/workflows/ci.yml`.
Your workflow decides when the checks run; the templates only define the jobs.
For trunk-based development, run them on every pull request and on every push
to `main`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read
  pull-requests: read   # needed by the secret scan

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  python-lint:
    uses: saratrajan/ci-cd-templates/.github/workflows/python-lint.yml@v1

  markdown-lint:
    uses: saratrajan/ci-cd-templates/.github/workflows/markdown-lint.yml@v1

  tests:
    uses: saratrajan/ci-cd-templates/.github/workflows/python-tests.yml@v1
    with:
      python-versions: '["3.12", "3.13"]'

  secrets:
    uses: saratrajan/ci-cd-templates/.github/workflows/secret-scan.yml@v1
```

## Inputs

### `python-lint.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-version` | `"3.13"` | Python version to run ruff on |
| `ruff-version` | `">=0.8"` | A pip version specifier for ruff |
| `paths` | `"."` | Files or folders to lint, separated by spaces |
| `runs-on` | `ubuntu-latest` | Runner label |

### `markdown-lint.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `globs` | empty | Files to lint. Empty means: use the globs in your `.markdownlint-cli2.yaml` |
| `runs-on` | `ubuntu-latest` | Runner label |

### `python-tests.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-versions` | `'["3.13"]'` | A JSON list of Python versions; one job runs per version |
| `install` | `-e ".[dev]"` | Arguments to `pip install` for the project |
| `pre-install` | empty | Arguments to a `pip install` that must run first, for example a CPU-only PyTorch with its own index URL |
| `test-command` | `python -m pytest -q` | The command that runs the tests |
| `cache-dependency-path` | `pyproject.toml` | The file that decides when the pip cache is refreshed |
| `runs-on` | `ubuntu-latest` | Runner label |

The `install`, `pre-install` and `test-command` inputs are run as shell
commands. They come from your own workflow file, so treat them as code: never
build them from pull request titles, branch names or other text a contributor
controls.

### `secret-scan.yml`

| Input or secret | Default | Meaning |
| --- | --- | --- |
| `runs-on` | `ubuntu-latest` | Runner label |
| `GITLEAKS_LICENSE` (secret) | none | Only needed when the calling repository belongs to an organisation |

The calling workflow must grant `contents: read` and `pull-requests: read`.

## Versions

Call the templates by tag, as in `@v1`, not by branch. `v1` moves forward with
changes that do not break callers; a change that does gets `v2`, and `v1`
stays where it was. To pin exactly, use a full commit SHA in place of the tag.

## Changing a template

This repository is trunk-based: branch from `main`, open a pull request, and
merge when the checks pass. Its own checks validate every workflow file with
actionlint and scan for secrets using the template itself.

## Licence

[MIT](LICENSE).
