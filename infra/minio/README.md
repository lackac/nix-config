# MinIO OpenTofu Stack

This stack manages MinIO buckets, users, access keys, and IAM policies.

State is already migrated to MinIO S3 backend.

## Environment Variables

Run OpenTofu through the stack environment wrapper:

```bash
./scripts/tofu-env.sh minio -- tofu -chdir=infra/minio plan
```

The wrapper injects all provider, managed credential, and backend authentication variables for the command it runs.

Secret file ownership:

- `secrets/boron.yaml`: MinIO runtime root credentials
- `secrets/tofu.yaml`: OpenTofu backend credential pair
- `secrets/carbon.yaml`: Mattermost S3 credential pair

## Commands

```bash
just tofu-init minio
just tofu-plan minio
just tofu-apply minio
```
