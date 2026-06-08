#!/usr/bin/env bash
# =============================================================================
#  PASO 4 - TRANSFORMACION (ELT) - re-ejecutable cuantas veces quieras
#  Construye la capa limpia + marts + vistas + controles en BigQuery.
#  Corre esto cuando haya datos en DatosTR (deja fluir ~15-30 min) y cada vez
#  que quieras refrescar lo que ven los dashboards de Looker.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00_variables.sh

run_sql () {
  local file="$1"; local desc="$2"
  echo "==> ($desc) ejecutando $file ..."
  bq query --use_legacy_sql=false --project_id="$PROJECT_ID" "$(cat "$file")"
  echo "    OK"
}

# Chequeo previo: ¿hay datos crudos?
N="$(bq query --use_legacy_sql=false --project_id="$PROJECT_ID" --format=csv \
       "SELECT COUNT(*) AS n FROM \`${PROJECT_ID}.${DATASET}.${TABLA}\`" 2>/dev/null | tail -n1 || echo 0)"
echo "Filas actuales en ${TABLA}: ${N}"
if [ "${N:-0}" = "0" ] || [ -z "${N// }" ]; then
  echo "    [AVISO] Aun no hay datos. Registra el webhook, deja fluir unos minutos y vuelve a correr."
  exit 0
fi

run_sql "sql/01_modelo_realtime.sql"   "modelo: capa limpia + marts + vistas"
run_sql "sql/03_controles_calidad.sql" "controles: dedup + monitor + integracion"

echo ""
echo "==> Validacion rapida de calidad:"
bq query --use_legacy_sql=false --project_id="$PROJECT_ID" \
  "SELECT * FROM \`${PROJECT_ID}.${DATASET}.v_calidad_datos\`"

echo ""
echo "[OK] Transformacion lista. Tablas para Looker:"
echo "    - ${DATASET}.subastas_clean   (capa limpia, fuente de los dashboards)"
echo "    - ${DATASET}.mart_producto / mart_forma_pago / mart_serie_tiempo"
echo "    Las 3 preguntas estan en sql/02_preguntas_negocio.sql"
