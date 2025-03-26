/*  1. ¿Cómo garantizas en tu código que un miembro del personal de servicio no supere el límite de pedidos activos?

    2. ¿Cómo evitas que dos transacciones concurrentes asignen un pedido al mismo personal de servicio cuyos pedidos activos estan a punto de superar el límite?

    3. Una vez hechas las comprobaciones en los pasos 1 y 2, ¿podrías asegurar que el pedido se puede realizar de manera correcta en el paso 4 y no se generan inconsistencias? 
    ¿Por qué? 
    
    Recuerda que trabajamos en entornos con conexiones concurrentes.

    4. Si modificásemos la tabla de personal con CHECK (pedidos_activos <= 5):
        - ¿Qué implicaciones tendría en tu código? 
        - ¿Cómo afectaría en la gestión de excepciones? 
        - Describe en detalle las modificaciones que deberías hacer en tu código para mejorar tu solución ante esta situación (puedes añadir pseudocódigo).

    5. ¿Qué tipo de estrategia de programación has utilizado? ¿Cómo
    puede verse en tu código?
*/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites para cada una)
-- * P4.1 
/*
    Garantizamos que un miembro del personal de servicio no supere el límite de pedidos activos 
    realizando una verificación explícita antes de registrar el pedido:
    
    ```sql
    SELECT pedidos_activos INTO v_pedidos_activos
    FROM personal_servicio
    WHERE id_personal = arg_id_personal;

    IF v_pedidos_activos >= 5 THEN 
        raise_application_error(-20003, msg_personal_ocupado);
    END IF;
    ```
    
    Esta validación se realiza antes de insertar cualquier registro en la base de datos,
    evitando así que se creen pedidos para personal que ya ha alcanzado su límite máximo.
    Además, el test del caso 8 verifica específicamente este escenario para asegurar que
    se lanza la excepción correcta cuando un miembro del personal ya tiene 5 pedidos activos.
*/
-- * P4.2
/*
    Para evitar problemas de concurrencia donde dos transacciones podrían asignar simultáneamente
    pedidos al mismo personal que está cerca del límite, decidimos implementar un bloqueo a nivel de fila
    usando la cláusula FOR UPDATE en la consulta que verifica los pedidos activos:
    
    ```
    SELECT pedidos_activos INTO v_pedidos_activos
    FROM personal_servicio
    WHERE id_personal = arg_id_personal
    FOR UPDATE;
    ```
    
    Esta cláusula bloquea la fila del personal consultado hasta que se complete la transacción,
    evitando que otras transacciones concurrentes puedan modificar los mismos datos.
    De esta manera, si dos transacciones intentan asignar un pedido al mismo personal,
    una de ellas tendrá que esperar hasta que la primera libere el bloqueo,
    garantizando así la integridad de la restricción de pedidos activos.
*/
-- * P4.3
/*
    Incluso después de implementar las comprobaciones y el bloqueo con FOR UPDATE,
    no se puede garantizar al 100% que el pedido se realizará correctamente sin inconsistencias,
    por varias razones:
    
    1. Pueden ocurrir errores durante la inserción del pedido o sus detalles que no están relacionados
       con las validaciones previas (por ejemplo, problemas de almacenamiento, restricciones adicionales).
    
    2. En un entorno con conexiones concurrentes, pueden surgir deadlocks si múltiples transacciones
       intentan bloquear recursos en diferente orden.
    
    3. Si el sistema se cae entre la inserción del pedido y la actualización de pedidos_activos,
       podría quedar en un estado inconsistente.
    
    Para mitigar estos problemas, el procedimiento utiliza un manejo de transacciones explícito con
    COMMIT al final y ROLLBACK en el bloque de excepciones, lo que garantiza la atomicidad de todas
    las operaciones. Si cualquier parte falla, todas las operaciones se deshacen, manteniendo así
    la consistencia de los datos.
*/
-- * P4.4
/*
    Si modificásemos la tabla personal_servicio añadiendo CHECK (pedidos_activos <= 5):
    
    - Implicaciones en el código:
        La restricción CHECK proporcionaría una capa adicional de seguridad a nivel de base de datos,
        actuando como una "red de seguridad" incluso si la validación en el código fallara.
        Esta redundancia es positiva para garantizar la integridad de los datos.
    
    - Efecto en la gestión de excepciones:
        Si se intenta actualizar pedidos_activos a un valor mayor que 5, la base de datos lanzaría
        una excepción ORA-02290 (restricción CHECK violada). Esta excepción tendría que ser capturada
        en el bloque EXCEPTION del procedimiento, diferenciándola de otras excepciones.
    
    - Modificaciones necesarias:
        1. Podríamos mantener la validación previa por claridad y mejor experiencia de usuario,
        permitiendo mensajes de error más específicos.
        2. El bloque EXCEPTION debería ampliarse para capturar específicamente la violación de CHECK:
      
      ```sql
        EXCEPTION
            WHEN check_constraint_violated THEN
                -- Definir un código de error personalizado para esta excepción
                ROLLBACK;
                raise_application_error(-20003, msg_personal_ocupado);
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE;
      ```
      
        3. Para mejorar el rendimiento, podríamos incluso considerar eliminar la validación previa
        y depender completamente de la restricción CHECK, simplificando el código pero sacrificando
        la personalización del mensaje de error.
*/
-- * P4.5
/*
    En la implementación de registrar_pedido hemos utilizado varias estrategias de programación:
    
    1. Programación defensiva: El código verifica múltiples condiciones antes de realizar cualquier
    operación crítica (validación de platos existentes, disponibilidad, límites de pedidos). Esto
    se evidencia en las validaciones previas a las inserciones y actualizaciones:
    
    ```sql
    IF arg_id_primer_plato IS NULL AND arg_id_segundo_plato IS NULL THEN
        raise_application_error(-20002, msg_pedido_no_valido);
    END IF;
    ```
    
    2. Manejo estructurado de excepciones: Definimos excepciones personalizadas con códigos específicos
    para diferentes tipos de errores, lo que facilita la identificación y gestión de problemas:
    
    ```sql
    PRAGMA exception_init(Plato_no_disponible, -20001);
    PRAGMA exception_init(Pedido_no_valido, -20002);
    PRAGMA exception_init(Personal_ocupado, -20003);
    PRAGMA exception_init(Plato_inexistente, -20004);
    ```
    
    3. Transaccionalidad: Aseguramos la atomicidad de las operaciones mediante el uso de COMMIT al final
    del procedimiento y ROLLBACK en caso de cualquier error:
    
    ```sql
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    ```
    
    4. Modularidad: El código está estructurado en bloques lógicos separados (validación, inserciones
    de pedidos, inserciones de detalles, actualización de contadores), lo que mejora la legibilidad
    y mantenibilidad.
*/
