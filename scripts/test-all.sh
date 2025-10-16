#!/bin/bash

echo "Test de tous les TPs"
echo "===================="

FAILED=0

echo "Test TP1..."
cd TP1-conteneurs-simples/exercices
./quick-test.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ../..

echo ""
echo "Test TP2..."
cd TP2-dockerfile
./test-all-examples.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ..

echo ""
echo "Test TP3..."
cd TP3-compose
./test-all-stacks.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ..

echo ""
echo "===================="
if [ $FAILED -eq 0 ]; then
    echo "[OK] Tous les tests reussis"
else
    echo "[ERREUR] $FAILED TP(s) en erreur"
fi

exit $FAILED
