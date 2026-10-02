#!/bin/sh
# Envoie 9 requêtes au load balancer et affiche quel serveur répond.
for i in 1 2 3 4 5 6 7 8 9; do
  echo "Requête $i -> $(curl -s http://localhost:8080)"
done