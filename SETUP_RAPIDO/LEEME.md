# ⚡ SETUP RÁPIDO — Pipeline Real Time Subastas (v2, a prueba de fallos)

Monta **todo el pipeline en GCP** automáticamente. Tu único trabajo manual:
**(1) registrar la URL del webhook en la página del profe** y **(2) armar los dashboards en Looker**.

> ⚙️ **Novedad importante (v2):** algunos labs **bloquean `us-central1`** con una *org policy*
> (`constraints/gcp.resourceLocations`). Por eso los scripts ahora **detectan solos una región
> permitida** y la usan en todo (Cloud Run, Dataflow, bucket). La región detectada queda guardada
> en el archivo `.region`. BigQuery usa la multi-región `US`.
> Si el panel del lab te dice qué región usar, puedes forzarla: `export REGION=us-east1`.

---

## 🔁 Cómo actualizar tu Cloud Shell con esta versión corregida
Como subiste la carpeta a GitHub, vuelve a **subir el `SETUP_RAPIDO` corregido** (GitHub → *Add file → Upload files* → arrastra la carpeta → *Commit*). Luego en Cloud Shell:
```bash
cd ~
rm -rf BIGDATA-REALTIME
git clone https://github.com/HKTamilo/BIGDATA-REALTIME.git
cd BIGDATA-REALTIME/SETUP_RAPIDO
bash setup_todo.sh
```
Lo que ya creaste antes (topic, dataset, tabla) **se saltea solo** (es idempotente); solo creará lo que faltó (bucket y webhook) en la región correcta.

---

## 🚀 Un solo comando
```bash
cd BIGDATA-REALTIME/SETUP_RAPIDO
bash setup_todo.sh
```
Corre todo y **se detiene una sola vez** para que copies la URL del webhook y la registres en
`https://bdrealtimeescuelait.duoc.cl`. Después presionas ENTER y sigue.

## 🧩 Paso a paso (si prefieres control)
```bash
bash 01_crear_infra.sh        # APIs + topico/sub + dataset + tabla + bucket (región correcta)
bash 02_desplegar_webhook.sh  # despliega el webhook (Cloud Run) y te imprime la URL
#  >>> registrar la URL en la página del profe y activar el envío <<<
bash 03_crear_dataflow.sh     # arranca el streaming Pub/Sub -> BigQuery
#  >>> dejar fluir 15-30 min <<<
bash 04_transformacion.sh     # ELT: capa limpia + marts + controles  (re-ejecútalo para refrescar)
```

Todos los scripts son **idempotentes**: puedes correrlos las veces que quieras sin romper nada.

---

## 📂 Archivos
```
SETUP_RAPIDO/
├── setup_todo.sh        ← orquestador (corre todo, idempotente)
├── 00_variables.sh      ← config + DETECCIÓN AUTOMÁTICA de región
├── 01_crear_infra.sh    ← Pub/Sub + BigQuery + bucket
├── 02_desplegar_webhook.sh ← webhook como servicio Cloud Run + permisos + URL
├── 03_crear_dataflow.sh ← job Dataflow (streaming)
├── 04_transformacion.sh ← ELT (re-ejecutable)
├── 05_diagnostico.sh    ← revisa estado del pipeline (jobs, filas, errores)
├── 06_reset_tabla.sh    ← recupera si los datos rebotan por tipo (recrea tabla + relanza)
├── esquema_DatosTR.json ← esquema EXACTO del profe (tipado: precio/monto FLOAT, fecreg TIMESTAMP)
├── funcion/  (main.py + requirements.txt)
└── sql/      (01 modelo, 02 preguntas, 03 controles)
```

> 🛡️ **Robustez:** `DatosTR` usa el esquema tipado del profe (punto 21 de la guía). La transformación
> usa `SAFE_CAST` en `subastas_clean`, así que no rompe ante datos sucios.
> Si alguna vez los datos rebotaran a una `DatosTR_error_records`, recrea la tabla TODO-STRING
> (cambia los tipos a STRING en `esquema_DatosTR.json`) y corre `bash 06_reset_tabla.sh`.

---

## 🩺 Si algo falla (diagnóstico rápido)
```bash
bash 05_diagnostico.sh     # te dice: estado del job, filas, si hay tabla de errores
```
- Job **Running** y filas subiendo → todo OK, corré `bash 04_transformacion.sh`.
- Hay **DatosTR_error_records** o filas sigue en **0** → corré `bash 06_reset_tabla.sh`
  (recrea la tabla todo-STRING y relanza Dataflow; espera ~5 min y revisá de nuevo).

---

## 📊 LOOKER (lo último)
Cuando `04` termine, tendrás `DatosRealTime.subastas_clean` + los marts. En Looker Studio
(looker.studio.google.com → *Create* → *Data source* → BigQuery → tu proyecto → `subastas_clean`)
armas **2 dashboards**:
- **A — Mercado/Subasta:** ranking por monto, volatilidad de precio, scorecard recaudación. Filtros: producto, sector.
- **B — Operación Real Time:** serie por minuto, forma de pago, género. Filtros: forma_pago, franja_horaria, hora.

> Pídeme el **mini-manual de Looker paso a paso** cuando llegues acá.

---

## ⚠️ Importante
- Hacé la parte GCP **en una sola sesión** (el proyecto del lab se borra al cerrarlo).
- **Detené el job de Dataflow** (Stop) al terminar, para no gastar créditos.
- Si `02` falla por `allUsers`/dominio, avísame: hay un plan B por consola.
