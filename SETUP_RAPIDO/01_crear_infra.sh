#!/usr/bin/env bash
# =============================================================================
#  PASO 1 - INFRAESTRUCTURA DE DESTINO  (idempotente: se puede correr varias veces)
#  Crea: APIs, topico + suscripcion Pub/Sub, dataset + tabla BigQuery y bucket temporal.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

echo "==> Habilitando APIs necesarias..."
gcloud services enable \
  run.googleapis.com cloudfunctions.googleapis.com pubsub.googleapis.com \
  dataflow.googleapis.com bigquery.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com eventarc.googleapis.com \
  --project="$PROJECT_ID"

echo "==> Topico Pub/Sub '$TOPIC'..."
if gcloud pubsub topics describe "$TOPIC" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "    ya existe"
else
  gcloud pubsub topics create "$TOPIC" --project="$PROJECT_ID"
fi

echo "==> Suscripcion '$SUBSCRIPTION'..."
if gcloud pubsub subscriptions describe "$SUBSCRIPTION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "    ya existe"
else
  gcloud pubsub subscriptions create "$SUBSCRIPTION" --topic="$TOPIC" --project="$PROJECT_ID"
fi

echo "==> Dataset BigQuery '$DATASET' (location $BQ_LOCATION)..."
if bq show "${PROJECT_ID}:${DATASET}" >/dev/null 2>&1; then
  echo "    ya existe"
else
  bq --location="$BQ_LOCATION" mk --dataset "${PROJECT_ID}:${DATASET}"
fi

echo "==> Tabla '$TABLA' (esquema de 10 columnas)..."
if bq show "${PROJECT_ID}:${DATASET}.${TABLA}" >/dev/null 2>&1; then
  echo "    ya existe"
else
  bq mk --table "${PROJECT_ID}:${DATASET}.${TABLA}" ./esquema_DatosTR.json
fi

echo "==> Bucket temporal gs://$BUCKET (region $REGION)..."
if gsutil ls -b "gs://$BUCKET" >/dev/null 2>&1; then
  echo "    ya existe"
else
  gsutil mb -l "$REGION" -p "$PROJECT_ID" "gs://$BUCKET"
fi

echo ""
echo "[OK] Infraestructura de destino lista."
