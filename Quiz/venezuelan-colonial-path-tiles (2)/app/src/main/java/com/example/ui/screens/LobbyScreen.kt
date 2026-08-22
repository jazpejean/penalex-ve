package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.model.REGIONES_21
import com.example.model.Region
import com.example.model.getRegionForLevel
import com.example.state.GameUiState
import com.example.ui.components.LevelMedallion
import com.example.ui.components.MedallionState
import com.example.ui.components.TopParchmentBanner
import kotlinx.coroutines.launch
import kotlin.math.sin

/**
 * Retorna la coordenada X normalizada (0.0 a 1.0) para posicionar cada medallón
 * sobre el camino de la región de forma continua y armónica.
 */
private fun getLevelXOffset(level: Int): Float {
    val wave = sin((level - 1) * 0.72f)
    return 0.50f + (wave * 0.32f)
}

@Composable
fun LobbyScreen(
    state: GameUiState,
    onLevelSelected: (Int) -> Unit,
    onBackToDashboard: () -> Unit
) {
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val totalLevels = 3000
    val levelsPerChunk = 6

    // Calcular el chunk en el que está el jugador
    val currentLevelChunkIndex = remember(state.nivelActual) {
        (state.nivelActual - 1) / levelsPerChunk
    }

    // Auto-scroll inicial al nivel del jugador
    LaunchedEffect(state.nivelActual) {
        listState.scrollToItem(currentLevelChunkIndex)
    }

    // Región visible calculada según el chunk visible
    val visibleRegion by remember {
        derivedStateOf {
            val visibleChunk = listState.firstVisibleItemIndex
            val approxLevel = ((visibleChunk * levelsPerChunk) + 1).coerceIn(1, totalLevels)
            getRegionForLevel(approxLevel)
        }
    }

    var showRegionPickerSheet by remember { mutableStateOf(false) }
    var selectedRegionForDossier by remember { mutableStateOf<Region?>(null) }

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val screenWidth = maxWidth

        // 1. MAPA SAGA VERTICAL TILEABLE (ReverseLayout: Nivel 1 abajo, Nivel 3000 arriba)
        LazyColumn(
            state = listState,
            reverseLayout = true,
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF060B17))
        ) {
            item {
                Spacer(modifier = Modifier.height(100.dp))
            }

            val totalChunks = (totalLevels + levelsPerChunk - 1) / levelsPerChunk

            items(
                count = totalChunks,
                key = { chunkIndex -> "chunk_$chunkIndex" }
            ) { chunkIndex ->
                val startLvl = (chunkIndex * levelsPerChunk) + 1
                val endLvl = minOf(startLvl + levelsPerChunk - 1, totalLevels)
                val currentRegion = getRegionForLevel(startLvl)
                val prevRegion = if (startLvl > 1) getRegionForLevel(startLvl - 1) else currentRegion
                val isRegionTransition = (currentRegion.id != prevRegion.id)

                Column(modifier = Modifier.fillMaxWidth()) {
                    // Pórtico de la Región
                    if (isRegionTransition || startLvl == 1) {
                        RegionMonumentGateway(
                            region = currentRegion,
                            onInfoClick = { selectedRegionForDossier = currentRegion }
                        )
                    }

                    // Mosaico Seamless con camino continuo integrado
                    SeamlessRegionTile(
                        currentRegion = currentRegion,
                        startLevel = startLvl,
                        endLevel = endLvl,
                        screenWidth = screenWidth,
                        state = state,
                        onLevelSelected = onLevelSelected
                    )
                }
            }

            item {
                TopMapCrownBanner()
                Spacer(modifier = Modifier.height(160.dp))
            }
        }

        // 2. HUD Superior: Pergamino Institucional Fijo
        TopParchmentBanner(
            nivelActual = state.nivelActual,
            xp = state.xp,
            apelaciones = state.apelaciones,
            modifier = Modifier.align(Alignment.TopCenter)
        )

        // 3. Barra de Control Inferior Flotante
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Regresar al Tribunal
            FloatingActionButton(
                onClick = onBackToDashboard,
                containerColor = Color(0xFF003893),
                contentColor = Color(0xFFFFD700),
                shape = CircleShape,
                modifier = Modifier.size(52.dp)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Regresar al Tribunal",
                    modifier = Modifier.size(26.dp)
                )
            }

            // Botón Central: "Ir a mi Caso Actual"
            Button(
                onClick = {
                    scope.launch {
                        listState.animateScrollToItem(currentLevelChunkIndex)
                    }
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFD4AF37),
                    contentColor = Color(0xFF002B72)
                ),
                shape = RoundedCornerShape(20.dp),
                elevation = ButtonDefaults.buttonElevation(8.dp),
                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.GpsFixed,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "Nivel ${state.nivelActual}",
                    fontWeight = FontWeight.Black,
                    fontSize = 12.sp
                )
            }

            // Selector de Regiones (21 Regiones)
            Box(
                modifier = Modifier
                    .shadow(10.dp, RoundedCornerShape(14.dp))
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF081426).copy(alpha = 0.96f))
                    .border(2.dp, Color(0xFFD4AF37), RoundedCornerShape(14.dp))
                    .clickable { showRegionPickerSheet = true }
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Explore,
                        contentDescription = "Regiones",
                        tint = Color(0xFFFFD700),
                        modifier = Modifier.size(22.dp)
                    )
                    Column {
                        Text(
                            text = "REGIÓN ${visibleRegion.id}/21",
                            color = Color(0xFFFFD700),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Black
                        )
                        Text(
                            text = visibleRegion.nombre,
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }

        // 4. Explorador de las 21 Jurisdicciones
        if (showRegionPickerSheet) {
            RegionPickerBottomSheet(
                currentRegion = visibleRegion,
                userLevel = state.nivelActual,
                onRegionSelected = { reg ->
                    showRegionPickerSheet = false
                    val chunkIdx = (reg.nivelInicio - 1) / levelsPerChunk
                    scope.launch {
                        listState.animateScrollToItem(chunkIdx)
                    }
                },
                onDismiss = { showRegionPickerSheet = false }
            )
        }

        // 5. Modal de Dossier Histórico
        selectedRegionForDossier?.let { reg ->
            RegionDetailModal(
                region = reg,
                onDismiss = { selectedRegionForDossier = null }
            )
        }
    }
}

/**
 * Mosaico continuo de la región con arte ilustrado y camino empedrado continuo
 * de alto rendimiento sin sobrecarga GPU.
 */
@Composable
private fun SeamlessRegionTile(
    currentRegion: Region,
    startLevel: Int,
    endLevel: Int,
    screenWidth: Dp,
    state: GameUiState,
    onLevelSelected: (Int) -> Unit
) {
    val tileHeight = 580.dp
    val levelCount = (endLevel - startLevel + 1)
    val stepY = tileHeight / (levelCount + 1)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(tileHeight)
    ) {
        // Capa 1: Fondo ilustrado de la región
        Image(
            painter = painterResource(id = currentRegion.drawableRes),
            contentDescription = currentRegion.nombre,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )

        // Capa 2: Viñeta de transición suave entre mosaicos (Top & Bottom gradient)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF060B17).copy(alpha = 0.65f),
                            Color.Transparent,
                            Color.Transparent,
                            Color(0xFF060B17).copy(alpha = 0.65f)
                        )
                    )
                )
        )

        // Capa 3: Camino continuo de adoquines dorados (Paved Stone Path)
        Canvas(modifier = Modifier.fillMaxSize()) {
            val widthPx = size.width
            val heightPx = size.height
            val stepYPx = heightPx / (levelCount + 1)

            val path = Path()

            // Punto previo para continuidad de curva
            val prevX = widthPx * getLevelXOffset(startLevel - 1)
            val prevY = 0f

            val firstX = widthPx * getLevelXOffset(startLevel)
            val firstY = stepYPx * 1

            path.moveTo((prevX + firstX) / 2f, 0f)

            for (i in 0 until levelCount) {
                val lvl = startLevel + i
                val currX = widthPx * getLevelXOffset(lvl)
                val currY = stepYPx * (i + 1)

                val nextLvl = startLevel + i + 1
                val nextX = widthPx * getLevelXOffset(nextLvl)
                val nextY = if (i == levelCount - 1) heightPx else stepYPx * (i + 2)

                val midX = (currX + nextX) / 2f
                val midY = (currY + nextY) / 2f

                path.quadraticTo(currX, currY, midX, midY)
            }

            // 3.1 Sombra profunda del camino
            drawPath(
                path = path,
                color = Color(0xFF020617).copy(alpha = 0.70f),
                style = Stroke(width = 38f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            )

            // 3.2 Borde dorado del sendero
            drawPath(
                path = path,
                color = Color(0xFFD4AF37).copy(alpha = 0.85f),
                style = Stroke(width = 24f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            )

            // 3.3 Relleno empedrado del camino
            drawPath(
                path = path,
                color = Color(0xFF1E293B),
                style = Stroke(width = 18f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            )

            // 3.4 Línea central de adoquines de oro
            drawPath(
                path = path,
                color = Color(0xFFFFE066).copy(alpha = 0.90f),
                style = Stroke(
                    width = 4f,
                    cap = StrokeCap.Round,
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(16f, 18f), 0f)
                )
            )
        }

        // Capa 4: Medallones de niveles asentados sobre el camino
        for (i in 0 until levelCount) {
            val level = startLevel + i
            val normX = getLevelXOffset(level)
            val levelXDp = (screenWidth * normX) - 35.dp
            val levelYDp = (stepY * (i + 1)) - 35.dp

            val medallionState = when {
                level < state.nivelActual -> MedallionState.COMPLETADO
                level == state.nivelActual -> MedallionState.ACTUAL
                else -> MedallionState.BLOQUEADO
            }

            LevelMedallion(
                level = level,
                state = medallionState,
                onClick = {
                    if (level <= state.nivelActual) {
                        onLevelSelected(level)
                    }
                },
                modifier = Modifier.offset(x = levelXDp, y = levelYDp)
            )
        }
    }
}

/**
 * Pórtico Monumental al iniciar una nueva región.
 */
@Composable
private fun RegionMonumentGateway(
    region: Region,
    onInfoClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .shadow(14.dp, RoundedCornerShape(16.dp))
            .clip(RoundedCornerShape(16.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF002B72),
                        Color(0xFF091222)
                    )
                )
            )
            .border(2.dp, Color(0xFFD4AF37), RoundedCornerShape(16.dp))
            .clickable(onClick = onInfoClick)
            .padding(12.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(Color(0xFFD4AF37), CircleShape)
                    .border(2.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AccountBalance,
                    contentDescription = null,
                    tint = Color(0xFF002B72),
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "JURISDICCIÓN • REGIÓN ${region.id} DE 21",
                    color = Color(0xFFFFD700),
                    fontSize = 10.5.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 0.8.sp
                )
                Text(
                    text = "${region.nombre.uppercase()} — ${region.capitalOEstado.uppercase()}",
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Black,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "Casos ${region.nivelInicio} al ${region.nivelFin} • ${region.monumentos}",
                    color = Color(0xFFCBD5E1),
                    fontSize = 11.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

/**
 * Cima suprema del mapa (Nivel 3000)
 */
@Composable
private fun TopMapCrownBanner() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
            .shadow(16.dp, RoundedCornerShape(18.dp))
            .clip(RoundedCornerShape(18.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFFD4AF37),
                        Color(0xFF8B6914)
                    )
                )
            )
            .border(3.dp, Color.White, RoundedCornerShape(18.dp))
            .padding(20.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Default.Stars,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(42.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "TRIBUNAL SUPREMO DE JUSTICIA",
                color = Color(0xFF0F172A),
                fontSize = 16.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center
            )
            Text(
                text = "CUMBRE DE LA MAGISTRATURA • NIVEL 3000",
                color = Color(0xFF1E293B),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * Modal para saltar rápidamente entre las 21 regiones de Venezuela.
 */
@Composable
private fun RegionPickerBottomSheet(
    currentRegion: Region,
    userLevel: Int,
    onRegionSelected: (Region) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(520.dp),
            shape = RoundedCornerShape(20.dp),
            color = Color(0xFF081426),
            border = androidx.compose.foundation.BorderStroke(2.5.dp, Color(0xFFD4AF37))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "JURISDICCIONES DE VENEZUELA",
                        color = Color(0xFFFFD700),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Black
                    )
                    Text(
                        text = "21 Regiones",
                        color = Color(0xFF94A3B8),
                        fontSize = 12.sp
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(REGIONES_21) { reg ->
                        val isCurrentRegion = reg.id == currentRegion.id
                        val isUnlocked = userLevel >= reg.nivelInicio

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(
                                    if (isCurrentRegion) Color(0xFF003893)
                                    else if (isUnlocked) Color(0xFF13233D)
                                    else Color(0xFF0B1220)
                                )
                                .border(
                                    width = if (isCurrentRegion) 2.dp else 1.dp,
                                    color = if (isCurrentRegion) Color(0xFFFFD700)
                                    else if (isUnlocked) Color(0xFFD4AF37).copy(alpha = 0.5f)
                                    else Color(0xFF334155),
                                    shape = RoundedCornerShape(12.dp)
                                )
                                .clickable { onRegionSelected(reg) }
                                .padding(10.dp)
                        ) {
                            Column {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        text = "R${reg.id}",
                                        color = if (isCurrentRegion) Color(0xFFFFD700) else Color(0xFF94A3B8),
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Black
                                    )
                                    Text(
                                        text = "${reg.nivelInicio}-${reg.nivelFin}",
                                        color = Color(0xFF64748B),
                                        fontSize = 9.sp
                                    )
                                }
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = reg.nombre,
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = reg.capitalOEstado,
                                    color = Color(0xFF94A3B8),
                                    fontSize = 10.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFD4AF37),
                        contentColor = Color(0xFF081426)
                    ),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Text("CERRAR EXPLORADOR", fontWeight = FontWeight.Black)
                }
            }
        }
    }
}

/**
 * Modal de Dossier Histórico y Monumentos de la Región.
 */
@Composable
private fun RegionDetailModal(
    region: Region,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(16.dp, RoundedCornerShape(18.dp))
                .clip(RoundedCornerShape(18.dp))
                .background(Color(0xFF081426))
                .border(3.dp, Color(0xFFD4AF37), RoundedCornerShape(18.dp))
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(170.dp)
                ) {
                    Image(
                        painter = painterResource(id = region.drawableRes),
                        contentDescription = region.nombre,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        Color(0xFF081426).copy(alpha = 0.95f)
                                    )
                                )
                            )
                    )
                    Text(
                        text = "REGIÓN ${region.id} • ${region.nombre.uppercase()}",
                        color = Color(0xFFFFD700),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Black,
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .padding(14.dp)
                    )
                }

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Capital / Circuito: ${region.capitalOEstado}",
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = region.descripcion,
                        color = Color(0xFFCBD5E1),
                        fontSize = 12.sp,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "Patrimonio & Monumentos:",
                        color = Color(0xFFFFD700),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = region.monumentos,
                        color = Color(0xFFF1F5F9),
                        fontSize = 12.sp
                    )
                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = onDismiss,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFD4AF37),
                            contentColor = Color(0xFF003893)
                        ),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("CONTINUAR EN EL MAPA", fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}
