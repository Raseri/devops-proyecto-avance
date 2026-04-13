-- ============================================================
-- TIENDA MANAGER V2 — Script de Inicialización Completo
-- Unifica: database_schema + pedidos_schema + add_peps_ueps
-- Se ejecuta automáticamente cuando Docker levanta MySQL
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- BLOQUE 1: TABLAS BASE
-- ============================================================

-- TABLA: usuarios
-- Roles: admin, vendedor, repartidor
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'vendedor', 'repartidor') NOT NULL DEFAULT 'vendedor',
    activo BOOLEAN DEFAULT TRUE,
    telefono VARCHAR(20),
    avatar_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,

    INDEX idx_email (email),
    INDEX idx_rol (rol),
    INDEX idx_activo (activo)
) ENGINE=InnoDB;

-- TABLA: productos
-- Catálogo de productos con soporte PEPS/UEPS/Promedio
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_barras VARCHAR(50) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria VARCHAR(100),
    precio DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    costo DECIMAL(10,2) DEFAULT 0.00,
    costo_promedio DECIMAL(10,2) DEFAULT 0.00,
    metodo_valuacion ENUM('PEPS','UEPS','PROMEDIO') DEFAULT 'PEPS',
    stock INT NOT NULL DEFAULT 0,
    stock_minimo INT DEFAULT 5,
    unidad VARCHAR(20) DEFAULT 'pcs',
    proveedor VARCHAR(150),
    imagen_url VARCHAR(255),
    activo BOOLEAN DEFAULT TRUE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_nombre (nombre),
    INDEX idx_codigo_barras (codigo_barras),
    INDEX idx_categoria (categoria),
    INDEX idx_activo (activo),
    INDEX idx_stock (stock),

    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- TABLA: ventas
-- Encabezado de cada venta realizada
CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,
    vendedor_id INT NOT NULL,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    impuestos DECIMAL(10,2) DEFAULT 0.00,
    descuento DECIMAL(10,2) DEFAULT 0.00,
    metodo_pago ENUM('efectivo','tarjeta','transferencia','mixto') DEFAULT 'efectivo',
    estado ENUM('completada','cancelada','pendiente') DEFAULT 'completada',
    cliente_nombre VARCHAR(150),
    cliente_telefono VARCHAR(20),
    notas TEXT,

    INDEX idx_folio (folio),
    INDEX idx_vendedor (vendedor_id),
    INDEX idx_fecha (fecha_venta),
    INDEX idx_estado (estado),
    INDEX idx_metodo_pago (metodo_pago),

    FOREIGN KEY (vendedor_id) REFERENCES usuarios(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TABLA: detalles_venta
-- Productos de cada venta (líneas de ticket)
CREATE TABLE IF NOT EXISTS detalles_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    producto_nombre VARCHAR(200) NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0.00,

    INDEX idx_venta (venta_id),
    INDEX idx_producto (producto_id),

    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TABLA: movimientos_inventario
-- Historial de entradas, salidas y ajustes de stock
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    tipo_movimiento ENUM('entrada','salida','ajuste','venta','devolucion') NOT NULL,
    cantidad INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    referencia VARCHAR(100),
    usuario_id INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notas TEXT,

    INDEX idx_producto (producto_id),
    INDEX idx_tipo (tipo_movimiento),
    INDEX idx_fecha (fecha),

    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- TABLA: lotes_inventario
-- Cada lote de compra (para PEPS/UEPS)
CREATE TABLE IF NOT EXISTS lotes_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad_inicial INT NOT NULL,
    cantidad_restante INT NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,
    fecha_entrada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATE NULL,
    proveedor VARCHAR(150),
    factura_compra VARCHAR(100),
    nota TEXT,
    activo BOOLEAN DEFAULT TRUE,
    created_by INT,

    INDEX idx_producto (producto_id),
    INDEX idx_fecha (fecha_entrada),
    INDEX idx_activo (activo),
    INDEX idx_restante (cantidad_restante),

    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- TABLA: detalle_costo_venta
-- Qué lotes se consumieron en cada venta (trazabilidad)
CREATE TABLE IF NOT EXISTS detalle_costo_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    detalle_venta_id INT NOT NULL,
    lote_id INT NOT NULL,
    cantidad INT NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,

    INDEX idx_detalle_venta (detalle_venta_id),
    INDEX idx_lote (lote_id),

    FOREIGN KEY (detalle_venta_id) REFERENCES detalles_venta(id) ON DELETE CASCADE,
    FOREIGN KEY (lote_id) REFERENCES lotes_inventario(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TABLA: pedidos
-- Pedidos a domicilio (módulo de logística)
CREATE TABLE IF NOT EXISTS pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    folio VARCHAR(20) UNIQUE NOT NULL,
    cliente_nombre VARCHAR(150) NOT NULL,
    cliente_telefono VARCHAR(20),
    cliente_direccion TEXT NOT NULL,
    cliente_lat DECIMAL(10,7) NOT NULL DEFAULT 19.0413000,
    cliente_lng DECIMAL(10,7) NOT NULL DEFAULT -98.2062000,
    estado ENUM('pendiente','en_camino','entregado','cancelado') DEFAULT 'pendiente',
    metodo_pago ENUM('efectivo','tarjeta','transferencia') DEFAULT 'efectivo',
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    notas TEXT,
    repartidor_id INT,
    creado_por INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_estado (estado),
    INDEX idx_repartidor (repartidor_id),
    INDEX idx_creado_por (creado_por),
    INDEX idx_fecha (created_at),

    FOREIGN KEY (repartidor_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TABLA: detalle_pedido
-- Productos incluidos en cada pedido
CREATE TABLE IF NOT EXISTS detalle_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    producto_nombre VARCHAR(200) NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,

    INDEX idx_pedido (pedido_id),
    INDEX idx_producto (producto_id),

    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- TABLA: sesiones
-- Control de sesiones activas (opcional / seguridad)
CREATE TABLE IF NOT EXISTS sesiones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_token (token),
    INDEX idx_usuario (usuario_id),
    INDEX idx_expires (expires_at),

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- BLOQUE 2: VISTAS
-- ============================================================

-- Vista: Productos con bajo stock
CREATE OR REPLACE VIEW productos_bajo_stock AS
SELECT
    p.id, p.nombre, p.codigo_barras, p.categoria,
    p.stock, p.stock_minimo, p.precio
FROM productos p
WHERE p.stock <= p.stock_minimo AND p.activo = TRUE;

-- Vista: Ventas diarias por vendedor
CREATE OR REPLACE VIEW ventas_diarias AS
SELECT
    DATE(v.fecha_venta) AS fecha,
    COUNT(*) AS total_ventas,
    SUM(v.total) AS total_ingresos,
    AVG(v.total) AS ticket_promedio,
    u.nombre AS vendedor
FROM ventas v
JOIN usuarios u ON v.vendedor_id = u.id
WHERE v.estado = 'completada'
GROUP BY DATE(v.fecha_venta), v.vendedor_id, u.nombre;

-- Vista: Top productos más vendidos
CREATE OR REPLACE VIEW top_productos_vendidos AS
SELECT
    p.id, p.nombre, p.categoria,
    SUM(dv.cantidad) AS total_vendido,
    SUM(dv.subtotal) AS ingresos_generados
FROM productos p
JOIN detalles_venta dv ON p.id = dv.producto_id
JOIN ventas v ON dv.venta_id = v.id
WHERE v.estado = 'completada'
GROUP BY p.id, p.nombre, p.categoria
ORDER BY total_vendido DESC;

-- Vista: Resumen de lotes por producto (para PEPS/UEPS)
CREATE OR REPLACE VIEW resumen_lotes AS
SELECT
    p.id AS producto_id,
    p.nombre AS producto,
    p.codigo_barras,
    COUNT(l.id) AS total_lotes,
    SUM(l.cantidad_restante) AS unidades_disponibles,
    MIN(l.fecha_entrada) AS lote_mas_antiguo,
    MAX(l.fecha_entrada) AS lote_mas_reciente,
    AVG(l.costo_unitario) AS costo_promedio,
    SUM(l.cantidad_restante * l.costo_unitario) AS valor_inventario
FROM productos p
LEFT JOIN lotes_inventario l ON p.id = l.producto_id
    AND l.cantidad_restante > 0 AND l.activo = TRUE
GROUP BY p.id, p.nombre, p.codigo_barras;

-- Vista: Lotes próximos a vencer (próximos 30 días)
CREATE OR REPLACE VIEW lotes_proximos_vencer AS
SELECT
    l.id AS lote_id,
    p.nombre AS producto,
    p.codigo_barras,
    l.cantidad_restante,
    l.fecha_vencimiento,
    DATEDIFF(l.fecha_vencimiento, CURDATE()) AS dias_hasta_vencimiento,
    l.costo_unitario,
    l.proveedor
FROM lotes_inventario l
JOIN productos p ON l.producto_id = p.id
WHERE l.fecha_vencimiento IS NOT NULL
  AND l.cantidad_restante > 0
  AND l.activo = TRUE
  AND DATEDIFF(l.fecha_vencimiento, CURDATE()) BETWEEN 0 AND 30
ORDER BY dias_hasta_vencimiento ASC;

-- ============================================================
-- BLOQUE 3: PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DROP PROCEDURE IF EXISTS actualizar_costo_promedio;
DELIMITER //
CREATE PROCEDURE actualizar_costo_promedio(IN p_producto_id INT)
BEGIN
    DECLARE v_costo_prom DECIMAL(10,2);
    SELECT
        IFNULL(SUM(cantidad_restante * costo_unitario) / NULLIF(SUM(cantidad_restante), 0), 0)
    INTO v_costo_prom
    FROM lotes_inventario
    WHERE producto_id = p_producto_id
      AND cantidad_restante > 0
      AND activo = TRUE;
    UPDATE productos SET costo_promedio = v_costo_prom WHERE id = p_producto_id;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS registrar_entrada_lote;
DELIMITER //
CREATE PROCEDURE registrar_entrada_lote(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_costo_unitario DECIMAL(10,2),
    IN p_proveedor VARCHAR(150),
    IN p_factura VARCHAR(100),
    IN p_fecha_vencimiento DATE,
    IN p_usuario_id INT,
    OUT p_lote_id INT
)
BEGIN
    DECLARE v_stock_anterior INT;
    DECLARE v_costo_total DECIMAL(10,2);
    SET v_costo_total = p_cantidad * p_costo_unitario;
    SELECT stock INTO v_stock_anterior FROM productos WHERE id = p_producto_id;
    INSERT INTO lotes_inventario (
        producto_id, cantidad_inicial, cantidad_restante,
        costo_unitario, costo_total, proveedor, factura_compra,
        fecha_vencimiento, created_by
    ) VALUES (
        p_producto_id, p_cantidad, p_cantidad,
        p_costo_unitario, v_costo_total, p_proveedor, p_factura,
        p_fecha_vencimiento, p_usuario_id
    );
    SET p_lote_id = LAST_INSERT_ID();
    UPDATE productos SET stock = stock + p_cantidad WHERE id = p_producto_id;
    INSERT INTO movimientos_inventario (
        producto_id, tipo_movimiento, cantidad,
        stock_anterior, stock_nuevo, referencia, usuario_id
    ) VALUES (
        p_producto_id, 'entrada', p_cantidad,
        v_stock_anterior, v_stock_anterior + p_cantidad,
        CONCAT('LOTE-', p_lote_id), p_usuario_id
    );
    CALL actualizar_costo_promedio(p_producto_id);
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS procesar_venta_peps;
DELIMITER //
CREATE PROCEDURE procesar_venta_peps(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_detalle_venta_id INT,
    OUT p_costo_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_cantidad_restante INT DEFAULT p_cantidad;
    DECLARE v_lote_id INT;
    DECLARE v_lote_cantidad INT;
    DECLARE v_lote_costo DECIMAL(10,2);
    DECLARE v_cantidad_usar INT;
    DECLARE v_costo_parcial DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;
    -- FIFO: lote más antiguo primero
    DECLARE lotes_cursor CURSOR FOR
        SELECT id, cantidad_restante, costo_unitario
        FROM lotes_inventario
        WHERE producto_id = p_producto_id
          AND cantidad_restante > 0 AND activo = TRUE
        ORDER BY fecha_entrada ASC, id ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET p_costo_total = 0;
    OPEN lotes_cursor;
    read_loop: LOOP
        FETCH lotes_cursor INTO v_lote_id, v_lote_cantidad, v_lote_costo;
        IF done OR v_cantidad_restante <= 0 THEN LEAVE read_loop; END IF;
        SET v_cantidad_usar = LEAST(v_cantidad_restante, v_lote_cantidad);
        SET v_costo_parcial = v_cantidad_usar * v_lote_costo;
        INSERT INTO detalle_costo_venta (detalle_venta_id, lote_id, cantidad, costo_unitario, costo_total)
        VALUES (p_detalle_venta_id, v_lote_id, v_cantidad_usar, v_lote_costo, v_costo_parcial);
        UPDATE lotes_inventario SET cantidad_restante = cantidad_restante - v_cantidad_usar WHERE id = v_lote_id;
        SET p_costo_total = p_costo_total + v_costo_parcial;
        SET v_cantidad_restante = v_cantidad_restante - v_cantidad_usar;
    END LOOP;
    CLOSE lotes_cursor;
    IF v_cantidad_restante > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente en lotes (PEPS)';
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS procesar_venta_ueps;
DELIMITER //
CREATE PROCEDURE procesar_venta_ueps(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_detalle_venta_id INT,
    OUT p_costo_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_cantidad_restante INT DEFAULT p_cantidad;
    DECLARE v_lote_id INT;
    DECLARE v_lote_cantidad INT;
    DECLARE v_lote_costo DECIMAL(10,2);
    DECLARE v_cantidad_usar INT;
    DECLARE v_costo_parcial DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;
    -- LIFO: lote más reciente primero
    DECLARE lotes_cursor CURSOR FOR
        SELECT id, cantidad_restante, costo_unitario
        FROM lotes_inventario
        WHERE producto_id = p_producto_id
          AND cantidad_restante > 0 AND activo = TRUE
        ORDER BY fecha_entrada DESC, id DESC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET p_costo_total = 0;
    OPEN lotes_cursor;
    read_loop: LOOP
        FETCH lotes_cursor INTO v_lote_id, v_lote_cantidad, v_lote_costo;
        IF done OR v_cantidad_restante <= 0 THEN LEAVE read_loop; END IF;
        SET v_cantidad_usar = LEAST(v_cantidad_restante, v_lote_cantidad);
        SET v_costo_parcial = v_cantidad_usar * v_lote_costo;
        INSERT INTO detalle_costo_venta (detalle_venta_id, lote_id, cantidad, costo_unitario, costo_total)
        VALUES (p_detalle_venta_id, v_lote_id, v_cantidad_usar, v_lote_costo, v_costo_parcial);
        UPDATE lotes_inventario SET cantidad_restante = cantidad_restante - v_cantidad_usar WHERE id = v_lote_id;
        SET p_costo_total = p_costo_total + v_costo_parcial;
        SET v_cantidad_restante = v_cantidad_restante - v_cantidad_usar;
    END LOOP;
    CLOSE lotes_cursor;
    IF v_cantidad_restante > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente en lotes (UEPS)';
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS actualizar_stock_venta;
DELIMITER //
CREATE PROCEDURE actualizar_stock_venta(
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_venta_id INT
)
BEGIN
    DECLARE v_stock_anterior INT;
    SELECT stock INTO v_stock_anterior FROM productos WHERE id = p_producto_id;
    UPDATE productos SET stock = stock - p_cantidad WHERE id = p_producto_id;
    INSERT INTO movimientos_inventario (producto_id, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, referencia)
    VALUES (p_producto_id, 'venta', -p_cantidad, v_stock_anterior, v_stock_anterior - p_cantidad, CONCAT('VENTA-', p_venta_id));
END //
DELIMITER ;

-- ============================================================
-- BLOQUE 4: TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS after_detalle_venta_insert;
DELIMITER //
CREATE TRIGGER after_detalle_venta_insert
AFTER INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    CALL actualizar_stock_venta(NEW.producto_id, NEW.cantidad, NEW.venta_id);
END //
DELIMITER ;

-- ============================================================
-- BLOQUE 5: DATOS SEMILLA (Demo)
-- Passwords reales hasheados con bcrypt (admin123 / vendedor123 / repartidor123)
-- ============================================================

INSERT IGNORE INTO usuarios (nombre, email, password_hash, rol, activo, telefono) VALUES
-- admin123
('Administrador', 'admin@tienda.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'admin', TRUE, '555-0001'),
-- vendedor123
('Vendedor Demo', 'vendedor@tienda.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'vendedor', TRUE, '555-0002'),
-- repartidor123
('Repartidor Demo', 'repartidor@tienda.com',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'repartidor', TRUE, '555-0003');

-- Productos iniciales (creados por admin = id 1)
INSERT IGNORE INTO productos
    (codigo_barras, nombre, descripcion, categoria, precio, costo, stock, stock_minimo, unidad, created_by)
VALUES
('7501234567890', 'Coca-Cola 600ml',       'Refresco de cola',       'Bebidas',   15.00, 10.00, 100, 20, 'pcs', 1),
('7501234567891', 'Sabritas Original 45g', 'Papas fritas',           'Botanas',   12.00,  8.00,  80, 15, 'pcs', 1),
('7501234567892', 'Pan Blanco Bimbo',      'Pan de caja blanco',     'Panaderia', 35.00, 25.00,  30, 10, 'pcs', 1),
('7501234567893', 'Leche Lala 1L',         'Leche entera',           'Lacteos',   22.00, 16.00,  50, 15, 'pcs', 1),
('7501234567894', 'Huevos San Juan 12pz',  'Huevos frescos',         'Huevos',    45.00, 35.00,  25, 10, 'pcs', 1),
('7501234567895', 'Agua Ciel 1.5L',        'Agua purificada',        'Bebidas',    9.00,  5.00, 120, 30, 'pcs', 1),
('7501234567896', 'Jabón Palmolive',       'Jabón de manos',         'Limpieza',  18.00, 12.00,  60, 10, 'pcs', 1),
('7501234567897', 'Papel Higiénico Regio', 'Paquete 4 rollos',       'Limpieza',  32.00, 22.00,  40, 10, 'pcs', 1);

SELECT CONCAT('✅ Base de datos Tienda Manager inicializada — ', NOW()) AS resultado;
