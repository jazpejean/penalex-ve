package com.example.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class MedallionState {
    COMPLETADO,
    BLOQUEADO,
    ACTUAL
}

@Composable
fun LevelMedallion(
    level: Int,
    state: MedallionState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isMilestone = level % 10 == 0 || level == 1
    val isSuperMilestone = level % 50 == 0

    val medallionSize = when {
        isSuperMilestone -> 76.dp
        isMilestone -> 68.dp
        else -> 60.dp
    }

    Box(
        modifier = modifier
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                enabled = state != MedallionState.BLOQUEADO,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        // Halo pulsante en el caso actual (sólo se anima si está activo)
        if (state == MedallionState.ACTUAL) {
            val infiniteTransition = rememberInfiniteTransition(label = "pulse_halo")
            val pulse by infiniteTransition.animateFloat(
                initialValue = 0.90f,
                targetValue = 1.15f,
                animationSpec = infiniteRepeatable(
                    animation = tween(900, easing = FastOutSlowInEasing),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "glow_scale"
            )

            Box(
                modifier = Modifier
                    .size(medallionSize * pulse + 16.dp)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                Color(0xFFFFD700).copy(alpha = 0.55f),
                                Color(0xFFF59E0B).copy(alpha = 0.25f),
                                Color.Transparent
                            )
                        ),
                        CircleShape
                    )
            )
        }

        // Medallón principal
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Etiqueta flotante de "CASO ACTUAL"
            if (state == MedallionState.ACTUAL) {
                Box(
                    modifier = Modifier
                        .offset(y = (-4).dp)
                        .shadow(6.dp, RoundedCornerShape(8.dp))
                        .clip(RoundedCornerShape(8.dp))
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24))
                            )
                        )
                        .border(1.dp, Color.White, RoundedCornerShape(8.dp))
                        .padding(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "TU CASO",
                        color = Color(0xFF0F172A),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 0.5.sp
                    )
                }
            }

            // Cuerpo circular del medallón
            Box(
                modifier = Modifier
                    .size(medallionSize)
                    .shadow(
                        elevation = if (state == MedallionState.ACTUAL) 12.dp else 6.dp,
                        shape = CircleShape
                    )
                    .clip(CircleShape)
                    .background(
                        when (state) {
                            MedallionState.COMPLETADO -> Brush.verticalGradient(
                                colors = listOf(
                                    Color(0xFFFFEE88),
                                    Color(0xFFD4AF37),
                                    Color(0xFF996515)
                                )
                            )
                            MedallionState.ACTUAL -> Brush.verticalGradient(
                                colors = listOf(
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF8FAFC),
                                    Color(0xFFE2E8F0)
                                )
                            )
                            MedallionState.BLOQUEADO -> Brush.verticalGradient(
                                colors = listOf(
                                    Color(0xFF334155),
                                    Color(0xFF1E293B),
                                    Color(0xFF0F172A)
                                )
                            )
                        }
                    )
                    .border(
                        width = if (isMilestone) 3.5.dp else 2.5.dp,
                        color = when (state) {
                            MedallionState.COMPLETADO -> Color(0xFFFFE066)
                            MedallionState.ACTUAL -> Color(0xFFFFD700)
                            MedallionState.BLOQUEADO -> Color(0xFF475569)
                        },
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                // Contenido interno según el estado
                when (state) {
                    MedallionState.COMPLETADO -> {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            if (isMilestone) {
                                Icon(
                                    imageVector = Icons.Default.AccountBalance,
                                    contentDescription = null,
                                    tint = Color(0xFF0F172A),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                            Text(
                                text = "$level",
                                color = Color(0xFF0F172A),
                                fontSize = if (isMilestone) 16.sp else 18.sp,
                                fontWeight = FontWeight.Black
                            )
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "Completado",
                                tint = Color(0xFF065F46),
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }
                    MedallionState.ACTUAL -> {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            if (isMilestone) {
                                Icon(
                                    imageVector = Icons.Default.AccountBalance,
                                    contentDescription = null,
                                    tint = Color(0xFF003893),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                            Text(
                                text = "$level",
                                color = Color(0xFF003893),
                                fontSize = if (isMilestone) 17.sp else 20.sp,
                                fontWeight = FontWeight.Black
                            )
                        }
                    }
                    MedallionState.BLOQUEADO -> {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Lock,
                                contentDescription = "Bloqueado",
                                tint = Color(0xFF94A3B8),
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.height(1.dp))
                            Text(
                                text = "$level",
                                color = Color(0xFF64748B),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            // Estrellas doradas para niveles completados
            if (state == MedallionState.COMPLETADO) {
                Row(
                    modifier = Modifier.offset(y = (-4).dp)
                ) {
                    repeat(3) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = Color(0xFFFFD700),
                            modifier = Modifier.size(11.dp)
                        )
                    }
                }
            }
        }
    }
}
