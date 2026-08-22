package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.getQuestionForLevel
import com.example.service.SoundSynthesizer
import com.example.state.GameUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizGameScreen(
    level: Int,
    state: GameUiState,
    onAnswerSubmitted: (Int, Boolean) -> Unit,
    onUseAppeal: (Int) -> Unit,
    onBack: () -> Unit
) {
    val question = remember(level) { getQuestionForLevel(level) }
    var selectedOption by remember { mutableStateOf<Int?>(null) }
    var isEvaluated by remember { mutableStateOf(false) }
    var isCorrect by remember { mutableStateOf(false) }

    val fallos = state.fallosPorNivel[level] ?: 0
    val isLocked = fallos >= 3

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "CASO JUDICIAL - NIVEL $level",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Black,
                            color = Color(0xFFFCDD09)
                        )
                        Text(
                            text = question.dificultad,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Regresar",
                            tint = Color(0xFFD4AF37)
                        )
                    }
                },
                actions = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(end = 16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Gavel,
                            contentDescription = null,
                            tint = Color(0xFFD4AF37),
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "${state.apelaciones} Apelaciones",
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFF003893)
                )
            )
        },
        containerColor = Color(0xFF0B1020)
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // 1. Cuadro del Caso Narrativo (Estilo Formal/Pergamino)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(6.dp, RoundedCornerShape(10.dp))
                    .background(Color.White, RoundedCornerShape(10.dp))
                    .border(2.5.dp, Color(0xFFD4AF37), RoundedCornerShape(10.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = question.delitoBase.uppercase(),
                        color = Color(0xFF003893),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.sp
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = question.contextoNarrativo,
                        color = Color(0xFF1E293B),
                        fontSize = 14.sp,
                        lineHeight = 20.sp,
                        fontWeight = FontWeight.Normal
                    )
                }
            }

            Spacer(modifier = Modifier.height(18.dp))

            // 2. Si el caso está bloqueado por 3 fallos
            if (isLocked) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFFCF142B).copy(alpha = 0.15f), RoundedCornerShape(10.dp))
                        .border(1.5.dp, Color(0xFFCF142B), RoundedCornerShape(10.dp))
                        .padding(20.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = null,
                            tint = Color(0xFFCF142B),
                            modifier = Modifier.size(40.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "CASO BLOQUEADO (3 FALLOS)",
                            color = Color(0xFFCF142B),
                            fontWeight = FontWeight.Black,
                            fontSize = 15.sp
                        )
                        Text(
                            text = "Debe interponer un recurso de apelación para reabrir el expediente.",
                            color = Color.White.copy(alpha = 0.8f),
                            fontSize = 12.sp,
                            modifier = Modifier.padding(top = 4.dp, bottom = 14.dp)
                        )
                        Button(
                            onClick = {
                                if (state.apelaciones > 0) {
                                    SoundSynthesizer.playGavel()
                                    onUseAppeal(level)
                                    isEvaluated = false
                                    selectedOption = null
                                }
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFFD4AF37),
                                contentColor = Color(0xFF003893)
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Icon(Icons.Default.Gavel, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "USAR APELACIÓN (${state.apelaciones} DISPONIBLES)",
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            } else {
                // 3. Opciones de respuesta A, B, C, D
                val letters = listOf("A", "B", "C", "D")
                question.opciones.forEachIndexed { index, opcion ->
                    val isSelected = selectedOption == index
                    val isLockedOption = isEvaluated

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 10.dp)
                            .background(
                                if (isSelected) Color(0xFF1B2440) else Color(0xFF131A2E),
                                RoundedCornerShape(8.dp)
                            )
                            .border(
                                width = if (isSelected) 2.dp else 1.dp,
                                color = if (isSelected) Color(0xFFD4AF37) else Color.White.copy(alpha = 0.15f),
                                shape = RoundedCornerShape(8.dp)
                            )
                            .clickable(enabled = !isLockedOption) {
                                selectedOption = index
                            }
                            .padding(14.dp)
                    ) {
                        Row(verticalAlignment = Alignment.Top) {
                            Text(
                                text = "${letters[index]}) ",
                                color = Color(0xFFFCDD09),
                                fontWeight = FontWeight.Black,
                                fontSize = 14.sp
                            )
                            Text(
                                text = opcion,
                                color = Colors.White,
                                fontSize = 13.sp,
                                lineHeight = 18.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Botón Dictar Sentencia
                if (!isEvaluated && selectedOption != null) {
                    Button(
                        onClick = {
                            val correct = selectedOption == question.respuestaCorrecta
                            isCorrect = correct
                            isEvaluated = true

                            if (correct) {
                                SoundSynthesizer.playSuccess()
                            } else {
                                SoundSynthesizer.playError()
                            }
                            onAnswerSubmitted(level, correct)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFD4AF37),
                            contentColor = Color(0xFF003893)
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "DICTAR SENTENCIA JURÍDICA",
                            fontWeight = FontWeight.Black,
                            fontSize = 14.sp,
                            letterSpacing = 1.sp
                        )
                    }
                }

                // 4. Panel de Retroalimentación Anti-Trampa
                AnimatedVisibility(
                    visible = isEvaluated,
                    enter = fadeIn() + slideInVertically()
                ) {
                    Column(modifier = Modifier.padding(top = 14.dp)) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    if (isCorrect) Color(0xFF27AE60).copy(alpha = 0.15f)
                                    else Color(0xFFE67E22).copy(alpha = 0.15f),
                                    RoundedCornerShape(8.dp)
                                )
                                .border(
                                    1.5.dp,
                                    if (isCorrect) Color(0xFF27AE60) else Color(0xFFE67E22),
                                    RoundedCornerShape(8.dp)
                                )
                                .padding(16.dp)
                        ) {
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = if (isCorrect) Icons.Default.CheckCircle else Icons.Default.Warning,
                                        contentDescription = null,
                                        tint = if (isCorrect) Color(0xFF27AE60) else Color(0xFFE67E22)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = if (isCorrect) "CRITERIO AJUSTADO A DERECHO (+100 XP)"
                                        else "CRITERIO IMPROCEDENTE (FALLO ${fallos + 1}/3)",
                                        color = if (isCorrect) Color(0xFF27AE60) else Color(0xFFE67E22),
                                        fontWeight = FontWeight.Black,
                                        fontSize = 13.sp
                                    )
                                }
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = if (isCorrect) question.fundamentacion else question.pista,
                                    color = Color.White.copy(alpha = 0.9f),
                                    fontSize = 12.sp,
                                    lineHeight = 18.sp
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        Button(
                            onClick = {
                                if (isCorrect) {
                                    onBack()
                                } else {
                                    isEvaluated = false
                                    selectedOption = null
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(46.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (isCorrect) Color(0xFF003893) else Color(0xFF1E293B)
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = if (isCorrect) "REGRESAR AL LOBBY" else "REINTENTAR CRITERIO",
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}

object Colors {
    val White = Color(0xFFFFFFFF)
}
