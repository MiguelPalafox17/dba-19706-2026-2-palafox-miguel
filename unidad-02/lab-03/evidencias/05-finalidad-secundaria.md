## 2. Análisis del Escenario

## Objetivo
Evaluar si los datos recopilados para la operación pueden utilizarse legítimamente para una finalidad secundaria de marketing y determinar los controles necesarios.

## Procedimiento
Se comparó la finalidad original de los datos con el uso promocional propuesto. Después se identificaron los datos estrictamente necesarios, los requisitos de consentimiento u oposición y las medidas técnicas para limitar el acceso del área de marketing.

### Pregunta 1: ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?
**No.** El principio de **limitación de finalidad** (presente en el Art. 12 de la LFPDPPP y Art. 5 del GDPR) establece que los datos personales deben ser tratados únicamente para las finalidades expresamente informadas en el Aviso de Privacidad inicial. Poseer los datos en la base de datos no otorga titularidad ni libre disposición sobre ellos a la empresa.

### Pregunta 2: ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?
1. ¿El Aviso de Privacidad actual contempla la finalidad secundaria de mercadotecnia y prospección comercial?
2. En caso de contemplarla, ¿se ofreció al titular un mecanismo claro para manifestar su negativa (*opt-out*) al momento de la recolección?
3. ¿Existe una base jurídica o consentimiento explícito válido para este tratamiento secundario?
4. ¿Qué impacto o riesgo genera este perfilamiento sobre los derechos de los usuarios?

### Pregunta 3: ¿Qué datos serían realmente necesarios?
Para campañas promocionales personalizadas, solo se requieren:
* Canal de contacto (`correo` o `telefono`).
* Criterio de segmentación no identificable (`ciudad`, categoría de compras previa).  
* **Innecesarios:** `rfc`, `nombre completo`, `código postal exacto`, `edad exacta`.

### Pregunta 4: ¿Necesitaría el área de marketing acceso directo a la tabla `clientes`?
**No.** Conceder acceso directo a la tabla `clientes` al área de marketing viola el principio de mínimo privilegio. Marketing solo requiere listas depuradas de contacto que hayan otorgado su consentimiento expreso y que hayan sido filtradas previamente para excluir a quienes ejercieron su derecho de Oposición.

### Pregunta 5: ¿Qué controles técnicos podrían limitar la información entregada?
1. **Vistas Filtradas con Exclusión de Oposición:**
   Vistas que realicen un `JOIN` con una tabla de preferencias donde solo se incluyan los clientes con `consentimiento_marketing = TRUE`.
2. **Anonimización/Seudonimización de Segmentos:**
   Exportar identificadores seudónimos a la plataforma de envíos masivos en lugar de la base de datos de clientes directa.
3. **Mecanismos de Masking:**
   Enmascarar datos de contacto en entornos de desarrollo de campañas.

## Resultado
Se concluyó que la posesión de los datos no autoriza automáticamente su uso para marketing. El área correspondiente debe trabajar con listas filtradas de personas con consentimiento válido, usando vistas, seudonimización y enmascaramiento en lugar de acceso directo a `clientes`.

## Análisis
El uso secundario puede generar incumplimientos de limitación de finalidad, transparencia y mínimo privilegio si no existe información previa al titular o un mecanismo efectivo de oposición. La segmentación debe evitar exponer atributos fiscales o identificadores innecesarios.

## Conclusión
La finalidad secundaria solo debe implementarse con base jurídica documentada, consentimiento u oposición gestionable y controles técnicos que entreguen al marketing la mínima información necesaria.