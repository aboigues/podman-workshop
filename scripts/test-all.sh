#!/bin/bash

echo "Test de tous les TPs"
echo "===================="

FAILED=0

echo "Test TP1..."
cd TP1-conteneurs-simples/exercices || exit 1
if ! ./quick-test.sh; then
    ((FAILED++))
fi
cd ../.. || exit 1

echo ""
echo "Test TP2..."
cd TP2-dockerfile || exit 1
if ! ./test-all-examples.sh; then
    ((FAILED++))
fi
cd .. || exit 1

echo ""
echo "Test TP3..."
cd TP3-compose || exit 1
if ! ./test-all-stacks.sh; then
    ((FAILED++))
fi
cd .. || exit 1

echo ""
echo "===================="
if [ $FAILED -eq 0 ]; then
    echo "[OK] Tous les tests reussis"
else
    echo "[ERREUR] $FAILED TP(s) en erreur"
fi

exit $FAILED
