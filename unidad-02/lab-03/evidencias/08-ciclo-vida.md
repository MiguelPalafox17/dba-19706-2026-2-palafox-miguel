# Actividad 8 — Derecho de cancelación y ciclo de vida
## Objetivo
Analizar el ciclo de vida completo de los datos personales y demostrar por qué una eliminación en la tabla principal no garantiza su desaparición de toda la organización.

## Procedimiento
Se identificaron las réplicas, respaldos, archivos WAL, exportaciones, repositorios de contingencia y ambientes de desarrollo que pueden conservar copias del registro. Posteriormente se revisaron los puntos donde debe aplicarse la cancelación o disposición segura.

```text
                        [ CLIENTES ]
                               │
   ┌───────────────────────────┼───────────────────────────┐
   │                           │                           │
   ▼                           ▼                           ▼
   Réplicas:                 Respaldos                ReporteS
   - Read Replicas         - pg_dump (.sql/.tar)      - Exportaciones CSV/Excel
   - Standby Nodes         - Archivos WAL (PITR)      - B.I. / PowerBI Cache
         │                 - S3 Snapshots                      │
         │                        │                            │
         ▼                        ▼                            ▼
   Repositorios:           Retención WORM:            Ambientes de Dev/Test
   - BDD de Contingencia   - Custodia Histórica       - Copias de desarrolladores
```

### ¿Por qué eliminar un registro en la tabla no significa que el dato ha desaparecido de la organización?

1. Aunque se ejecute el `delete` la transacción sigue registrada en los archivos WAL, los cuales son utilizados para replicación y recuperación punto en el tiempo (*PITR*).
2. Los respaldos generados previamente continúan conteniendo el dato personal cancelada. Restaurar un respaldo antiguo volvería a introducir el dato en el sistema.
3. Si se enviaron respaldos o extractos de producción a los equipos de desarrollo, los datos personales persisten en sus estaciones de trabajo o servidores de prueba.
4. Exportaciones enviadas a proveedores de correos, plataformas CRM o contabilidad ajenas a PostgreSQL.

## Resultado
Se determinó que los datos pueden permanecer en respaldos históricos, réplicas, caches, archivos de desarrollo y proveedores externos aun después de ejecutar `DELETE` en la base principal. Por ello, la eliminación debe coordinarse en todas las copias y sistemas derivados.

## Análisis
El ciclo de vida no termina en la tabla operativa. Los mecanismos de recuperación y continuidad son necesarios para el negocio, pero también crean copias adicionales que deben tener inventario, retención, controles de acceso y procedimientos de purga o anonimización.

## Conclusión
Una solicitud de cancelación requiere un proceso integral que abarque producción, respaldos, réplicas, exportaciones, proveedores y ambientes no productivos, con evidencia de las acciones realizadas.