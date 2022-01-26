-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-01-2022 a las 12:07:25
-- Versión del servidor: 10.4.19-MariaDB
-- Versión de PHP: 8.0.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `inmuebles`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `NuevaVenta` (IN `nombrecomprador` VARCHAR(50), IN `apellidoscomprador` VARCHAR(50), IN `idinmueble` INT(11), IN `localidadventa` VARCHAR(40), IN `importeventa` FLOAT, IN `descripcionventa` VARCHAR(50))  proceso:BEGIN
# añadimos la etiqueta “proceso” para que más adelante cuando no se cumpla una       # condición se salga del procedimiento
    DECLARE idcomprador int(11); 
    # declaramos la variable local donde se almacena el ID del comprador
    DECLARE ncomp varchar(50);
    # declaramos la variable local donde se almacena el nombre del comprador
    DECLARE acomp varchar(50);
    # declaramos la variable local donde se almacena el apellido del comprador
    DECLARE idmunicipio int(11);
    # declaramos la variable local donde se guardará el ID del municipio que se  
    # introduce por parámetros
    DECLARE inmuebleid int(11);
    # declaramos la variable local que hará lo mismo que la anterior pero con el ID de 
    # inmueble
    DECLARE codvend varchar(10);
    # declaramos la variable local donde se guardará el código del vendedor para que se
    # añada a la venta
    DECLARE fech date;
    # variable local que añadirá la fecha actual cada vez que se agregue una venta
    
	SELECT id INTO idcomprador FROM personas WHERE nombre LIKE 	nombrecomprador AND apellidos LIKE apellidoscomprador;
      # se guardará el id del comprador solo y cuando el nombre y apellidos del 
      # se corresponda con los introducidos por parámetros
    	SELECT nombre INTO ncomp from personas WHERE nombre LIKE 	nombrecomprador AND apellidos LIKE apellidoscomprador;
      # lo mismo que el anterior pero con el nombre del comprador
   	SELECT apellidos into acomp FROM personas WHERE apellidos LIKE 	apellidoscomprador AND nombre like nombrecomprador;
      # lo mismo que la anterior pero esta vez con los apellidos
   	SELECT id INTO idmunicipio FROM municipios WHERE nombre like 	localidadventa;
      # se guardará en la variable la id del municipio solo y cuando su nombre, sea el
      # mismo que el introducido por parámetros
    	SELECT id INTO inmuebleid FROM inmuebles WHERE id = idinmueble;
      # lo mismo que la anterior, pero en este caso con el ID de inmueble
    	SELECT codigovendedor INTO codvend from personas p INNER JOIN inmuebles i 	ON p.id = i.PROPIETARIO_ID
   										WHERE i.ID = 	inmuebleid;
      # guardamos el codigo de vendedor en la variable mientras que el propietario de
      # ese inmueble sea el mismo que el ID de una persona donde el id del inmueble
      # sea el mismo que el que se introduce por parámetros
    	SELECT year(now()) INTO fech;
      # almacenamos en esta variable la función que nos devuelve la fecha actual
    # con los siguientes if comprobamos que cada una de las variables declaradas,
    # correspondientes a los atributos pedidos por parámetros, al introducir los datos
    # de la venta compruebe si existen en la base de datos
    if ncomp is null
    THEN
    	SELECT 'No existe el comprador en la Base de Datos';
        LEAVE proceso; 
    END IF;
    if acomp is null
    THEN
    	SELECT 'Apellido no correspondiente';
        LEAVE proceso;
    END IF;
    IF idmunicipio IS null
    THEN
    	SELECT 'Municipio inexistente en la Base de Datos';
    END IF;
    if inmuebleid is null
    THEN
    	SELECT 'ID de inmueble inválido';
        LEAVE proceso;
    END IF;
    IF codvend is null
    THEN
    	SELECT 'Código vendedor no válido';
        LEAVE proceso;
    END IF;
    # una vez cumplida todas las condiciones, es decir, habiendo comprobado que
    # existen todos los datos, se procederá a la inserción de una nueva venta
    INSERT INTO ventas (descripcion, inmueble_id, comprador_id, vendedor_id, importe, municipiodefirmaventa_id, fecha) VALUES
    (descripcionventa, inmuebleid, idcomprador, codvend, importeventa, idmunicipio, fech);
    # actualizamos el propietario del inmueble, ya que al producirse una venta de estos,
    # por lógica, su propietario va a ser uno nuevo, el comprador
    UPDATE inmuebles SET propietario_id = idcomprador WHERE id = inmuebleid;
    	    
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Actualiza_Ventas` () RETURNS VARCHAR(500) CHARSET utf8mb4 BEGIN
	
    DECLARE idagente int(10);
    DECLARE cantidad int(4);
    DECLARE control bit DEFAULT 0;
    DECLARE total varchar(500);
    DECLARE cursoragentes CURSOR FOR (SELECT agente_id, COUNT(agente_id) FROM ventas GROUP BY agente_id);
    DECLARE CONTINUE HANDLER FOR NOT found SET control = 1;
    
    SET total='';
    OPEN cursoragentes;
    proceso:LOOP
    FETCH cursoragentes INTO idagente, cantidad;
    IF control = 1 THEN
    	LEAVE proceso;
    ELSE
    	UPDATE agentes SET numerodeventas = cantidad WHERE id = idagente;
        SET total = concat(total,'El agente ',idagente,' tiene ',cantidad,' ventas','\n');
    END IF;
    END LOOP;
	CLOSE cursoragentes;
    RETURN total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `CorreosElectronicos` () RETURNS VARCHAR(500) CHARSET utf8mb4 BEGIN
	
    DECLARE datos varchar(500);
    DECLARE ecorreo varchar(70);
    DECLARE nombap varchar(100);
    DECLARE control bit DEFAULT 0;
    
    DECLARE micursor CURSOR FOR (SELECT concat(nombre,' ',apellidos), email FROM personas WHERE email is not null);
    DECLARE CONTINUE HANDLER FOR NOT found SET control = 1;
    
    SET datos = '';
    OPEN micursor;
    bucle:LOOP
    	FETCH micursor INTO nombap, ecorreo;
        IF control = 1 THEN
        	LEAVE bucle;
        ELSE
        	SET datos = concat(datos,nombap,'<',ecorreo,'>','\n');
        END IF;
    END LOOP;
    RETURN datos;
    CLOSE micursor;
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `agentes`
--

CREATE TABLE `agentes` (
  `ID` int(11) DEFAULT NULL,
  `fecha_de_alta` datetime DEFAULT current_timestamp(),
  `numerodeventas` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `agentes`
--

INSERT INTO `agentes` (`ID`, `fecha_de_alta`, `numerodeventas`) VALUES
(24, '2021-05-27 09:47:14', 2),
(25, '2021-05-27 09:51:13', 1),
(26, '2021-05-27 09:51:17', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inmuebles`
--

CREATE TABLE `inmuebles` (
  `ID` int(11) NOT NULL,
  `TIPOINMUEBLE_ID` int(11) NOT NULL,
  `NUMEROPLANTAS` int(11) DEFAULT NULL,
  `DIRECCION` varchar(100) NOT NULL,
  `METROSCUADRADOS` int(11) NOT NULL,
  `MUNICIPIO_ID` int(11) NOT NULL,
  `PROPIETARIO_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `inmuebles`
--

INSERT INTO `inmuebles` (`ID`, `TIPOINMUEBLE_ID`, `NUMEROPLANTAS`, `DIRECCION`, `METROSCUADRADOS`, `MUNICIPIO_ID`, `PROPIETARIO_ID`) VALUES
(1, 1, 2, 'Calle de Juan Sanchez', 90, 1, 12),
(2, 1, 3, 'Calle de la Montaña', 80, 1, 1),
(3, 1, 3, 'Calle Benito Pérez Galdós', 90, 2, 1),
(4, 1, 3, 'Alonso Martin, 12', 900, 7, 14),
(5, 1, 2, 'Calle Imagen y Sonido,3 - A', 90, 1, 12);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `municipios`
--

CREATE TABLE `municipios` (
  `ID` int(11) NOT NULL,
  `NOMBRE` varchar(50) NOT NULL,
  `NUMEROHABITANTES` int(11) DEFAULT NULL,
  `PROVINCIA_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `municipios`
--

INSERT INTO `municipios` (`ID`, `NOMBRE`, `NUMEROHABITANTES`, `PROVINCIA_ID`) VALUES
(1, 'Cáceres', 90000, 1),
(2, 'Trujillo', 9437, 1),
(3, 'Badajoz', 150000, 2),
(4, 'Mérida', 60000, 2),
(5, 'Madrid', 2000000, 3),
(6, 'Alcalá de Henares', 400000, 3),
(7, 'Don Benito', 35000, 2),
(8, 'Villanueva de la Serena', 25000, 2),
(11, 'Azuaga', 10000, 2),
(14, 'TALAVERA', NULL, 1),
(15, 'VALLE DE LA SERENA', NULL, 1);

--
-- Disparadores `municipios`
--
DELIMITER $$
CREATE TRIGGER `convierteMayus` BEFORE INSERT ON `municipios` FOR EACH ROW BEGIN
	set new.nombre = upper(new.nombre);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `meterEnCaceres` BEFORE INSERT ON `municipios` FOR EACH ROW BEGIN
	DECLARE idcaceres varchar(50);
    SELECT id INTO idcaceres FROM provincias WHERE nombre LIKE 'Cáceres';
	IF new.provincia_id is null THEN
    	SET new.provincia_id = idcaceres;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personas`
--

CREATE TABLE `personas` (
  `id` int(11) NOT NULL,
  `DNI` varchar(9) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `APELLIDOS` varchar(50) NOT NULL,
  `DIRECCION` varchar(100) DEFAULT NULL,
  `MUNICIPIO_ID` int(11) NOT NULL,
  `PADRE_ID` int(11) DEFAULT NULL,
  `CODIGOVENDEDOR` varchar(10) DEFAULT NULL,
  `email` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personas`
--

INSERT INTO `personas` (`id`, `DNI`, `nombre`, `APELLIDOS`, `DIRECCION`, `MUNICIPIO_ID`, `PADRE_ID`, `CODIGOVENDEDOR`, `email`) VALUES
(1, '99999999Y', 'Juan', 'Sánchez', 'Calle de Juan Sanchez', 1, NULL, 'cod999999', 'juanito_elboss@gmail.com'),
(2, '88888888O', 'Luis', 'Sánchez', 'Calle de Juan Sanchez', 1, 1, NULL, 'luis_pistolo@hotmail.com'),
(4, '77777777S', 'Fermin', 'Valiente', 'Calle de Fermin Valiente', 2, NULL, 'cod777777', 'fvaliente01@yahoo.com'),
(5, '66666666S', 'Magdalena', 'Cifuentes', 'Calle de Magdalena Cifuentes', 2, NULL, NULL, NULL),
(11, '55555555C', 'Antonia', 'López', 'Calle de Antonia López', 2, NULL, 'cod555555', 'alopez_yomisma@pecesgordo.org'),
(12, '44444444C', 'Pedro', 'Jiménez', 'Calle de Antonia López', 2, NULL, 'cod444444', NULL),
(13, '33333333T', 'Carmina', 'Sánchez', 'Calle de Juan Sanchez', 1, 1, NULL, NULL),
(14, '06000243V', 'Consejería', 'de Educación y Cultura', 'Avda. Valhondo s/n', 4, NULL, 'cod8384349', NULL),
(24, '47589651Y', 'Juan', 'Ruiz del Olmo', NULL, 3, NULL, NULL, NULL),
(25, '44445555X', 'Paco', 'de la Montaña Pérez', NULL, 2, NULL, NULL, NULL),
(26, '47859999N', 'Mónica', 'Suárez Mótril', NULL, 3, NULL, NULL, NULL);

--
-- Disparadores `personas`
--
DELIMITER $$
CREATE TRIGGER `comprobarDni` BEFORE INSERT ON `personas` FOR EACH ROW proceso:BEGIN
	
    -- variable que almacenará los 8 primeros dígitos del DNI
    DECLARE numsdni int(8);
    -- variable que almacenará la letra del DNI
    DECLARE letradni varchar(1);
    -- variable para comparar con la anterior, ya que contendrá la letra correcta
    DECLARE letradnicorrecta varchar(1);
    -- variable que almacenará el resto resultado de la división de comprobación de DNI
    DECLARE restoDiv int(2);
    DECLARE mensajeSalida varchar(50);
    
    SET numsdni = LEFT(new.dni,8);
    SET letradni = RIGHT(new.dni, 1);       
    
    SET restoDiv = MOD(numsdni, 23); 
    
        CASE restoDiv
			WHEN 0 THEN
 			 SET letradnicorrecta = 'T';
        
            WHEN 1 THEN 
             SET letradnicorrecta = 'R';
         
            WHEN 2 THEN
 			 SET letradnicorrecta = 'W';
        
            WHEN 3 THEN 
             SET letradnicorrecta = 'A';
     
            WHEN 4 THEN 
             SET letradnicorrecta = 'G';

            WHEN 5 THEN 
             SET letradnicorrecta = 'M';
          
            WHEN 6 THEN 
             SET letradnicorrecta = 'Y';
           
            WHEN 7 THEN 
             SET letradnicorrecta = 'F';
         
            WHEN 8 THEN 
             SET letradnicorrecta = 'P';
         
            WHEN 9 THEN 
             SET letradnicorrecta = 'D';
            
            WHEN 10 THEN 
             SET letradnicorrecta = 'X';
         
            WHEN 11 THEN 
             SET letradnicorrecta = 'B';
          
            WHEN 12 THEN 
             SET letradnicorrecta = 'N';
            
            WHEN 13 THEN 
             SET letradnicorrecta = 'J';
          
            WHEN 14 THEN 
             SET letradnicorrecta = 'Z';
             
            WHEN 15 THEN 
             SET letradnicorrecta = 'S';
        
            WHEN 16 THEN 
             SET letradnicorrecta = 'Q';
          
            WHEN 17 THEN 
             SET letradnicorrecta = 'V';
            
            WHEN 18 THEN 
             SET letradnicorrecta = 'H';
        
            WHEN 19 THEN 
             SET letradnicorrecta = 'L';
          
            WHEN 20 THEN 
             SET letradnicorrecta = 'C';
           
            WHEN 21 THEN 
             SET letradnicorrecta = 'K';
          
            WHEN 22 THEN 
             SET letradnicorrecta = 'E';
			
			ELSE
            	BEGIN
        			SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'ERROR CON EL RESTO DEL ALGORITMO, DNI INCORRECTO';
                END;
        END CASE;
		
        IF letradni LIKE letradnicorrecta THEN
        	SELECT 'El DNI es correcto' INTO mensajeSalida;
            LEAVE proceso;
        ELSE
        	SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'La letra del DNI es incorrecta';
        END IF;
        
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `papelerapersonas` AFTER DELETE ON `personas` FOR EACH ROW BEGIN
  
    -- se inserta en la tabla de personas_papelera los datos que se borren de la tabla de personas
	INSERT INTO personas_papelera (id, DNI, nombre, APELLIDOS, DIRECCION, MUNICIPIO_ID, PADRE_ID, CODIGOVENDEDOR, email ) VALUES 		(old.id, old.DNI,old.nombre, old.apellidos, old.direccion, old.municipio_id, old.padre_id, old.codigovendedor, old.email);
	
    -- se borra las filas cada vez que se ejecute el trigger, en la que el año actual 
    -- menos el año en el que se borro a esa persona, de como resultado 4 o mayor que 4
    DELETE FROM personas_papelera WHERE now() - fecha_eliminacion >= year(4);
    
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personas_papelera`
--

CREATE TABLE `personas_papelera` (
  `id` int(11) NOT NULL,
  `DNI` varchar(9) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `APELLIDOS` varchar(50) NOT NULL,
  `DIRECCION` varchar(100) DEFAULT NULL,
  `MUNICIPIO_ID` int(11) NOT NULL,
  `PADRE_ID` int(11) DEFAULT NULL,
  `CODIGOVENDEDOR` varchar(10) DEFAULT NULL,
  `email` varchar(70) DEFAULT NULL,
  `fecha_eliminacion` datetime DEFAULT current_timestamp(),
  `usuario_que_eliminó` varchar(50) DEFAULT current_user()
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personas_papelera`
--

INSERT INTO `personas_papelera` (`id`, `DNI`, `nombre`, `APELLIDOS`, `DIRECCION`, `MUNICIPIO_ID`, `PADRE_ID`, `CODIGOVENDEDOR`, `email`, `fecha_eliminacion`, `usuario_que_eliminó`) VALUES
(15, '77777777B', 'Alfredo', 'Horizonte', NULL, 11, NULL, NULL, NULL, '2021-05-20 10:07:22', 'root@localhost'),
(18, '08781945H', NULL, 'Suárez', NULL, 2, NULL, NULL, NULL, '2021-05-20 10:33:31', 'root@localhost'),
(19, '08781945H', NULL, 'Suárez', NULL, 2, NULL, NULL, NULL, '2021-05-20 10:39:10', 'root@localhost'),
(20, '89452477A', NULL, 'Pepito', NULL, 2, NULL, NULL, NULL, '2021-05-20 10:08:39', 'root@localhost'),
(21, '47589651Y', 'Juan', 'Ruiz del Olmo', NULL, 3, NULL, NULL, NULL, '2021-05-26 14:04:46', 'root@localhost'),
(22, '55564789D', 'Paco', 'de la Montaña Pérez', NULL, 2, NULL, NULL, NULL, '2021-05-26 14:04:50', 'root@localhost'),
(23, '78004755W', 'Mónica', 'Suárez Motril', NULL, 3, NULL, NULL, NULL, '2021-05-26 14:04:56', 'root@localhost');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `provincias`
--

CREATE TABLE `provincias` (
  `ID` int(11) NOT NULL,
  `NOMBRE` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `provincias`
--

INSERT INTO `provincias` (`ID`, `NOMBRE`) VALUES
(1, 'Cáceres'),
(2, 'Badajoz'),
(3, 'Madrid');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipoinmuebles`
--

CREATE TABLE `tipoinmuebles` (
  `ID` int(11) NOT NULL,
  `NOMBRE` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `tipoinmuebles`
--

INSERT INTO `tipoinmuebles` (`ID`, `NOMBRE`) VALUES
(1, 'Vivienda'),
(2, 'Finca'),
(3, 'Garaje');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `id` int(11) NOT NULL,
  `DESCRIPCION` varchar(500) NOT NULL,
  `INMUEBLE_ID` int(11) NOT NULL,
  `COMPRADOR_ID` int(11) NOT NULL,
  `VENDEDOR_ID` varchar(10) NOT NULL,
  `IMPORTE` float NOT NULL,
  `MUNICIPIODEFIRMAVENTA_ID` int(11) NOT NULL,
  `FECHA` date NOT NULL,
  `Agente_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `ventas`
--

INSERT INTO `ventas` (`id`, `DESCRIPCION`, `INMUEBLE_ID`, `COMPRADOR_ID`, `VENDEDOR_ID`, `IMPORTE`, `MUNICIPIODEFIRMAVENTA_ID`, `FECHA`, `Agente_ID`) VALUES
(1, 'Contrato privado de compra-venta', 1, 1, 'cod555555', 125000, 3, '2018-12-07', 26),
(2, 'Compra por impago de deuda', 2, 1, 'cod555555', 93000, 2, '2005-12-01', 25),
(3, 'Contrato privado de compra-venta', 1, 12, 'cod999999', 150000, 3, '2019-02-28', 24),
(4, 'Contrato privado de compra-venta', 5, 12, 'cod999999', 120000, 3, '2019-03-03', 24);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `agentes`
--
ALTER TABLE `agentes`
  ADD KEY `ID` (`ID`);

--
-- Indices de la tabla `inmuebles`
--
ALTER TABLE `inmuebles`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `MUNICIPIO_ID` (`MUNICIPIO_ID`),
  ADD KEY `PROPIETARIO_ID` (`PROPIETARIO_ID`),
  ADD KEY `TIPOINMUEBLE_ID` (`TIPOINMUEBLE_ID`);

--
-- Indices de la tabla `municipios`
--
ALTER TABLE `municipios`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `PROVINCIA_ID` (`PROVINCIA_ID`);

--
-- Indices de la tabla `personas`
--
ALTER TABLE `personas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CODIGOVENDEDOR` (`CODIGOVENDEDOR`),
  ADD KEY `PADRE_ID` (`PADRE_ID`),
  ADD KEY `MUNICIPIO_ID` (`MUNICIPIO_ID`);

--
-- Indices de la tabla `personas_papelera`
--
ALTER TABLE `personas_papelera`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CODIGOVENDEDOR` (`CODIGOVENDEDOR`),
  ADD KEY `PADRE_ID` (`PADRE_ID`),
  ADD KEY `MUNICIPIO_ID` (`MUNICIPIO_ID`);

--
-- Indices de la tabla `provincias`
--
ALTER TABLE `provincias`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tipoinmuebles`
--
ALTER TABLE `tipoinmuebles`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `COMPRADOR_ID` (`COMPRADOR_ID`),
  ADD KEY `VENDEDOR_ID` (`VENDEDOR_ID`),
  ADD KEY `INMUEBLE_ID` (`INMUEBLE_ID`),
  ADD KEY `MUNICIPIODEFIRMAVENTA_ID` (`MUNICIPIODEFIRMAVENTA_ID`),
  ADD KEY `Agente_ID` (`Agente_ID`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `inmuebles`
--
ALTER TABLE `inmuebles`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `municipios`
--
ALTER TABLE `municipios`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `personas`
--
ALTER TABLE `personas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT de la tabla `personas_papelera`
--
ALTER TABLE `personas_papelera`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT de la tabla `provincias`
--
ALTER TABLE `provincias`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `tipoinmuebles`
--
ALTER TABLE `tipoinmuebles`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `agentes`
--
ALTER TABLE `agentes`
  ADD CONSTRAINT `agentes_ibfk_1` FOREIGN KEY (`ID`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `agentes_ibfk_2` FOREIGN KEY (`ID`) REFERENCES `personas` (`id`);

--
-- Filtros para la tabla `inmuebles`
--
ALTER TABLE `inmuebles`
  ADD CONSTRAINT `inmuebles_ibfk_1` FOREIGN KEY (`MUNICIPIO_ID`) REFERENCES `municipios` (`ID`) ON DELETE NO ACTION,
  ADD CONSTRAINT `inmuebles_ibfk_2` FOREIGN KEY (`PROPIETARIO_ID`) REFERENCES `personas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inmuebles_ibfk_3` FOREIGN KEY (`TIPOINMUEBLE_ID`) REFERENCES `tipoinmuebles` (`ID`) ON DELETE CASCADE;

--
-- Filtros para la tabla `municipios`
--
ALTER TABLE `municipios`
  ADD CONSTRAINT `municipios_ibfk_1` FOREIGN KEY (`PROVINCIA_ID`) REFERENCES `provincias` (`ID`) ON DELETE CASCADE;

--
-- Filtros para la tabla `personas`
--
ALTER TABLE `personas`
  ADD CONSTRAINT `personas_ibfk_2` FOREIGN KEY (`MUNICIPIO_ID`) REFERENCES `municipios` (`ID`),
  ADD CONSTRAINT `personas_ibfk_3` FOREIGN KEY (`PADRE_ID`) REFERENCES `personas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`COMPRADOR_ID`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `ventas_ibfk_3` FOREIGN KEY (`VENDEDOR_ID`) REFERENCES `personas` (`CODIGOVENDEDOR`),
  ADD CONSTRAINT `ventas_ibfk_4` FOREIGN KEY (`INMUEBLE_ID`) REFERENCES `inmuebles` (`ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `ventas_ibfk_5` FOREIGN KEY (`MUNICIPIODEFIRMAVENTA_ID`) REFERENCES `municipios` (`ID`),
  ADD CONSTRAINT `ventas_ibfk_6` FOREIGN KEY (`Agente_ID`) REFERENCES `agentes` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
