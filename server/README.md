# Server job

## Build and push image

```bash
docker tag $(docker build . -q) ivribalko/new-content-notifier
docker push ivribalko/new-content-notifier
```

## Update Firestore

Put `account.json` into root folder and run without `--dry-run`:

```bash
docker run -it --rm $(docker build -q .) /root/server/bin/server.exe --dry-run --no-notify --google-acc $(cat account.json | tr -d '[:space:]') --firebase-web-key KEY
```

## Secrets

```bash
kubectl create secret generic firebase --from-literal=api-key=KEY
kubectl create secret generic google --from-file=account=account.json
```

## Deploy

```bash
kubectl create -f server/cronjob.yaml
```
