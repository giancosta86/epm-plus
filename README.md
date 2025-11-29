# epm-plus

_Package versioning for epm in Elvish_

**epm-plus** is a minimalist but effective library, designed to support _multiple coexisting versions_ of Elvish packages - especially from _Git repositories_ - following the simple set of rules described below; the changes introduced are _fully backwards-compatible_, enabling users to _choose their favorite versioning style_.

## Installation

As usual, the package can be downloaded via `epm`:

```elvish
use epm

epm:install github.com/giancosta86/epm-plus
```

Then, it is necessary to _patch epm_ - replacing some of its functions - by running:

```elvish
use github.com/giancosta86/epm-plus/epm-plus

epm-plus:patch-epm
```

**Please, note**: patching epm will _not_ alter the standard package provided by Elvish - only its in-memory representation! As a consequence, you'll need to _run this command whenever you start a shell_ - especially by adding the lines in the previous snippet to the `rc.elv` file.

## Usage

For **Git-based packages**, one can now use `package-name@git-reference` in `epm install` and other commands - where `git-reference` could be a _tag_, a _branch_, a _commit_ - anything that can be the target of `git checkout`.

For example:

```elvish
epm:install github.com/giancosta86/epm-plus@v1.0.0+test2
```

As a plus, this notation is also supported in the `dependencies` list of the **metadata.json** package descriptor:

```json
{
  "dependencies": ["github.com/giancosta86/epm-plus@v1.0.0+test1"]
}
```

### Effects on metadata.json

**epm-plus** introduces the concept of **metadata-driven install**, which applies when running `epm:install` _without passing packages_: in this case, **epm** will install the dependencies listed _in the metadata descriptor within the current directory_ - failing if such file is missing.

As a plus, in addition to the usual `dependencies` field, the `devDependencies` field is now available - listing all the dependencies that must be installed **only** when performing a _metadata-driven install_.

The rationale for this extension resides in the fact that a library might need _support libraries_ - for example, the [velvet](https://github.com/giancosta86/velvet) testing system - only in contexts like _development_ or **CI/CD**; as a consequence, in lieu of having to _manually install_ such libraries, the `devDependencies` field will satisfy all the requirements in a _standardized_ way, via a simple `epm:install` execution.

### Effects on epm commands

By design, _epm will work as usual_, with a handful of brand-new _version-oriented_ features:

- Installing `package-name` creates the expected `$epm:managed-dir/package-name` directory - whereas installing, for example, `package-name@v1` will put its files into its `v1` subdirectory.

  Therefore, installing `package@v2` will create a sibling `v2` subdirectory.

  To access either package from anywhere:

  ```elvish
  use package-name/v1/some-module v1
  use package-name/v2/some-module v2
  ```

  One version can even access the other - for example, a script within **v2**'s root could contain:

  ```elvish
  use ../v1/some-module v1
  ```

  It is even possible - although not recommended, for cleaner versioning - to install _the default package_ (from the **main** branch) as well as _a specific reference_, which will be stored into _a subdirectory of the former_.

- `epm:install` now supports the idea of _metadata-driven install_ - i.e., when it's called _without packages_ from a directory containing a **metadata.json** descriptor.

  In this case:

  - all the packages listed in `dependencies` are installed, as usual

  - all the packages listed in `devDependencies` are installed as well - and this is _the only case_ where the field is taken into account; in particular, _dev dependencies_ are **never** installed as _transitive dependencies_.

  Of course, if the command is invoked _without packages_ from a directory not containing **metadata.json**, it will fail, as usual.

- `epm:dest` returns:

  - for `package-name`: `$epm:managed-dir/package-name`, as usual

  - for `package-name@version`: `$epm:managed-dir/package-name/version`

- `epm:list` (as well as `epm:installed`) changes as follows _for Git packages_:

  - if the package directory contains _no regular files_ - which means it is merely a package root directory containing **version-related directories**:

    - every single subdirectory will be listed, with the format: `<package-name>@<version>`

  - otherwise, just `<package-name>` will be displayed, as usual

- `epm:metadata`, in its `src` field, always shows the **package url** _without_ Git reference

- `epm:uninstall` accepts the following package formats:

  - `package-name@version`: only _the specific version subdirectory_ will be deleted

  - `package-name`: _the entire package directory will be deleted_ - including the version-related sub-directories

## Further references

- [epm](https://elv.sh/ref/epm.html) - the official documentation for the `epm` module

- [velvet](https://github.com/giancosta86/velvet) - minimalist, expressive test framework for Elvish

- [Elvish](https://elv.sh/)
