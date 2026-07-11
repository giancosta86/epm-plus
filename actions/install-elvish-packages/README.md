# install-elvish-packages

Installs packages for the **Elvish** shell, supporting the extended format introduced by [epm-plus](https://github.com/giancosta86/epm-plus).

## 🃏 Example

```yaml
steps:
  - uses: giancosta86/epm-plus/actions/install-elvish-packages@main
    with:
      packages: github.com/giancosta86/primrose@v1, github.com/giancosta86/astral-bridge@v1
```

## 💡 How it works

1. Patch `epm` with **epm-plus**.

1. Consider what to install:
   1. If at least one comma-separated package has been specified, install the required packages via the patched `epm:install`.

   1. Otherwise, run `epm:install` to perform a _metadata-driven install_ within `working-directory`.

## ☑️ Requirements

The Elvish shell must be already installed on the system.

## 📥 Inputs

|        Name         |    Type    |                          Description                           | Default value |
| :-----------------: | :--------: | :------------------------------------------------------------: | :-----------: |
|     `packages`      | **string** |  **Comma-separated** `<name>[@<version>]` packages to install  |               |
| `working-directory` | **string** | Directory containing **metadata.json**, if `packages` is empty |     **.**     |

## 🌐 Further references

- [epm-plus](../../README.md) - _Package versioning for epm in Elvish_
