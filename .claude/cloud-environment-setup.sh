#!/bin/bash
# Setup script for the team's Claude cloud environment (docs/team-setup.md).
# Paste it into the environment's "Setup script" box. It runs before Claude
# starts, and the result is cached, so new sessions start with malloyyo ready.
npm install -g @malloydata/malloyyo || true
