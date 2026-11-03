# Actividad 10 — Política de retención

## Objetivo
Definir criterios para establecer periodos de retención de datos que sean legales, necesarios, proporcionales y técnicamente ejecutables.

## Procedimiento
Se evaluó la compatibilidad de una retención indefinida con la minimización. Luego se identificaron sus riesgos y los factores que deben documentarse: regulación aplicable, duración de la relación, posibles controversias, evento disparador, responsable y acción final.

### Pregunta 1: ¿Es compatible con el principio de minimización?
No, ya que la retención indefinida viola el principio de minimización y proporcionalidad. Ya que al mantener los datos cuyo propósito operativo o legal ya expiró, se convierte en un acto ilícito por exceso de conservación.

### Pregunta 2: ¿Qué riesgos genera conservar información innecesaria?
1. Mientras mayor sea el volumen de datos históricos almacenados, mayor es el impacto y la gravedad en caso de una brecha de seguridad.
2. Multas severas de parte de las autoridades por incumplimiento de plazos de conservación.
3. Pueden provocar consultas más lentas y mayor tiempo requerido para ejecutar procesos de mantenimiento y respaldos.
4. Gastos innecesarios en infraestructura de almacenamiento en la nube o local.

### Pregunta 3: ¿Qué debería determinar la organización antes de establecer un periodo de retención?
* Identificar el marco regulatorio aplicable.
* Identificar el tiempo que dura la prestación del servicio o la relación contractual.
* Aplicar criterios del código civil/mercantil para la atención de eventuales disputas o demandas legales.

### Pregunta 4: ¿Qué información debería documentarse para justificar el periodo seleccionado?
* Base legal o regulatoria que fundamenta el plazo.
* Definición clara del "evento disparador" (*trigger event*) que inicia el cómputo del plazo (ej. cancelación de cuenta, emisión de la última factura).
* Responsable del seguimiento (Data Owner).
* Mapeo de la acción a ejecutar al finalizar el periodo (purga, anonimización o archivado en frío).

## Resultado
Se concluyó que la conservación indefinida no es compatible con la minimización cuando ya expiró la finalidad. La organización debe establecer plazos documentados y ejecutar purga, anonimización o archivado controlado al concluir cada periodo.

## Análisis
Conservar datos innecesarios aumenta el impacto de una brecha, los costos de almacenamiento y mantenimiento, y el riesgo de incumplir obligaciones legales. Una política efectiva debe traducirse en reglas automatizadas y revisiones periódicas, no quedarse solo como documento.

## Conclusión
La retención debe justificarse campo por campo y comenzar a contar desde un evento claramente definido. Al vencer el plazo, la disposición final debe quedar registrada y ser verificable.