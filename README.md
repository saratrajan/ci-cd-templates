# CI/CD templates

Reusable GitHub Actions workflows, kept in one place so that every repository
runs the same checks and a fix is made once. All of them run on GitHub-hosted
runners.

## What is here

GitHub requires reusable workflows to sit directly in `.github/workflows/`, so
the categories are in the file names: `lint-`, `test-`, `build-` and `scan-`.

### Lint

| Workflow | Tool | Settings it reads from your repository |
| --- | --- | --- |
| [`lint-python.yml`](.github/workflows/lint-python.yml) | ruff | `pyproject.toml` or `ruff.toml` |
| [`lint-markdown.yml`](.github/workflows/lint-markdown.yml) | markdownlint | `.markdownlint.yaml` for rules, `.markdownlintignore` for folders to skip |
| [`lint-shell.yml`](.github/workflows/lint-shell.yml) | ShellCheck | `.shellcheckrc` |
| [`lint-powershell.yml`](.github/workflows/lint-powershell.yml) | PSScriptAnalyzer | a settings file you name in `settings` |

### Test and build

| Workflow | What it does |
| --- | --- |
| [`test-python.yml`](.github/workflows/test-python.yml) | Installs the project and runs pytest, on one or more Python versions |
| [`build-python.yml`](.github/workflows/build-python.yml) | Builds the sdist and wheel, checks them with twine, uploads them as an artifact |
| [`build-java-springboot.yml`](.github/workflows/build-java-springboot.yml) | Builds and tests a Spring Boot service with Maven or Gradle, uploads the jar as an artifact |

### Compliance and security

| Workflow | Tool | What it finds |
| --- | --- | --- |
| [`scan-secrets.yml`](.github/workflows/scan-secrets.yml) | gitleaks | Keys, tokens and passwords in the commits of a push or pull request |
| [`scan-trivy.yml`](.github/workflows/scan-trivy.yml) | Trivy | Known vulnerabilities in dependencies, infrastructure misconfigurations, and secrets, in the repository or a container image |
| [`scan-codeql.yml`](.github/workflows/scan-codeql.yml) | CodeQL | Security flaws in your own code (static analysis) |
| [`scan-dependencies.yml`](.github/workflows/scan-dependencies.yml) | Dependency review | A pull request that adds a vulnerable dependency or a disallowed licence |

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
  lint-python:
    uses: saratrajan/ci-cd-templates/.github/workflows/lint-python.yml@v1

  lint-markdown:
    uses: saratrajan/ci-cd-templates/.github/workflows/lint-markdown.yml@v1

  tests:
    uses: saratrajan/ci-cd-templates/.github/workflows/test-python.yml@v1
    with:
      python-versions: '["3.12", "3.13"]'

  secrets:
    uses: saratrajan/ci-cd-templates/.github/workflows/scan-secrets.yml@v1

  trivy:
    uses: saratrajan/ci-cd-templates/.github/workflows/scan-trivy.yml@v1
```

A Spring Boot service would call the Java build in place of the Python jobs:

```yaml
  build:
    uses: saratrajan/ci-cd-templates/.github/workflows/build-java-springboot.yml@v1
    with:
      java-version: "21"
```

## Inputs

Every workflow also takes `runs-on` (default `ubuntu-latest`).

### `lint-python.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-version` | `"3.13"` | Python version to run ruff on |
| `ruff-version` | `">=0.8"` | A pip version specifier for ruff |
| `paths` | `"."` | Files or folders to lint, separated by spaces |

### `lint-markdown.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `globs` | `'"**/*.md"'` | Files to lint, as quoted glob patterns separated by spaces |
| `markdownlint-version` | `"0.50.1"` | Version of the markdownlint command-line tool |

### `lint-shell.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `patterns` | `"*.sh *.bash"` | File name patterns to lint, found anywhere in the repository |
| `severity` | `warning` | The least serious finding that fails the job: `error`, `warning`, `info` or `style` |

### `lint-powershell.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `path` | `"."` | Folder searched for `.ps1`, `.psm1` and `.psd1` files |
| `severity` | `"Error,Warning"` | Severities that fail the job |
| `settings` | empty | Path to a PSScriptAnalyzer settings file in your repository |

### `test-python.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-versions` | `'["3.13"]'` | A JSON list of Python versions; one job runs per version |
| `install` | `-e ".[dev]"` | Arguments to `pip install` for the project |
| `pre-install` | empty | Arguments to a `pip install` that must run first, for example a CPU-only PyTorch with its own index URL |
| `test-command` | `python -m pytest -q` | The command that runs the tests |
| `cache-dependency-path` | `pyproject.toml` | The file that decides when the pip cache is refreshed |

The `install`, `pre-install` and `test-command` inputs are run as shell
commands. They come from your own workflow file, so treat them as code: never
build them from pull request titles, branch names or other text a contributor
controls.

### `build-python.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-version` | `"3.13"` | Python version to build with |
| `working-directory` | `"."` | Folder that holds `pyproject.toml` |
| `artifact-name` | `python-dist` | Name of the uploaded artifact; empty skips the upload |

### `build-java-springboot.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `java-version` | `"21"` | Java version |
| `distribution` | `temurin` | JDK distribution |
| `build-tool` | `auto` | `maven`, `gradle`, or `auto` to choose by which build file is present. A wrapper (`mvnw`, `gradlew`) is used when there is one |
| `working-directory` | `"."` | Folder that holds `pom.xml` or `build.gradle` |
| `skip-tests` | `false` | Build without running the tests |
| `artifact-name` | `app-jar` | Name of the uploaded artifact; empty skips the upload |

### `scan-secrets.yml`

| Secret | Meaning |
| --- | --- |
| `GITLEAKS_LICENSE` | Only needed when the calling repository belongs to an organisation |

The calling workflow must grant `contents: read` and `pull-requests: read`.

### `scan-trivy.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `scan-type` | `fs` | `fs` for the repository's files, `image` for a container image |
| `scan-ref` | `"."` | For `fs`, the folder to scan |
| `image-ref` | empty | For `image`, the image to scan |
| `scanners` | `"vuln,misconfig,secret"` | What to look for; `license` is also available |
| `severity` | `"CRITICAL,HIGH"` | Severities that fail the job |
| `ignore-unfixed` | `true` | Ignore vulnerabilities with no fixed version yet |
| `fail-on-findings` | `true` | Fail the job when something is found; `false` only reports |
| `upload-sarif` | `false` | Also send results to the Security tab. The calling job must then grant `security-events: write` |

### `scan-codeql.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `languages` | required | A JSON list, for example `'["python"]'` or `'["java-kotlin"]'` |
| `build-mode` | `none` | `none` for interpreted languages, `autobuild` for compiled ones |
| `queries` | `security-extended` | Query suite |

The calling job must grant `security-events: write`. Free for public
repositories; private ones need GitHub Advanced Security.

### `scan-dependencies.yml`

| Input | Default | Meaning |
| --- | --- | --- |
| `fail-on-severity` | `high` | The least serious vulnerability that fails the job |
| `deny-licenses` | empty | Licences to refuse, as SPDX ids separated by commas |

Runs on pull requests only; on other events the job is skipped. The calling repository must have the
dependency graph switched on (Settings, Advanced Security, Dependency graph);
without it the job fails with "Forbidden". This template is the one not
exercised by this repository's self-check, for that reason.

## Versions

Call the templates by tag, as in `@v1`, not by branch. `v1` moves forward with
changes that do not break callers; a change that does gets `v2`, and `v1`
stays where it was. To pin exactly, use a full commit SHA in place of the tag.

## Changing a template

This repository is trunk-based: branch from `main`, open a pull request, and
merge when the checks pass. Its self-check validates every workflow file with
actionlint and runs each template against a small fixture in
`tests/fixtures/`, so a broken template is caught here first. A new template
needs a fixture and a job in `self-check.yml`.

## Licence

[MIT](LICENSE).
