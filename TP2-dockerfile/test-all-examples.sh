#!/bin/bash

echo "Test de tous les exemples TP2"
echo "=============================="

FAILED=0

echo "Test Python App..."
cd python-app && ./test.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ..

echo ""
echo "Test Go App..."
cd go-app && ./test.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ..

echo ""
echo "Test Nginx Custom..."
cd nginx-custom && ./test.sh
if [ $? -ne 0 ]; then ((FAILED++)); fi
cd ..

echo ""
echo "=============================="
if [ $FAILED -eq 0 ]; then
    echo "[OK] Tous les tests reussis"
else
    echo "[ERREUR] $FAILED test(s) echoue(s)"
fi

exit $FAILED
