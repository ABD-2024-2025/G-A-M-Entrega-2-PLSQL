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
-- * P4.4/*
/*
    1. Como mencioné en la pregunta 1, nos permitiría tener una comprobación directamente en la BD, 
    por lo que no sería necesario añadir comprobaciones adicionales en el software.
    
    2. La diferencia entre el CHECK y no haberlo es si salta una excepción en la BD o no. EL check hará que salte una excepción que podremos
    gestionar, generar un código de error, un mensaje, y permitir que el software trabaje con ello, en vez de pedirle al propio software que haga la comprobación.

    3. Habría que modificar el código para que gestione la excepción que salta en la BD, y que permita al usuario saber que ha habido un error.
    Primero, modificamos la tabla de personal_servicio añadiendo el CHECK:
    ```sql
    CREATE TABLE personal_servicio (
        id_personal INTEGER PRIMARY KEY,
        nombre VARCHAR2(100) NOT NULL,
        apellido VARCHAR2(100) NOT NULL,
        pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
    );
    ```

    Luego, modificamos el procedimiento registrar_pedido para que gestione la excepción:
    ```sql
    create or replace procedure registrar_pedido(
        arg_id_cliente      INTEGER, 
        arg_id_personal     INTEGER, 
        arg_id_primer_plato INTEGER DEFAULT NULL,
        arg_id_segundo_plato INTEGER DEFAULT NULL
    ) is
    begin
        begin
            registrar_pedido(101, 1, 1, 2);
            -- Lo hacemos 5 veces más para que salte la excepción...
        exception
            when OTHERS then
                raise_application_error(-20003, 'El personal de servicio tiene demasiados pedidos activos.');
        end;
    end;
    ```

    De esta forma, si se supera el límite de pedidos activos, se generará un error que podremos gestionar.
*/
-- * P4.5
-- 