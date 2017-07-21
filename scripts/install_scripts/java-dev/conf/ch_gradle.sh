#!/bin/bash
set -euo pipefail


if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [1.9 or 2.2.1]" >&2
  exit 1
fi

case $1 in
  1.9)
    sudo alternatives --set gradle /opt/gradle/gradle-1.9
    ;;
  2.2.1)
    sudo alternatives --set gradle /opt/gradle/gradle-2.2.1
    ;;
  *)
    echo "Usage: $0 [1.9 or 2.2.1]" >&2
    exit 1
    ;;
esac

java -version

echo
echo "GRADLE_HOME"
echo "   "`readlink -f ${GRADLE_HOME}`
