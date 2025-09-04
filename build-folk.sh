name: Folk Live-Build

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: debian:bookworm

    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y \
            git build-essential live-build debootstrap \
            systemd-container squashfs-tools xorriso \
            genisoimage parted dosfstools zip sudo \
            procps uidmap fakeroot eatmydata \
          && rm -rf /var/lib/apt/lists/*

      - name: Prepare Folk repo
        run: |
          mkdir -p /build
          cd /build
          if [ ! -d folk ]; then
            git clone https://github.com/FolkComputer/folk.git
          else
            cd folk && git pull
          fi
          cd folk/live-build
          git submodule update --init

      - name: Build apriltag library
        run: make -C config/includes.chroot_after_packages/home/folk/apriltag libapriltag.a libapriltag.so

      - name: Configure Debian archive URLs for chroot
        run: |
          mkdir -p config/archives
          cat <<'EOF' > config/archives/bookworm.list.chroot
deb http://archive.debian.org/debian bookworm main contrib non-free
deb http://archive.debian.org/debian bookworm-updates main contrib non-free
deb http://archive.debian.org/debian-security bookworm-security main contrib non-free
EOF
          echo 'Acquire::Check-Valid-Until "false";' > config/archives/99disable-check-valid-until.chroot

      - name: Build live image
        run: |
          set -eux
          # Clean previous build
          lb clean
          # Configure lb
          lb config
          # Bootstrap
          lb bootstrap
          # Build
          lb build
          # Copy outputs
          mkdir -p /build/output
          cp -r ./live-image-* ./binary* /build/output/ || true

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: folk-live-build
          path: /build/output