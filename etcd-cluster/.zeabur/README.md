# Zeabur Template Assets

This directory contains assets for the Zeabur template marketplace.

## Cover Image

To add a cover image:

1. Create a cover image (recommended size: 1200x630px)
2. Save it as `cover.png` in the etcd-cluster directory
3. Upload to GitHub and get the raw URL
4. Update the `coverImage` field in `zeabur-template.yaml`

Example:
```yaml
coverImage: https://raw.githubusercontent.com/your-username/zeabur-template/main/etcd-cluster/cover.png
```

## Icon

The template uses the official etcd icon from CNCF artwork:
```yaml
icon: https://raw.githubusercontent.com/cncf/artwork/master/projects/etcd/icon/color/etcd-icon-color.svg
```

## Template Structure

```
etcd-cluster/
├── .zeabur/
│   └── README.md
├── docker-compose.yml
├── zeabur-template.yaml
├── test.sh
└── README.md
```
