#!/usr/bin/env bash
# =============================================================================
#  PASO 2 - WEBHOOK (Cloud Function gen2 que publica a Pub/Sub)
#  Despliega la funcion 'webhookpubsub', le da permisos y MUESTRA LA URL
#  que debes copiar y registrar en https://bdrealtimeescuelait.duoc.cl
#
#  *** Si prefieres crear el webhook a mano por la consola siguiendo la
#      "GUIA PARA DESCARGAR DATA STREAMING A WEBHOOK PUB_SUB.pdf", puedes
#      SALTARTE este script y crearlo tu mismo. ***
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

echo "==> Desplegando la Cloud Function '$FUNCION' (Python 3.10)..."
gcloud functions deploy "$FUNCION" \
  --gen2 \
  --runtime=python310 \
  --region="$REGION" \
  --source=./funcion \
  --entry-point=main \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars="GCP_PROJECT=${PROJECT_ID},PUBSUB_TOPIC=${TOPIC}" \
  --project="$PROJECT_ID"

echo "==> Dando rol 'Pub/Sub Publisher' a la cuenta de servicio de la funcion..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_COMPUTE}" \
  --role="roles/pubsub.publisher" >/dev/null
echo "    permiso asignado"

URL="$(gcloud functions describe "$FUNCION" --gen2 --region="$REGION" \
        --project="$PROJECT_ID" --format='value(serviceConfig.uri)')"

echo ""
echo "============================================================"
echo "   COPIA ESTA URL (es tu WEBHOOK) Y REGISTRALA EN:"
echo "   https://bdrealtimeescuelait.duoc.cl  ->  Registro de URL"
echo ""
echo "   >>>  $URL  <<<"
echo "============================================================"
echo "$URL" > URL_WEBHOOK.txt
echo "(tambien quedo guardada en SETUP_RAPIDO/URL_WEBHOOK.txt)"
