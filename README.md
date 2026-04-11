Various scripts and configuration files I use.

To get started:
```sh
$ git clone git@github.com:rkj/dotfiles_rkj.git
$ cd dotfiles_rkj
$ ./bin/provision
$ ./init.sh
```

To add new files into the repo use:
```sh
$ ./adopt.sh ~/.file_name
$ ./adopt.sh --force ~/.file_name # overwrite an existing repo destination
```

Machine-local overrides belong in `env.local`, which is gitignored.

Example:
```sh
$ cat > env.local <<'EOF'
export DOTFILES_IS_WORK=1
EOF
```

`config/fish/conf.d/env.fish` loads both `env` and `env.local`, and `bin/provision`
uses `DOTFILES_IS_WORK=1` to enable work-machine behavior without committing
machine-specific settings into the repo.
