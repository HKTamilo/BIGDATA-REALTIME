#!/usr/bin/env bash
# =============================================================================
#  PASO 4 - TRANSFORMACION (ELT) - LA PARTE QUE QUEDA ADELANTADA
#  Ejecuta en BigQuery: modelo limpio + marts + vistas + controles.
#  Correr cuando ya haya datos acumulados en DatosTR (deja fluir ~15-30 min).
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

run_sql () {
  local file="$1"; local desc="$2"
  echo "==> ($desc) ejecutando $file ..."
  bq query --use_legacy_sql=false --project_id="$PROJECT_ID" \
           "$(cat "$file")"
  echo "    OK"
}

# Chequeo previo: ¿hay datos crudos?
N=$(bq query --use_legacy_sql=false --project_id="$PROJECT_ID" --format=csv \
      "SELECT COUNT(*) FROM \`${PROJECT_ID}.${DATASET}.${TABLA}\`" | tail -1)
echo "Filas actuales en ${TABLA}: ${N}"
if [ "${N:-0}" = "0" ]; then
  echo "    [AVISO] Aun no hay datos. Registra el webhook, deja fluir unos minutos y vuelve a correr."
  exit 0
fi

run_sql "sql/01_modelo_realtime.sql"     "modelo: capa limpia + marts + vistas"
run_sql "sql/03_controles_calidad.sql"   "controles: dedup + monitor + integracion"

echo ""
echo "==> Validacion rapida de calidad:"
bq query --use_legacy_sql=false --project_id="$PROJECT_ID" \
  "SELECT * FROM \`${PROJECT_ID}.${DATASET}.v_calidad_datos\`"

echo ""
echo "[OK] Transformacion lista. Tablas para Looker:"
echo "    - ${DATASET}.subastas_clean   (capa limpia, fuente de los dashboards)"
echo "    - ${DATASET}.mart_producto / mart_forma_pago / mart_serie_tiempo"
echo "    Las 3 preguntas estan en sql/02_preguntas_negocio.sql"
