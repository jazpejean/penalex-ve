# Penalex VE - Videojuego Jurídico de Derecho Penal Venezolano

Proyecto completo desarrollado en **Flutter** con el motor de juegos **Flame**, ambientado con una estética **Colonial Venezolana pura** (siglos XVIII-XIX), sobria, institucional y profesional.

---

## 🏛️ Estilo Visual & Arquitectura Colonial
- **Materiales**: Adoquines de piedra colonial, mármol blanco, bronce, hierro forjado y tejas rojas.
- **Paleta Institucional**: Azul noche (`#0B1528`), Blanco roto (`#F8F6F0`), Beige pergamino (`#EADBC8`), Oro judicial (`#D4AF37`) y Bronce (`#8C6239`).
- **Iluminación**: Luz solar radiante y cielo azul despejado.
- **Camino Sinuoso**: Curva matemática continua en "S" con adoquines de 300px de ancho y faroles de hierro forjado a los costados.

---

## 🗺️ Las 21 Regiones de Venezuela y sus Monumentos
1. **Distrito Capital (Caracas)**: El Ávila, Estatua ecuestre de Bolívar en la Plaza Bolívar, Panteón Nacional y casas coloniales. (Niveles 1–143)
2. **Miranda (Los Teques)**: Circuito Judicial Penal, Plaza Bolívar de Los Teques y faroles de hierro forjado. (Niveles 144–286)
3. **Vargas (La Guaira)**: Fuerte San Carlos, el puerto colonial y el Tribunal del Puerto. (Niveles 287–429)
4. **Aragua (Maracay)**: Circuito Judicial, palmas reales y araguaneyes amarillos en flor. (Niveles 430–572)
5. **Carabobo (Valencia)**: Campo de Carabobo (obelisco), Palacio de Justicia y columnas corintias. (Niveles 573–715)
6. **Zulia (Maracaibo)**: Basílica de Chiquinquirá, Circuito Judicial y Lago de Maracaibo. (Niveles 716–858)
7. **Lara (Barquisimeto)**: Catedral de Barquisimeto y Circuito Judicial. (Niveles 859–1001)
8. **Táchira (San Cristóbal)**: Catedral de San Cristóbal, Palacio de los Leones y los Andes. (Niveles 1002–1144)
9. **Mérida (Mérida)**: Universidad de Los Andes (ULA), Catedral de Mérida y picos nevados. (Niveles 1145–1287)
10. **Bolívar (Ciudad Bolívar)**: Casa del Congreso de Angostura, Río Orinoco y Palacio de Justicia. (Niveles 1288–1430)
11. **Anzoátegui (Barcelona)**: Casa Fuerte de Barcelona, Circuito Judicial y costa caribeña. (Niveles 1431–1573)
12. **Sucre (Cumaná)**: Castillo de San Antonio de la Eminencia y Mar Caribe. (Niveles 1574–1716)
13. **Monagas (Maturín)**: Circuito Judicial y sabana oriental. (Niveles 1717–1859)
14. **Delta Amacuro (Tucupita)**: Circuito Judicial y palafitos del Delta del Orinoco. (Niveles 1860–2002)
15. **Amazonas (Puerto Ayacucho)**: Selva Amazónica y Salto Ángel al fondo. (Niveles 2003–2145)
16. **Apure (San Fernando)**: Circuito Judicial y llanos venezolanos. (Niveles 2146–2288)
17. **Barinas (Barinas)**: Circuito Judicial y llanos altos. (Niveles 2289–2431)
18. **Portuguesa (Guanare)**: Santuario de Nuestra Señora de Coromoto y Circuito Judicial. (Niveles 2432–2574)
19. **Cojedes (San Carlos)**: Circuito Judicial y llanos centrales. (Niveles 2575–2717)
20. **Guárico (San Juan de los Morros)**: Los Morros de San Juan y Circuito Judicial. (Niveles 2718–2860)
21. **Yaracuy (San Felipe)**: Santuario de María Lionza y Circuito Judicial. (Niveles 2861–3000)

---

## ⚖️ Sistema de Quiz, Gamificación y Anti-Trampa
- **3000 Niveles Procedurales**: Casos forenses basados en el Código Penal Venezolano (CPV).
- **Gamificación**: 10 XP por acierto (15 XP si hay racha activa).
- **Sistema de Apelaciones**:
  - Inicia con 5 apelaciones.
  - Cada fallo resta 1 apelación de inmediato.
  - Se regenera 1 apelación cada 30 minutos de forma persistente.
  - Con 0 apelaciones no se puede litigar.
  - **Bloqueo por 3 fallos**: Si se falla 3 veces el mismo caso, el nivel se bloquea con candado y requiere consignar 1 apelación para desbloquear.
- **Motor Anti-Trampa**:
  - 5 variantes aleatorias de casos por nivel. Si se sale a mitad del caso, al volver se asigna otra variante.
  - Opciones barajadas aleatoriamente.
  - **Penalización por celeridad**: Si el usuario responde en menos de 3.0 segundos, se marca como incorrecta y se descuenta la apelación sin mostrar la fundamentación legal.

---

## 📜 Banner Superior Pergamino & Sonidos Sintetizados
- HUD superior con avatar judicial, rango de la magistratura, barra de XP y 5 pergaminos dibujados con `Canvas` (`CustomPainter`).
- Sonidos en `assets/audio/`:
  - `correct.wav`: Arpegio mayor ascendente.
  - `error.wav`: Tono menor descendente solemne.
  - `fanfare.wav`: Fanfarria triunfal de ascenso.
  - `gavel.wav`: Golpe de mazo judicial.

---

## 🚀 Cómo Ejecutar el Proyecto en tu Máquina
1. Asegúrate de tener instalado **Flutter** (`flutter --version`).
2. Abre la terminal dentro de esta carpeta (`flutter_project`).
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta en tu emulador o dispositivo:
   ```bash
   flutter run
   ```
