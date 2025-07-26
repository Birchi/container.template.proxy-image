# General
## Description
## Scripts
### Pull
```
./scripts/pull.sh --name my_image --version latest --registry docker.io --registry-image-name registry_image --registry-image-version latest
```
### Cleanup
```
./scripts/cleanup.sh --name my_image --version latest
```
### Deploy
```
./scripts/deploy.sh --name my_image --version latest --registry my.registry.com --registry-username username --registry-password password
```
### Start
```
./scripts/start.sh --name my_container --image my_image --version latest
```
### Enter
```
./scripts/enter.sh --name my_container --workdir / --shell /bin/bash
```