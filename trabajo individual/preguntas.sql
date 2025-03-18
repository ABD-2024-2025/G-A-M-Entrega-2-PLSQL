/*  1. ¿Cómo garantizas en tu código que un miembro del personal de servicio no supere el límite de pedidos activos?

    2. ¿Cómo evitas que dos transacciones concurrentes asignen un pedido al mismo personal de servicio cuyos pedidos activos estan a punto de superar el límite?

    3. Una vez hechas las comprobaciones en los pasos 1 y 2, ¿podrías asegurar que el pedido se puede realizar de manera correcta en el paso 4 y no se generan inconsistencias? 
    ¿Por qué? 
    
    Recuerda que trabajamos en entornos con conexiones concurrentes.

    4. Si modificásemos la tabla de personal con CHECK (pedidos_activos <= 5):
        - ¿Qué implicaciones tendría en tu código? 
        - ¿Cómo afectaría en la gestión de excepciones? 
        - Describe en detalle las modificaciones que deberías hacer en tu código para mejorar tu solución ante esta situación (puedes añadir pseudocódigo).
*/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites para cada una)
-- * P4.1 
/*
    A la hora de crear las tablas existe un `pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)`. 
    Este CHECK garantiza que el número de pedidos activos no supere el límite de 5.
    De hecho, gracias a este check podríamos ignorar el añadir comprobaciones adicionales al software que se conecte a la base de datos, 
    ya que la base de datos se encargaría de gestionar este límite.
    En el caso de que se superase el límite, Tendríamos que gestionar esa excepción tanto en la BD como en el software.
*/
-- * P4.2
/*
    Hay varias opciones, yo eligiría una de las 2 siguientes, dependiendo de la complejidad del sistema:
    1. Un FOR UPDATE en la consulta que obtiene el personal de servicio, de esta forma se bloquea la fila y no se puede asignar a otro pedido.
    2. Un trigger que se ejecute antes de insertar un pedido, que compruebe si el personal de servicio tiene pedidos activos y si los tiene, no permita la inserción.

    Considero que la primera es más sencilla de implementar y más eficiente, por lo que sería mi elección por excelencia.
*/
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 