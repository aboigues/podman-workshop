#!/bin/bash

TP=$1

if [ -z "$TP" ]; then
    echo "Usage: $0 <TP1|TP2|TP3|TP4|TP5A|TP5B>"
    exit 1
fi

case $TP in
    TP1)
        cd TP1-conteneurs-simples/exercices
        ./quick-test.sh
        ;;
    TP2)
        cd TP2-dockerfile
        ./test-all-examples.sh
        ;;
    TP3)
        cd TP3-compose
        ./test-all-stacks.sh
        ;;
    *)
        echo "[ERREUR] TP $TP non supporte pour test automatique"
        exit 1
        ;;
esac
