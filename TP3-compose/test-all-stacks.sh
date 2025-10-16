#!/bin/bash

echo "Test de toutes les stacks TP3"
echo "=============================="

FAILED=0

echo "Test Simple Stack..."
cd simple-stack
podman-compose up -d
sleep 5
if curl -s http://localhost:8080 | grep -q "Simple Stack"; then
    echo "[OK] Simple stack fonctionne"
else
    echo "[ERREUR] Simple stack"
    ((FAILED++))
fi
podman-compose down
cd ..

echo ""
echo "Test WebApp-DB..."
cd webapp-db
podman-compose up -d
sleep 15
if curl -s http://localhost:8080 | grep -q "PostgreSQL"; then
    echo "[OK] WebApp avec DB fonctionne"
else
    echo "[ERREUR] WebApp avec DB"
    ((FAILED++))
fi
podman-compose down -v
cd ..

echo ""
if [ $FAILED -eq 0 ]; then
    echo "[OK] Tous les tests reussis"
else
    echo "[ERREUR] $FAILED test(s) echoue(s)"
fi

exit $FAILED
