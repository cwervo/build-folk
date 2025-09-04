#!/bin/bash
set -euo pipefail

# ==============================
# Folk Live-Build Local Script
# ==============================
# Author: Andrés
# Purpose: Run a Folk live-build with detailed logging and step numbers.
# ==============================

# Directories
BUILD_DIR="${HOME}/folk-build"
OUTPUT_DIR="${HOME}/folk-output"
CHROOT_DIR="${HOME}/folk-chroot"

log() { echo "[${1}] $2"; }

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$CHROOT_DIR"

# STEP0: Install required packages (Debian/Ubuntu)
log "STEP0" "Installing required packages"
sudo apt-get update
sudo apt-get install -y \
    git \
    build-essential \
    live-build \
    debootstrap \
    systemd-container \
    squashfs-tools \
    xorriso \
    genisoimage \
    parted \
    dosfstools \
    zip \
    sudo \
    procps \
    uidmap \
    fakeroot \
    eatmydata

# STEP1: Clone Folk repository
log "STEP1" "Cloning Folk repository"
if [ ! -d "$BUILD_DIR/folk" ]; then
    git clone https://github.com/FolkComputer/folk.git "$BUILD_DIR/folk"
else
    log "INFO" "Folk repo already exists, pulling latest changes"
    git -C "$BUILD_DIR/folk" pull
fi

# STEP2: Initialize submodules
log "STEP2" "Initializing git submodules"
git -C "$BUILD_DIR/folk" submodule update --init --recursive

# STEP3: Build apriltag library
log "STEP3" "Building apriltag library"
make -C "$BUILD_DIR/folk/live-build/config/includes.chroot_after_packages/home/folk/apriltag" libapriltag.a libapriltag.so

# STEP4: Clean previous live-build
log "STEP4" "Cleaning previous live-build"
cd "$BUILD_DIR/folk/live-build"
lb clean

# STEP5: Configure live-build
log "STEP5" "Configuring live-build"
lb config

# STEP6: Bootstrap live-build
log "STEP6" "Bootstrapping live-build"
lb bootstrap

# STEP7: Run live-build
log "STEP7" "Building live image"
lb build

# STEP8: Collect outputs
log "STEP8" "Copying build outputs"
cp -r "$BUILD_DIR/folk/live-build/live-image-*" "$OUTPUT_DIR/" || true
cp -r "$BUILD_DIR/folk/live-build/binary*" "$OUTPUT_DIR/" || true

log "DONE" "Folk live-build finished successfully!"
