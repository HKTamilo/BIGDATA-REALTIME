#!/usr/bin/env bash
# =============================================================================
#  CONFIGURACION CENTRAL - editar SOLO si hace falta y luego: source 00_variables.sh
#  (los demas scripts hacen 'source' de este archivo automaticamente)
# =============================================================================

# Project ID: por defecto toma el proyecto activo de tu sesion de Cloud Shell.
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null)"

# Region unica para todos los servicios (igual a la guia del profe).
export REGION="us-central1"

# Nombres de recursos (coinciden con la Guia Pub/Sub del profesor).
export TOPIC="registros"
export SUBSCRIPTION="registros-sub"
export FUNCION="webhookpubsub"
export DATASET="DatosRealTime"
export TABLA="DatosTR"
export BUCKET="${PROJECT_ID}-rt-temp"          # bucket temporal para Dataflow
export DATAFLOW_JOB="transferBigQuery"

# Cuenta de servicio que usa la Cloud Function gen2 (Cloud Run) para publicar.
export SA_COMPUTE="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo "  PROJECT_ID   = $PROJECT_ID"
echo "  REGION       = $REGION"
echo "  TOPIC/SUB    = $TOPIC / $SUBSCRIPTION"
echo "  FUNCION      = $FUNCION"
echo "  DATASET.TBL  = $DATASET.$TABLA"
echo "  BUCKET       = gs://$BUCKET"
