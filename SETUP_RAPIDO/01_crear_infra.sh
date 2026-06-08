#!/usr/bin/env bash
# =============================================================================
#  PASO 1 - INFRAESTRUCTURA DE DESTINO (sin tocar el webhook)
#  Crea: APIs habilitadas, topico + suscripcion Pub/Sub, dataset + tabla
#  BigQuery (DatosTR) y el bucket temporal para Dataflow.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

echo "==> Habilitando APIs necesarias..."
gcloud services enable \
  run.googleapis.com cloudfunctions.googleapis.com pubsub.googleapis.com \
  dataflow.googleapis.com bigquery.googleapis.com cloudbuild.googleapis.com \
  --project="$PROJECT_ID"

echo "==> Creando topico Pub/Sub '$TOPIC'..."
gcloud pubsub topics create "$TOPIC" --project="$PROJECT_ID" 2>/dev/null \
  && echo "    topico creado" || echo "    (ya existia)"

echo "==> Creando suscripcion '$SUBSCRIPTION'..."
gcloud pubsub subscriptions create "$SUBSCRIPTION" --topic="$TOPIC" --project="$PROJECT_ID" 2>/dev/null \
  && echo "    suscripcion creada" || echo "    (ya existia)"

echo "==> Creando dataset BigQuery '$DATASET'..."
bq --location=US mk --dataset "${PROJECT_ID}:${DATASET}" 2>/dev/null \
  && echo "    dataset creado" || echo "    (ya existia)"

echo "==> Creando tabla '$TABLA' con esquema de 10 columnas..."
bq mk --table "${PROJECT_ID}:${DATASET}.${TABLA}" ./esquema_DatosTR.json 2>/dev/null \
  && echo "    tabla creada" || echo "    (ya existia)"

echo "==> Creando bucket temporal gs://$BUCKET ..."
gsutil mb -l "$REGION" "gs://$BUCKET" 2>/dev/null \
  && echo "    bucket creado" || echo "    (ya existia)"

echo ""
echo "[OK] Infraestructura de destino lista."
