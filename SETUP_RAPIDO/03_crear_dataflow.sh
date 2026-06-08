#!/usr/bin/env bash
# =============================================================================
#  PASO 3 - DATAFLOW (plantilla Pub/Sub Subscription to BigQuery)
#  Arranca el pipeline streaming que lleva los mensajes de la suscripcion
#  a la tabla DatosTR. Ejecutar DESPUES de registrar la URL del webhook.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

echo "==> Lanzando job de Dataflow '$DATAFLOW_JOB'..."
gcloud dataflow jobs run "$DATAFLOW_JOB" \
  --gcs-location="gs://dataflow-templates-${REGION}/latest/PubSub_Subscription_to_BigQuery" \
  --region="$REGION" \
  --staging-location="gs://${BUCKET}/temp" \
  --project="$PROJECT_ID" \
  --parameters="inputSubscription=projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION},outputTableSpec=${PROJECT_ID}:${DATASET}.${TABLA}"

echo ""
echo "[OK] Job enviado. Espera unos 3-5 min a que aparezca en estado 'Running'."
echo "    Veelo en: Consola -> Dataflow -> Jobs"
echo "    RECUERDA: detener el job (Stop) cuando termines, para no gastar creditos."
