package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.data.getQuestionForLevel
import com.example.service.SoundAndTtsService
import com.example.state.GameViewModel

@Composable
fun QuizModalDialog(
    level: Int,
    viewModel: GameViewModel,
    soundService: SoundAndTtsService,
    onDismiss: () -> Unit
) {
    val question = remember(level) { getQuestionForLevel(level) }
    var selectedOption by remember { mutableStateOf<Int?>(null) }
    var showFundamentacionModal by remember { mutableStateOf(false) }
    var showPistaModal by remember { mutableStateOf(false) }

    val isLocked = viewModel.isLevelLocked(level)
    val fallos = viewModel.getFailures(level)

    DisposableEffect(Unit) {
        onDispose {
            soundService.stopSpeaking()
        }
    }

    Dialog(
        onDismissRequest = {
            soundService.stopSpeaking()
            onDismiss()
        },
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .shadow(24.dp, RoundedCornerShape(16.dp))
                .background(Color(0xFF0B1020), RoundedCornerShape(16.dp))
                .border(2.dp, Color(0xFFD4AF37), RoundedCornerShape(16.dp))
                .padding(18.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                // Cabecera del Caso
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "CASO JUDICIAL - NIVEL $level",
                            color = Color(0xFFFCDD09),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Black
                        )
                        Text(
                            text = question.dificultad,
                            color = Color(0xFFD4AF37),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                    IconButton(
                        onClick = {
                            soundService.stopSpeaking()
                            onDismiss()
                        },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Cerrar",
                            tint = Color.White.copy(alpha = 0.7f)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Cuadro Blanco Formal del Caso
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(4.dp, RoundedCornerShape(8.dp))
                        .background(Color.White, RoundedCornerShape(8.dp))
                        .padding(14.dp)
                ) {
                    Column {
                        Text(
                            text = question.delitoBase.uppercase(),
                            color = Color(0xFF003893),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 1.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = question.contextoNarrativo,
                            color = Color(0xFF1E293B),
                            fontSize = 13.sp,
                            lineHeight = 18.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Estado Bloqueado por 3 fallos
                if (isLocked) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFCF142B).copy(alpha = 0.15f), RoundedCornerShape(10.dp))
                            .border(1.5.dp, Color(0xFFCF142B), RoundedCornerShape(10.dp))
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Default.Lock,
                                contentDescription = null,
                                tint = Color(0xFFCF142B),
                                modifier = Modifier.size(36.dp)
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "EXPEDIENTE BLOQUEADO (3 FALLOS)",
                                color = Color(0xFFCF142B),
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp
                            )
                            Spacer(modifier = Modifier.height(10.dp))
                            Button(
                                onClick = {
                                    if (viewModel.usarApelacion(level)) {
                                        soundService.playGavel()
                                        selectedOption = null
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = Color(0xFFD4AF37),
                                    contentColor = Color(0xFF003893)
                                ),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Icon(Icons.Default.Gavel, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "USAR APELACIÓN (${viewModel.uiState.value.apelaciones})",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                } else {
                    // Opciones de Respuesta
                    val letters = listOf("A", "B", "C", "D")
                    question.opciones.forEachIndexed { idx, opcion ->
                        val isSelected = selectedOption == idx
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 8.dp)
                                .background(
                                    if (isSelected) Color(0xFF1B2440) else Color(0xFF131A2E),
                                    RoundedCornerShape(8.dp)
                                )
                                .border(
                                    width = if (isSelected) 2.dp else 1.dp,
                                    color = if (isSelected) Color(0xFFD4AF37) else Color.White.copy(alpha = 0.15f),
                                    shape = RoundedCornerShape(8.dp)
                                )
                                .clickable { selectedOption = idx }
                                .padding(12.dp)
                        ) {
                            Row(verticalAlignment = Alignment.Top) {
                                Text(
                                    text = "${letters[idx]}) ",
                                    color = Color(0xFFFCDD09),
                                    fontWeight = FontWeight.Black,
                                    fontSize = 13.sp
                                )
                                Text(
                                    text = opcion,
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    lineHeight = 16.sp
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    if (selectedOption != null) {
                        Button(
                            onClick = {
                                val isCorrect = selectedOption == question.respuestaCorrecta
                                val rankUp = viewModel.responderPregunta(level, isCorrect)

                                if (isCorrect) {
                                    if (rankUp) {
                                        soundService.playFanfare()
                                    } else {
                                        soundService.playSuccess()
                                    }
                                    soundService.speak(question.fundamentacion)
                                    showFundamentacionModal = true
                                } else {
                                    soundService.playError()
                                    showPistaModal = true
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(46.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFFD4AF37),
                                contentColor = Color(0xFF003893)
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = "DICTAR SENTENCIA JURÍDICA",
                                fontWeight = FontWeight.Black,
                                fontSize = 13.sp,
                                letterSpacing = 1.sp
                            )
                        }
                    }
                }
            }
        }
    }

    // Modal Flotante de Fundamentación Legal con Voz en Off
    if (showFundamentacionModal) {
        Dialog(
            onDismissRequest = {
                soundService.stopSpeaking()
                showFundamentacionModal = false
                onDismiss()
            }
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(16.dp, RoundedCornerShape(14.dp))
                    .background(Color(0xFF0B1020), RoundedCornerShape(14.dp))
                    .border(2.dp, Color(0xFF27AE60), RoundedCornerShape(14.dp))
                    .padding(18.dp)
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = Color(0xFF27AE60),
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "FUNDAMENTACIÓN LEGAL (+100 XP)",
                            color = Color(0xFF27AE60),
                            fontWeight = FontWeight.Black,
                            fontSize = 13.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = question.fundamentacion,
                        color = Color.White.copy(alpha = 0.95f),
                        fontSize = 12.sp,
                        lineHeight = 18.sp
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    // Botón de lectura de voz en off (TTS)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                soundService.speak(question.fundamentacion)
                            }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.VolumeUp,
                            contentDescription = null,
                            tint = Color(0xFFD4AF37),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Reproducir lectura en voz alta",
                            color = Color(0xFFD4AF37),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = {
                            soundService.stopSpeaking()
                            showFundamentacionModal = false
                            onDismiss()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(42.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF003893)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "CONTINUAR",
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
            }
        }
    }

    // Modal Flotante de Pistas
    if (showPistaModal) {
        Dialog(
            onDismissRequest = {
                showPistaModal = false
            }
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(16.dp, RoundedCornerShape(14.dp))
                    .background(Color(0xFF0B1020), RoundedCornerShape(14.dp))
                    .border(2.dp, Color(0xFFE67E22), RoundedCornerShape(14.dp))
                    .padding(18.dp)
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = Color(0xFFE67E22),
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "CRITERIO IMPROCEDENTE (${fallos + 1}/3)",
                            color = Color(0xFFE67E22),
                            fontWeight = FontWeight.Black,
                            fontSize = 13.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = question.pista,
                        color = Color.White.copy(alpha = 0.9f),
                        fontSize = 12.sp,
                        lineHeight = 18.sp
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = {
                            showPistaModal = false
                            selectedOption = null
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(42.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E293B)),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "REINTENTAR CRITERIO",
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFFFCDD09)
                        )
                    }
                }
            }
        }
    }
}
