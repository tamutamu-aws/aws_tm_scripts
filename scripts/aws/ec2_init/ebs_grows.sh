#!/bin/bash
set -euo pipefail


### EBS Grows
LANG="en_US.UTF-8" growpart /dev/xvda 1


### Reboot for EBS Disk change.
reboot
