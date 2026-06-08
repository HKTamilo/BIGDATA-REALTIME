#!/usr/bin/env bash
# =============================================================================
#  PASO 3 - DATAFLOW (plantilla Pub/Sub Subscription to BigQuery) en la REGION valida.
#  Idempotente: si ya hay un job activo con el mismo nombre, no crea otro.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

echo "==> Revisando si ya hay un job '$DATAFLOW_JOB' activo..."
ACTIVO="$(gcloud dataflow jobs list --region="$REGION" --status=active \
            --filter="name=${DATAFLOW_JOB}" --format='value(JOB_ID)' \
            --project="$PROJECT_ID" 2>/dev/null | head -n1 || true)"
if [ -n "$ACTIVO" ]; then
  echo "    Ya hay un job activo ($ACTIVO). No se crea otro."
  exit 0
fi

echo "==> Lanzando job de Dataflow '$DATAFLOW_JOB' en $REGION..."
gcloud dataflow jobs run "$DATAFLOW_JOB" \
  --gcs-location="gs://dataflow-templates-${REGION}/latest/PubSub_Subscription_to_BigQuery" \
  --region="$REGION" \
  --staging-location="gs://${BUCKET}/temp" \
  --project="$PROJECT_ID" \
  --parameters="inputSubscription=projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION},outputTableSpec=${PROJECT_ID}:${DATASET}.${TABLA}"

echo ""
echo "[OK] Job enviado. Espera 3-5 min a que aparezca 'Running' (Consola -> Dataflow -> Jobs)."
echo "    RECUERDA: detener el job (Stop) cuando termines, para no gastar creditos."
