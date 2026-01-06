#!/bin/bash

echo "Test de tous les exemples TP2"
echo "=============================="

FAILED=0

echo "Test Python App..."
cd python-app || exit 1
if ! bash test.sh; then
    ((FAILED++))
fi
cd .. || exit 1

echo ""
echo "Test Go App..."
cd go-app || exit 1
if ! bash test.sh; then
    ((FAILED++))
fi
cd .. || exit 1

echo ""
echo "Test Nginx Custom..."
cd nginx-custom || exit 1
if ! bash test.sh; then
    ((FAILED++))
fi
cd .. || exit 1

echo ""
echo "=============================="
if [ $FAILED -eq 0 ]; then
    echo "[OK] Tous les tests reussis"
else
    echo "[ERREUR] $FAILED test(s) echoue(s)"
fi

exit $FAILED
