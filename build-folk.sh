#!/bin/bash
set -euo pipefail

# =====================================
# Folk Live-Build Master Script
# =====================================

# Directories
BUILD_DIR="${BUILD_DIR:-$PWD}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/output}"

mkdir -p "$OUTPUT_DIR"

log() {
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] [${1}] ${2}"
}

log "INFO" "Starting Folk live-build"
log "INFO" "Build directory: $BUILD_DIR"
log "INFO" "Output directory: $OUTPUT_DIR"

# STEP0: Install dependencies
log "STEP0" "Installing required packages"
sudo apt-get update
sudo apt-get install -y \
  git build-essential live-build debootstrap \
  systemd-container squashfs-tools xorriso \
  genisoimage parted dosfstools zip sudo \
  procps uidmap fakeroot eatmydata

# STEP1: Clone repo if missing
if [[ ! -d "$BUILD_DIR/folk" ]]; then
  log "STEP1" "Cloning Folk repository..."
  git clone https://github.com/FolkComputer/folk.git "$BUILD_DIR/folk"
else
  log "STEP1" "Folk repository already exists, pulling latest..."
  git -C "$BUILD_DIR/folk" pull
fi

# STEP2: Initialize submodules & build apriltag
log "STEP2" "Initializing submodules..."
git -C "$BUILD_DIR/folk" submodule update --init --recursive

log "STEP2" "Building apriltag library..."
APRILTAG_DIR="$BUILD_DIR/folk/live-build/config/includes.chroot_after_packages/home/folk/apriltag"
make -C "$APRILTAG_DIR" libapriltag.a libapriltag.so

# STEP3: Clean previous live-build
log "STEP3" "Cleaning previous live-build..."
cd "$BUILD_DIR/folk/live-build"
sudo lb clean

# STEP4: Configure live-build
log "STEP4" "Configuring live-build..."
sudo lb config

# STEP5: Bootstrap live-build
log "STEP5" "Bootstrapping live-build..."
sudo lb bootstrap

# STEP6: Build live-build
log "STEP6" "Running lb build..."
sudo lb build

# STEP7: Collect outputs
log "STEP7" "Copying built images to output directory..."
cp -r live-image-* "$OUTPUT_DIR/" || true
cp -r binary* "$OUTPUT_DIR/" || true

log "INFO" "Folk live-build complete!"
