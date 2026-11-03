# Actividad 15 — Propuesta de arquitectura de datos protegidos

## Objetivo
Diseñar una propuesta conceptual y técnica de arquitectura de datos en PostgreSQL que segregue la información de acuerdo con su finalidad, aplicando controles de minimización, aislamiento por esquemas, trazabilidad y políticas de acceso granular.

## Procedimiento
Se diseñó una arquitectura conceptual separando los datos operativos, analíticos y de auditoría en esquemas independientes. Después se asignaron roles con permisos mínimos, se definieron mecanismos de seudonimización y enmascaramiento, y se incorporaron controles de auditoría y disposición por particiones.

### Diagrama de Arquitectura Conceptual

```text
                                [ BASE DE DATOS POSTGRESQL ]
                                             │
      ┌──────────────────────────────────────┼──────────────────────────────────────┐
      │                                      │                                      │
      ▼                                      ▼                                      ▼
 [ ESQUEMA OPERATIVO ]                [ ESQUEMA ANALÍTICO ]               [ ESQUEMA AUDITORÍA ]
 Schema: `operacion`                  Schema: `analitica`                 Schema: `auditoria`
      │                                      │                                      │
      ├─ Tablas Base (Cifradas)              ├─ Vistas Agregadas                    ├─ Logs de Auditoría
      ├─ RLS (Row Level Security)            ├─ Datos Seudonimizados                ├─ Registro de Consultas
      └─ Acceso: App / Facturación           └─ Acceso: Rol `analista`              └─ Acceso: Exclusivo Auditor
```

---

### Especificación de Controles Técnicos

### Control de Acceso Granular (RBAC)
* **Rol `app_operacion`:** Acceso de lectura/escritura únicamente a `operacion.clientes_core`.
* **Rol `analista`:** Acceso de lectura exclusivamente al esquema `analitica` mediante vistas agregadas. No posee permisos en `operacion` ni `auditoria`.
* **Rol `auditor`:** Acceso exclusivo de lectura al esquema `auditoria`.

### Protección de Datos Sensibles (Minimización y Anonimización)
* **Vistas de Analítica:** Transformación en tiempo de ejecución de variables continuas (como `edad`) a categóricas (`rango_edad`).
* **Enmascaramiento Dinámico:** Ocultamiento de los caracteres centrales del correo o teléfono para roles no administrativos.

### Trazabilidad y Auditoría
* Monitoreo centralizado con `pgAudit` para registrar comandos de modificación (`UPDATE`, `DELETE`) sobre tablas con datos personales.

### Retención y Disposición Final
* Implementación de esquemas de particionamiento por fecha (`RANGE PARTITIONING`), lo que permite realizar el borrado físico de particiones antiguas mediante `DROP TABLE` sin fragmentar la base de datos ni generar sobrecostos de mantenimiento.

## Resultado
La propuesta establece que la aplicación opere sobre `operacion`, que los analistas consulten únicamente vistas agregadas de `analitica` y que los auditores accedan a `auditoria`. También incorpora RLS, RBAC, pgAudit, cifrado, transformación de rangos de edad y particionamiento por fecha.

## Análisis
La separación por esquemas reduce el riesgo de acceso accidental a datos identificables y permite aplicar controles según la finalidad. Sin embargo, debe complementarse con una correcta administración de claves, revisión periódica de permisos, protección de respaldos y pruebas que verifiquen que las vistas no permitan reidentificación.

## Conclusión
La arquitectura propuesta aplica minimización, aislamiento, trazabilidad y retención controlada desde la base de datos. Su implementación debe validarse con pruebas de permisos, auditoría, eliminación y recuperación para confirmar que los controles funcionan en la operación real.