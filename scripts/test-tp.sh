#!/bin/bash

TP=$1

if [ -z "$TP" ]; then
    echo "Usage: $0 <TP1|TP2|TP3|TP4|TP5A|TP5B|TP6>"
    exit 1
fi

case $TP in
    TP1)
        cd TP1-conteneurs-simples/exercices || exit 1
        bash quick-test.sh
        ;;
    TP2)
        cd TP2-dockerfile || exit 1
        bash test-all-examples.sh
        ;;
    TP3)
        cd TP3-compose || exit 1
        bash test-all-stacks.sh
        ;;
    TP6)
        cd TP6-projet-complet || exit 1
        bash test-tp6.sh
        ;;
    *)
        echo "[ERREUR] TP $TP non supporte pour test automatique"
        exit 1
        ;;
esac
