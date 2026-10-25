------------------------------------------------------------
--PREENTREGA - ANÁLISIS AVANZADO CON WINDOWFUNCTION
------------------------------------------------------------

-------------------------------------------------------------------------
--En esta primera CTE agrupare las ventas por mes y por categoría
--Utilizare DATETRUNC para normalizar las fechas al primer día de cada mes
--y después sumare el total de ventas de cada categoría
--------------------------------------------------------------------------
WITH ventas_mensuales AS (

    SELECT
        DATE_TRUNC('month', v.fecha_venta) AS mes,
        c.nombre_categoria AS categoria,
        SUM(v.total) AS venta_total

    FROM ventas v

    INNER JOIN productos p
        ON v.producto_id = p.id_producto

    INNER JOIN categorias c
        ON p.categoria_id = c.id_categoria

    GROUP BY
        DATE_TRUNC('month', v.fecha_venta),
        c.nombre_categoria
),

-------------------------------------------------------------------------------
--En esta segunda CTE calculare las métricas de ventana
--Primero generare un ranking para identificar las categorías más vendidas
--dentro de cada mes.

--Después calculare el acumulado de ventas de cada categoría a través del tiempo
--utilizando una Windowfunction
-------------------------------------------------------------------------------
metricas_ventana AS (

    SELECT
        mes,
        categoria,
        venta_total,

        RANK() OVER (
            PARTITION BY mes
            ORDER BY venta_total DESC
        ) AS ranking,

        SUM(venta_total) OVER (
            PARTITION BY categoria
            ORDER BY mes
        ) AS acumulado

    FROM ventas_mensuales
)

---------------------------------------------------------------------
--En la consulta final mostrare las métricas solicitadas.

--También utilizare CASE WHEN para comparar la venta mensual
--contra el promedio histórico de la misma categoría.

--Si la venta es igual o superior al promedio, marcare el resultado
--como 'Exitoso'. En caso contrario, aparece como
--'Bajo el promedio'
---------------------------------------------------------------------
SELECT
    mes,
    categoria,
    venta_total,
    ranking,
    acumulado,

    CASE
        WHEN venta_total >= AVG(venta_total) OVER (
            PARTITION BY categoria
        )
        THEN 'Exitoso'
        ELSE 'Bajo el promedio'
    END AS comparativa

FROM metricas_ventana

ORDER BY
    mes,
    ranking;

----------------------------------------------------------------------