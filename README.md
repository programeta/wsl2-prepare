# WSL2-Prepare
## _The easier way to set-up a WSL2 environment for developers_

This project was created for the automatic initialization of a WSL2 environment to be able to work with the most popular development tools.
This script has been separated into several independent steps that completely configure the environment to start developing.

Some of the tools that are installed out of the box are:
- PHP
- Composer
- Docker
- Docker-compose
- DDEV
- Lando

## Requirements
- To have a local user 'dev' as will be our main non-root user.
- To use WSL2 under Ubuntu-22.04 and Ubuntu-24.04 distributions. Other distributions may be not compatible with.

## Installation
```sh
$ git clone https://github.com/programeta/wsl2-prepare.git
$ cd wsl2-prepare
$ sudo bash ./prepare.sh
```

If you would like to collaborate with us in the development of this tool or find any incompatibility or bug, do not hesitate to contact us or commit the changes you think are necessary.

Special credit to:
- [programeta]
- [pgrandeg]

   [programeta]: <https://github.com/programeta>
   [pgrandeg]: <https://github.com/pgrandeg>
